CREATE DATABASE ASSIGNMENT_2;

Go
	Use ASSIGNMENT_2;
Go

CREATE TABLE Employee 
(	E_Code		CHAR(4)		PRIMARY KEY,
	E_FName		VARCHAR(20)	NOT NULL,
	E_LName		VARCHAR(20)	NOT NULL,
	E_Gender	CHAR(1),
	E_Address	VARCHAR(50),
	E_Type		VARCHAR(20)	NOT NULL,
	CONSTRAINT	domain_gender CHECK (E_Gender IN ('F', 'M')),
	CONSTRAINT	domain_type CHECK (E_Type IN ('Manager', 'Operational staff', 'Office staff', 'Partner staff'))
);
go

CREATE TABLE Employee_Phone
(	Employee_Code		CHAR(4),
	Phone_number		VARCHAR(15)		UNIQUE,
	PRIMARY KEY(Employee_Code,Phone_number),
	CONSTRAINT 	fk_emp_pnumber	FOREIGN KEY (Employee_Code) 
				REFERENCES Employee(E_Code) 
				ON DELETE CASCADE
				ON UPDATE CASCADE,
	CONSTRAINT domain_phone CHECK (Phone_number NOT LIKE '%[^0-9]%')
);
go

CREATE TABLE Supplier
(	S_Code		CHAR(6)		PRIMARY KEY,
	S_Name		VARCHAR(20)	NOT NULL,
	S_Address	VARCHAR(50),
	S_Taxcode	VARCHAR(15),
	S_BankAccount	VARCHAR(20),
	S_Pstaff_code	CHAR(4)	NOT NULL,
	CONSTRAINT 	fk_sup_partner_code	FOREIGN KEY (S_Pstaff_code) 
				REFERENCES Employee(E_Code) 
				ON DELETE NO ACTION
				ON UPDATE CASCADE
);
go

CREATE TABLE Fabric_Category
(	F_Code		CHAR(5)		PRIMARY KEY,
	F_Name		VARCHAR(20)	NOT NULL,
	F_Quantity	INT			DEFAULT 0,
	F_Color		VARCHAR(7),
	CONSTRAINT domain_quantity CHECK (F_Quantity >= 0),
	CONSTRAINT domain_hex_color CHECK (UPPER(F_Color) LIKE '#[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]' 
										OR UPPER(F_Color) LIKE '#[0-9A-F][0-9A-F][0-9A-F]')
);
go

CREATE TABLE Customer
(	C_Code		CHAR(8)		PRIMARY KEY,
	C_FName		VARCHAR(20)	NOT NULL,
	C_LName		VARCHAR(20)	NOT NULL,
	C_Address	VARCHAR(50),
	C_Arrearage DECIMAL(10, 2)	DEFAULT 0,
	C_Last_Warning_Date     Date,
	C_Warning	CHAR(1)		DEFAULT '0',
	C_Office_staff_code	CHAR(4)	NOT NULL,
	CONSTRAINT 	fk_cus_office_code	FOREIGN KEY (C_Office_staff_code) 
				REFERENCES Employee(E_Code) 
				ON DELETE NO ACTION
				ON UPDATE CASCADE,
	CONSTRAINT domain_bool CHECK (C_Warning = '0' OR C_Warning = '1'),
	CONSTRAINT domain_arrearage CHECK (C_Arrearage >= 0)
);
go

CREATE TABLE Order_Customer
(	O_Code		CHAR(10)		PRIMARY KEY,
	O_Customer_Code	CHAR(8)		NOT NULL,
	O_Total_Price	DECIMAL(10, 2)	DEFAULT 0,
	O_Ostaff_code	CHAR(4)		NOT NULL,
	CONSTRAINT 	fk_order_customer_code	FOREIGN KEY (O_Customer_Code) 
				REFERENCES Customer(C_Code) 
				ON DELETE NO ACTION,
	CONSTRAINT 	fk_order_op_staff_code	FOREIGN KEY (O_Ostaff_code) 
				REFERENCES Employee(E_Code) 
				ON DELETE NO ACTION
				ON UPDATE CASCADE,
	CONSTRAINT	domain_total CHECK (O_Total_Price >= 0)
);
go

CREATE TABLE Import_Information
(	I_Category_Code		CHAR(5),
	I_Supplier_Code		CHAR(6),
	I_Date				Date,
	I_Quantity			INT		NOT NULL,
	I_Price				DECIMAL(10, 2)	NOT NULL,
	PRIMARY KEY (I_Supplier_Code, I_Category_Code, I_Date),
	CONSTRAINT 	fk_import_fabric_code	FOREIGN KEY (I_Category_Code) 
				REFERENCES Fabric_Category(F_Code) 
				ON DELETE NO ACTION,
	CONSTRAINT 	fk_import_sup_code	FOREIGN KEY (I_Supplier_Code) 
				REFERENCES Supplier(S_Code) 
				ON DELETE NO ACTION
				ON UPDATE CASCADE,
	CONSTRAINT	domain_quantity_price CHECK (I_Quantity > 0 AND I_Price > 0)
);
go

CREATE TABLE Bolt
(	B_Code				CHAR(7),
	B_Category_Code		CHAR(5),
	B_Length			DECIMAL(5, 2),
	PRIMARY KEY (B_Code, B_Category_Code),
	CONSTRAINT 	fk_bolt_category_code	FOREIGN KEY (B_Category_Code) 
				REFERENCES Fabric_Category(F_Code) 
				ON DELETE NO ACTION
				ON UPDATE CASCADE,
	CONSTRAINT	domain_length CHECK (B_Length > 0)
);
go

CREATE TABLE Order_Status
(	OS_Code		CHAR(10),
	OS_Date		DATE,
	OS_Time		TIME,
	OS_Status	VARCHAR(20)		NOT NULL DEFAULT 'New',
	OS_Cancel_Reason VARCHAR(255),
	OS_Ostaff_code	 CHAR(4),
	PRIMARY KEY (OS_Code, OS_Date, OS_Time),
	CONSTRAINT 	fk_order_status_code	FOREIGN KEY (OS_Code) 
				REFERENCES Order_Customer(O_Code) 
				ON DELETE CASCADE,
	CONSTRAINT 	fk_ostatus_op_staff_code	FOREIGN KEY (OS_Ostaff_code) 
				REFERENCES Employee(E_Code) 
				ON DELETE NO ACTION
				ON UPDATE CASCADE,
	CONSTRAINT	domain_status CHECK (OS_Status IN ('New', 'Ordered', 'Partial paid', 'Full paid', 'Cancelled'))
);
go


CREATE TABLE Order_Bolt
(	OB_Bolt_Code		CHAR(7),
	OB_Category_Code	CHAR(5),
	OB_Order_Code		CHAR(10),
	PRIMARY KEY (OB_Bolt_Code, OB_Category_Code, OB_Order_Code),
	CONSTRAINT 	fk_OB_bolt_code	 FOREIGN KEY (OB_Bolt_Code, OB_Category_Code) 
				REFERENCES Bolt(B_Code, B_Category_Code) 
				ON DELETE CASCADE,
	CONSTRAINT 	fk_OB_order_code FOREIGN KEY (OB_Order_Code) 
				REFERENCES Order_Customer(O_Code) 
				ON DELETE CASCADE
				ON UPDATE CASCADE
);
go


CREATE TABLE Supplier_Phone
(	Supplier_Code		CHAR(6),
	Phone_number		VARCHAR(15)		UNIQUE,
	PRIMARY KEY(Supplier_Code,Phone_number),
	CONSTRAINT 	fk_sup_pnumber	FOREIGN KEY (Supplier_Code) 
				REFERENCES Supplier(S_Code) 
				ON DELETE CASCADE
				ON UPDATE CASCADE,
	CONSTRAINT domain_supplier_phone CHECK (Phone_number NOT LIKE '%[^0-9]%')
);
go

CREATE TABLE Customer_Phone
(	Customer_Code		CHAR(8),
	Phone_number		VARCHAR(15)		UNIQUE,
	PRIMARY KEY(Customer_Code,Phone_number),
	CONSTRAINT 	fk_cus_pnumber	FOREIGN KEY (Customer_Code) 
				REFERENCES Customer(C_Code) 
				ON DELETE CASCADE
				ON UPDATE CASCADE,
	CONSTRAINT domain_customer_phone CHECK (Phone_number NOT LIKE '%[^0-9]%')
);
go

CREATE TABLE Fabric_Category_Price
(	FCP_Category_Code	CHAR(5),
	FCP_Date			Date,
	FCP_Price			DECIMAL(10, 2),
	PRIMARY KEY(FCP_Category_Code,FCP_Date,FCP_Price),
	CONSTRAINT 	fk_FCP_fabric_code	FOREIGN KEY (FCP_Category_Code) 
				REFERENCES Fabric_Category(F_Code) 
				ON DELETE CASCADE
				ON UPDATE CASCADE,
	CONSTRAINT	domain_category_price CHECK (FCP_Price > 0)
);
go

CREATE TABLE Order_Payment
(	OP_Order_Code		CHAR(10),
	OP_Amount			DECIMAL(10, 2)	NOT NULL,
	OP_Date				Date,
	OP_Time				Time,
	OP_Customer_Code	CHAR(8),
	PRIMARY KEY(OP_Customer_Code, OP_Order_Code, OP_Date, OP_Time),
	CONSTRAINT 	fk_order_payment	FOREIGN KEY (OP_Order_Code) 
				REFERENCES Order_Customer(O_Code) 
				ON DELETE NO ACTION,
	CONSTRAINT 	fk_order_payment_customer_code	FOREIGN KEY (OP_Customer_Code) 
				REFERENCES Customer(C_Code) 
				ON DELETE NO ACTION
				ON UPDATE CASCADE,
	CONSTRAINT	domain_amount CHECK (OP_Amount > 0)
);
go


	