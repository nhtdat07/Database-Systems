Use ASSIGNMENT_2;
Go

-------------------------------		TRIGGER     ---------------------------------------------------

-- Check partner staff of supplier
CREATE TRIGGER check_partner_staff ON Supplier
AFTER INSERT, UPDATE
AS
BEGIN
	IF NOT EXISTS
		(SELECT *
		FROM inserted,  Employee
		WHERE S_Pstaff_code = E_Code AND E_Type = 'Partner staff')
	BEGIN
		RAISERROR('You must input the code of a partner staff', 16, 1);
		ROLLBACK TRANSACTION;
	END
END;
go

-- Check office staff of customer
CREATE TRIGGER check_office_staff ON Customer
AFTER INSERT, UPDATE
AS
BEGIN
	IF NOT EXISTS
		(SELECT *
		FROM inserted,  Employee
		WHERE C_Office_staff_code = E_Code AND E_Type = 'Office staff')
	BEGIN
		RAISERROR('You must input the code of an office staff', 16, 1);
		ROLLBACK TRANSACTION;
	END
END;
go

-- Check operational staff of order
CREATE TRIGGER check_operational_staff1 ON Order_Customer
AFTER INSERT, UPDATE
AS
BEGIN
	IF NOT EXISTS
		(SELECT *
		FROM inserted,  Employee
		WHERE O_Ostaff_code = E_Code AND E_Type = 'Operational staff')
	BEGIN
		RAISERROR('You must input the code of an operational staff', 16, 1);
		ROLLBACK TRANSACTION;
	END
END;
go

-- Check unique supplier of category
CREATE TRIGGER check_unique_supplier ON Import_Information
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @count INT;
	SELECT @count = COUNT(*)
	FROM 
		(SELECT DISTINCT Info.I_Supplier_Code
		FROM Import_Information AS Info, inserted
		WHERE inserted.I_Category_Code = Info.I_Category_Code)
	AS Supplier_code;
	IF @count > 1
	BEGIN
		RAISERROR('One category can only be supplied by one supplier', 16, 1);
		ROLLBACK TRANSACTION;
	END;
END;
go

-- Update category quantity when imported
CREATE TRIGGER update_category_quantity ON Import_Information
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @new_amount INT, @old_amount INT;

	SELECT @new_amount = I_Quantity FROM inserted;
	IF EXISTS (SELECT * FROM deleted)
	BEGIN
		SELECT @old_amount = I_Quantity FROM deleted;
	END
	ELSE
	BEGIN
		SET @old_amount = 0;
	END;

	UPDATE Fabric_Category
	SET F_Quantity = F_Quantity + @new_amount - @old_amount
	FROM inserted JOIN Fabric_Category ON I_Category_Code = F_Code;
END;
go

-- Get the price of a category on a date
CREATE FUNCTION get_price 
	(@Category_code CHAR(5), @date DATE)
RETURNS DECIMAL(10, 2)
AS
BEGIN
	DECLARE @price DECIMAL(10, 2);
	SELECT TOP 1 @price = FCP_Price
	FROM Fabric_Category_Price
	WHERE FCP_Category_Code = @Category_code AND FCP_Date <= @date
	ORDER BY FCP_Date DESC;
	RETURN @price;
END;
go

-- Check for valid bolt
CREATE TRIGGER check_bolt ON Order_Bolt
AFTER INSERT, UPDATE
AS
BEGIN
	IF EXISTS
		(SELECT * 
		FROM 
			(SELECT OB.OB_Order_Code
			FROM Order_Bolt AS OB, inserted AS I, Order_Status
			WHERE I.OB_Bolt_Code = OB.OB_Bolt_Code AND I.OB_Category_Code = OB.OB_Category_Code
				AND OB.OB_Order_Code = OS_Code AND OS_Status = 'Ordered') AS Has_Ordered
		WHERE OB_Order_Code NOT IN
			(SELECT OS_Code
			FROM Order_Status
			WHERE OS_Status = 'Cancelled'))
	BEGIN
		RAISERROR('This bolt has been ordered in another order', 16, 1);
		ROLLBACK TRANSACTION;
	END;
END; 
go

-- Update total price of order
CREATE TRIGGER update_total_price ON Order_Bolt
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @new_price DECIMAL(10, 2), @old_price DECIMAL(10, 2), @category CHAR(5), @date DATE;

	SELECT @date = OS_Date, @category = OB_Category_Code
	FROM inserted, Order_Status
	WHERE OB_Order_Code = OS_Code AND OS_Status = 'New';
	SET @new_price = dbo.get_price(@category, @date);

	IF EXISTS (SELECT * FROM deleted)
	BEGIN
		SELECT @date = OS_Date, @category = OB_Category_Code
		FROM deleted, Order_Status
		WHERE OB_Order_Code = OS_Code AND OS_Status = 'New';
		SET @old_price = dbo.get_price(@category, @date);
	END
	ELSE 
	BEGIN
		SET @old_price = 0;
	END;

	UPDATE Order_Customer
	SET O_Total_Price = O_Total_Price + @new_price - @old_price
	FROM Order_Customer JOIN inserted ON O_Code = OB_Order_Code;
END;
go

-- Get the paid amount of an order
CREATE FUNCTION get_paid_amount(@order_code CHAR(10))
RETURNS DECIMAL(10, 2)
AS
BEGIN
	DECLARE @result DECIMAL(10, 2);
	SELECT @result = SUM(OP_Amount)
	FROM Order_Payment
	WHERE OP_Order_Code = @order_code;
	IF @result IS NULL 
	BEGIN
		RETURN 0;
	END
	RETURN @result;
END;
go

-- Check operational staff of order status
CREATE TRIGGER check_operational_staff2 ON Order_Status
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @employee CHAR(4);
	SELECT @employee = OS_Ostaff_code FROM inserted;
	IF @employee IS NOT NULL AND NOT EXISTS
		(SELECT *
		FROM Employee
		WHERE E_Code = @employee AND E_Type = 'Operational staff')
	BEGIN
		RAISERROR('You must input the code of an operational staff', 16, 1);
		ROLLBACK TRANSACTION;
	END
END;
go

-- Update category quantity, arrearage and warning mode when an order has the status 'Ordered' or 'Cancelled'
CREATE TRIGGER update_when_change_status ON Order_Status
AFTER INSERT
AS
BEGIN
	DECLARE @status VARCHAR(20), @total DECIMAL(10, 2), @order CHAR(10), @new_arrearage DECIMAL(10, 2), @warning CHAR(1);
	SELECT @status = OS_Status, @order = OS_Code FROM inserted;
	SELECT @total = O_Total_Price, @new_arrearage = C_Arrearage, @warning = C_Warning 
	FROM Order_Customer, Customer
	WHERE O_Code = @order AND O_Customer_Code = C_Code; 

	IF @status = 'Ordered' 
	BEGIN
		UPDATE Fabric_Category
		SET F_Quantity = F_Quantity - Amount
		FROM Fabric_Category, 
			(SELECT OB_Category_Code AS Category_Code, COUNT(*) AS Amount
			FROM Order_Bolt
			WHERE OB_Order_Code = @order
			GROUP BY OB_Category_Code)
			AS Category_Amount
		WHERE F_Code = Category_Code;

		SET @new_arrearage = @new_arrearage + @total;
		IF @new_arrearage > 2000 AND @warning = '0'
		BEGIN
			DECLARE @warning_date DATE;
			SELECT @warning_date = OS_Date FROM inserted;
			UPDATE Customer
			SET C_Arrearage = @new_arrearage, C_Warning = '1', C_Last_Warning_Date = @warning_date
			WHERE C_Code = (SELECT O_Customer_Code FROM Order_Customer WHERE O_Code = @order);
		END
		ELSE
		BEGIN
			UPDATE Customer
			SET C_Arrearage = @new_arrearage
			WHERE C_Code = (SELECT O_Customer_Code FROM Order_Customer WHERE O_Code = @order);
		END;
	END;

	IF @status = 'Cancelled' AND EXISTS
		(SELECT * FROM Order_Status WHERE OS_Status = 'Ordered' AND OS_Code = @order)
	BEGIN
		UPDATE Fabric_Category
		SET F_Quantity = F_Quantity + Amount
		FROM Fabric_Category, 
			(SELECT OB_Category_Code AS Category_Code, COUNT(*) AS Amount
			FROM Order_Bolt
			WHERE OB_Order_Code = @order
			GROUP BY OB_Category_Code)
			AS Category_Amount
		WHERE F_Code = Category_Code;

		SET @new_arrearage = @new_arrearage - @total + dbo.get_paid_amount(@order);
		IF @new_arrearage <= 2000 AND @warning = '1'
		BEGIN
			UPDATE Customer
			SET C_Arrearage = @new_arrearage, C_Warning = '0'
			WHERE C_Code = (SELECT O_Customer_Code FROM Order_Customer WHERE O_Code = @order);
		END
		ELSE
		BEGIN
			UPDATE Customer
			SET C_Arrearage = @new_arrearage
			WHERE C_Code = (SELECT O_Customer_Code FROM Order_Customer WHERE O_Code = @order);
		END;
	END;
END;
go

-- Check the correct customer for payment
CREATE TRIGGER check_correct_customer ON Order_Payment
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @customer CHAR(8);
	DECLARE @check_cus CHAR(8);

	SELECT @customer = O_Customer_Code, @check_cus = OP_Customer_Code
	FROM inserted JOIN Order_Customer ON OP_Order_Code = O_Code;

	IF @check_cus <> @customer
	BEGIN
		RAISERROR('The customer who paid for the order must be the one who made the order', 16, 1);
		ROLLBACK TRANSACTION;
	END
END;
go

-- Check valid payment and update arrearage, warning mode, order status for each payment
CREATE TRIGGER check_payment ON Order_Payment
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @paid DECIMAL(10, 2), @total DECIMAL(10, 2);
	DECLARE @order CHAR(10);

	SELECT @total = O_Total_Price, @order = OP_Order_Code
	FROM Order_Customer JOIN inserted ON O_Code = OP_Order_Code;
	SET @paid = dbo.get_paid_amount(@order);

	IF @paid > @total
	BEGIN
		RAISERROR('This payment exceeds the debt for the order', 16, 1);
		ROLLBACK TRANSACTION;
	END
	ELSE
	BEGIN
		DECLARE @new_arrearage DECIMAL(10, 2), @amount DECIMAL(10, 2), @pay_day DATE, @pay_time TIME, @warning CHAR(1);
		SELECT @new_arrearage = C_Arrearage, @amount = OP_Amount, @pay_day = OP_Date, @pay_time = OP_Time, @warning = C_Warning
		FROM Customer JOIN inserted ON C_Code = OP_Customer_Code;

		SET @new_arrearage = @new_arrearage - @amount;
		IF @new_arrearage <= 2000 AND @warning = '1'
		BEGIN
			UPDATE Customer
			SET C_Arrearage = @new_arrearage, C_Warning = '0'
			WHERE C_Code = (SELECT OP_Customer_Code FROM inserted);
		END
		ELSE
		BEGIN
			UPDATE Customer
			SET C_Arrearage = @new_arrearage
			WHERE C_Code = (SELECT OP_Customer_Code FROM inserted);
		END;

		IF @paid = @total 
		BEGIN
			INSERT INTO Order_Status (OS_Code, OS_Date, OS_Time, OS_Status) 
			VALUES (@order, @pay_day, @pay_time, 'Full paid');
		END
		ELSE
		BEGIN
			IF NOT EXISTS
				(SELECT * FROM Order_Status WHERE OS_Code = @order AND OS_Status = 'Partial paid')
			BEGIN
				INSERT INTO Order_Status (OS_Code, OS_Date, OS_Time, OS_Status) 
				VALUES (@order, @pay_day, @pay_time, 'Partial paid');
			END;
		END;
	END;
END;
go