--Part 1

USE [AdventureWorks2008R2];
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name ='idxSalesOrderHeaderSubTotal')
	 DROP INDEX idxSalesOrderHeaderSubTotal ON Sales.SalesOrderHeader
GO
 
CREATE INDEX idxSalesOrderHeaderSubTotal
ON Sales.SalesOrderHeader ([SubTotal]);
GO

--turn on the actual execution plan 
SELECT * 
FROM Sales.SalesOrderHeader h
JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderId
WHERE h.[SubTotal] =3578.27;
GO

SELECT * 
FROM Sales.SalesOrderHeader h
JOIN Sales.SalesOrderDetail d
     ON h.SalesOrderID = d.SalesOrderId
WHERE h.[SubTotal] = 1.374;
GO

DECLARE @SubTotal money;
SET @SubTotal = 1.374;
SELECT * 
FROM Sales.SalesOrderHeader h JOIN Sales.SalesOrderDetail d
     ON h.SalesOrderID = d.SalesOrderId
WHERE h.[SubTotal] = @SubTotal;
GO


DBCC SHOW_STATISTICS ('Sales.SalesOrderHeader','idxSalesOrderHeaderSubTotal');
GO



SELECT (SELECT COUNT(*) FROM  Sales.SalesOrderHeader) * 0.0002106594;
GO

DECLARE @SubTotal money 
SET @SubTotal = 3578.27
SELECT * 
FROM Sales.SalesOrderHeader h JOIN Sales.SalesOrderDetail d
     ON h.SalesOrderID = d.SalesOrderId
WHERE h.[SubTotal] = @SubTotal;
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name ='uspGetOrdersBySubTotal')
	 DROP PROCEDURE uspGetOrdersBySubTotal
GO

CREATE PROCEDURE uspGetOrdersBySubTotal(@SubTotal money) AS
SELECT * 
FROM Sales.SalesOrderHeader h JOIN Sales.SalesOrderDetail d
      ON h.SalesOrderID = d.SalesOrderId
WHERE h.[SubTotal] = @SubTotal;
GO

EXECUTE uspGetOrdersBySubTotal 3578.27;
GO
EXECUTE uspGetOrdersBySubTotal 1.374;
GO

--Part 2

ALTER PROCEDURE uspGetOrdersBySubTotal(@SubTotal money) 
WITH RECOMPILE AS
SELECT * 
FROM Sales.SalesOrderHeader h JOIN Sales.SalesOrderDetail d
	ON h.SalesOrderID = d.SalesOrderId
WHERE h.[SubTotal] = @SubTotal;
GO

EXECUTE uspGetOrdersBySubTotal 3578.27;
GO
EXECUTE uspGetOrdersBySubTotal 1.374;
GO

ALTER PROCEDURE uspGetOrdersBySubTotal(@SubTotal money) AS
SELECT * 
FROM Sales.SalesOrderHeader h JOIN Sales.SalesOrderDetail d
	ON h.SalesOrderID = d.SalesOrderId
WHERE h.[SubTotal] = @SubTotal;
GO

DBCC FREEPROCCACHE
GO
EXECUTE uspGetOrdersBySubTotal 3578.27;
GO 
EXECUTE uspGetOrdersBySubTotal 1.374 WITH RECOMPILE;
GO
EXECUTE uspGetOrdersBySubTotal 3578.27;
GO

ALTER PROCEDURE uspGetOrdersBySubTotal (@SubTotal money) AS
DECLARE @_SubTotal money;
SET @_SubTotal = @SubTotal;
SELECT * 
FROM Sales.SalesOrderHeader h JOIN Sales.SalesOrderDetail d
	ON h.SalesOrderID = d.SalesOrderId
WHERE h.[SubTotal] = @_SubTotal;
GO

EXECUTE uspGetOrdersBySubTotal 3578.27;
GO 
EXECUTE uspGetOrdersBySubTotal 1.374;
GO

ALTER PROCEDURE uspGetOrdersBySubTotal (@SubTotal money) AS
SELECT * 
FROM Sales.SalesOrderHeader h JOIN Sales.SalesOrderDetail d
	ON h.SalesOrderID = d.SalesOrderId
WHERE h.[SubTotal] = @SubTotal
OPTION (OPTIMIZE FOR UNKNOWN);
GO

EXECUTE uspGetOrdersBySubTotal 3578.27;
GO 
EXECUTE uspGetOrdersBySubTotal 1.374;
GO