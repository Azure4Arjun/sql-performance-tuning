USE AdventureWorks;
GO

SELECT * 
FROM sys.stats
WHERE object_id = object_id('Sales.SalesOrderDetail');
GO

DBCC SHOW_STATISTICS ('Sales.SalesOrderDetail', UnitPrice);
GO

SELECT * 
FROM Sales.SalesOrderDetail
WHERE UnitPrice = 35;
GO

DBCC SHOW_STATISTICS ('Sales.SalesOrderDetail', UnitPrice);
GO

--Density
DBCC SHOW_STATISTICS ('Sales.SalesOrderDetail', IX_SalesOrderDetail_ProductID);
GO

DECLARE @ProductID int;
SET @ProductID = 921;
SELECT ProductID 
FROM Sales.SalesOrderDetail
WHERE ProductID = @ProductID;
GO

DECLARE @ProductID int;
SET @ProductID = 897;
SELECT ProductID 
FROM Sales.SalesOrderDetail
WHERE ProductID = @ProductID;
GO

--Cardinality
DBCC SHOW_STATISTICS ('Sales.SalesOrderDetail', IX_SalesOrderDetail_ProductID);
GO

SELECT * 
FROM Sales.SalesOrderDetail
WHERE ProductID = 831;
GO

SELECT * 
FROM Sales.SalesOrderDetail
WHERE ProductID = 828;
GO

SELECT * 
FROM Sales.SalesOrderDetail
WHERE ProductID < 714;
GO

SELECT * 
FROM Sales.SalesOrderDetail
WHERE ProductID = 870 AND OrderQty = 1;
GO

SELECT * 
FROM Sales.SalesOrderDetail
WHERE ProductID = 870 OR OrderQty = 1;
GO

SELECT ProductID, COUNT(*) AS Total
FROM Sales.SalesOrderDetail
WHERE ProductID BETWEEN 827 AND 831
GROUP BY ProductID;
GO