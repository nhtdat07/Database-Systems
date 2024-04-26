
Use ASSIGNMENT_2;
Go

------ 2.2 a ---------
	INSERT INTO Fabric_Category_Price (FCP_Category_Code, FCP_Date, FCP_Price)
	SELECT FCP_Category_Code, CAST(GETDATE() AS DATE) AS new_date, FCP_Price * 1.1 AS new_price
	FROM Fabric_Category_Price,
		(SELECT FCP_Category_Code AS Code, MAX(FCP_Date) AS FCP_Latest_Date
		FROM Fabric_Category_Price
		GROUP BY FCP_Category_Code
		HAVING FCP_Category_Code IN
			(SELECT DISTINCT I_Category_Code
			FROM Import_Information
			WHERE I_Date >= '2020-09-01')) AS Latest_Date 
	WHERE FCP_Category_Code = Code AND FCP_Date = FCP_Latest_Date;

	------ 2.2 b ---------
	SELECT * 
	FROM Order_Customer 
	WHERE O_Code IN 
		(SELECT DISTINCT OB_Order_Code 
		FROM Order_Bolt 
		WHERE OB_Category_Code IN
			(SELECT DISTINCT I_Category_Code 
			FROM Supplier JOIN Import_Information ON S_Code = I_Supplier_Code 
			WHERE S_Name = 'Silk Agency'));

	------ 2.2 c ---------
	CREATE FUNCTION CalculateSupplierPayment(@SupplierID CHAR(6))
	RETURNS TABLE
	AS
	RETURN
	(
		SELECT I_Supplier_Code AS SupplierID, SUM(I_Quantity * I_Price) AS TotalPayment
		FROM Import_Information
		WHERE I_Supplier_Code = @SupplierID
		GROUP BY I_Supplier_Code
	);
	
	------ 2.2 d ---------
	CREATE PROCEDURE SortSuppliersByCategories(
		@StartDate	DATE,
		@EndDate	DATE
	)
	AS
	BEGIN
		SELECT I_Supplier_Code AS SupplierID, COUNT(DISTINCT I_Category_Code) AS CategoryCount
		FROM Import_Information
		WHERE I_Date BETWEEN @StartDate AND @EndDate
		GROUP BY I_Supplier_Code
		ORDER BY COUNT(DISTINCT I_Category_Code) ASC;
	END;