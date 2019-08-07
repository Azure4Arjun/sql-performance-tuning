--SARG
USE AdventureWorks
GO
SELECT * 
FROM Sales.SalesOrderHeader
WHERE CustomerID <2

SELECT * 
FROM Sales.SalesOrderHeader
WHERE CustomerID+0 <2
GO

SELECT *
FROM Sales.SalesOrderHeader 
WHERE SalesOrderNumber='SO43860'

SELECT *
FROM Sales.SalesOrderHeader
WHERE UPPER(SalesOrderNumber)='SO43860'
GO
