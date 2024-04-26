USE ASSIGNMENT_7;
------------------------------------------------------------------------------------------------
-- 4a - Generate 10 million bolts for each category --
CREATE PROCEDURE add_bolt
	(@category CHAR(5), @start CHAR(7), @end INT)
AS
BEGIN
	DECLARE @count INT;
	SET @count = CONVERT(INT, @start);
	WHILE @count < @end
	BEGIN
		INSERT INTO Bolt(B_Category_Code, B_Code, B_Length)
		VALUES (@category, REPLICATE('0', 7 - LEN(@count)) + CAST(@count AS VARCHAR(7)), 
							100 + ABS(CAST(CHECKSUM(NEWID()) % 10001 AS FLOAT)) / 100);
		SET @count = @count + 1;
	END;
END; 
go

EXECUTE add_bolt '11111', '0000000', 4000001;
EXECUTE add_bolt '11111', '4000021', 10000000;
go
EXECUTE add_bolt '11112', '0000000', 4000001;
EXECUTE add_bolt '11112', '4000025', 10000000;
go
EXECUTE add_bolt '11113', '0000000', 4000001;
EXECUTE add_bolt '11113', '4000025', 10000000;
go
EXECUTE add_bolt '11114', '0000000', 4000001;
EXECUTE add_bolt '11114', '4000021', 10000000;
go
EXECUTE add_bolt '11115', '0000000', 4000001;
EXECUTE add_bolt '11115', '4000026', 10000000;
go
EXECUTE add_bolt '11116', '0000000', 4000001;
EXECUTE add_bolt '11116', '4000029', 10000000;
go
EXECUTE add_bolt '11117', '0000000', 4000001;
EXECUTE add_bolt '11117', '4000030', 10000000;
go
EXECUTE add_bolt '11118', '0000000', 4000001;
EXECUTE add_bolt '11118', '4000027', 10000000;
go
EXECUTE add_bolt '11119', '0000000', 4000001;
EXECUTE add_bolt '11119', '4000022', 10000000;
go
EXECUTE add_bolt '11120', '0000000', 4000001;
EXECUTE add_bolt '11120', '4000016', 10000000;
go
EXECUTE add_bolt '11121', '0000000', 4000001;
EXECUTE add_bolt '11121', '4000029', 10000000;
go
EXECUTE add_bolt '11122', '0000000', 4000001;
EXECUTE add_bolt '11122', '4000026', 10000000;
go
select count(*) from bolt;
-- With Cluster index --
SELECT * FROM Bolt WHERE B_Code = '2345678'; 
-- With table scan --
SELECT * from Bolt WITH (INDEX(0)) WHERE B_Code = '2345678'; 