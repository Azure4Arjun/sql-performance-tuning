USE AdventureWorks2008R2;
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name ='uspGetSpecialOfferHistory')
	 DROP PROCEDURE uspGetSpecialOfferHistory
GO

CREATE PROCEDURE uspGetSpecialOfferHistory (
    @SpecialOfferID int = NULL)
AS
IF @SpecialOfferID IS NULL
    SELECT SUM([SubTotal])
    FROM Sales.SalesOrderHeader h JOIN Sales.SalesOrderDetail d
        ON h.SalesOrderID = d.SalesOrderId; 
ELSE
    SELECT SUM([SubTotal])
    FROM Sales.SalesOrderHeader h JOIN Sales.SalesOrderDetail d
        ON h.SalesOrderID = d.SalesOrderId
    WHERE [SpecialOfferID] = @SpecialOfferID;
GO

EXEC uspGetSpecialOfferHistory;
GO

SELECT cp.usecounts, qt.text, qp.query_plan
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS qt
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
WHERE qt.text LIKE '%Sales.SalesOrderHeader%'
AND qt.text NOT like '%dm_exec_sql_text%';
GO

SET STATISTICS IO ON;
GO
DBCC FREEPROCCACHE;
GO

EXEC uspGetSpecialOfferHistory;
GO
EXEC uspGetSpecialOfferHistory @SpecialOfferID = 1;
GO

SELECT cp.usecounts, qt.text, qp.query_plan
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS qt
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
WHERE qt.text LIKE '%Sales.SalesOrderHeader%'
AND qt.text NOT like '%dm_exec_sql_text%';