-- Types of Hints

-- Table Hints, use of WITH is recommended
-- Most Table Hints deal with LOCKING
-- Exceptions INDEX  and FASTFIRSTROW

USE AdventureWorks
GO

SELECT * 
FROM Sales.SalesOrderDetail 
ORDER BY ProductID 

SELECT * 
FROM Sales.SalesOrderDetail WITH (FASTFIRSTROW)
ORDER BY ProductID 
GO

SELECT * 
FROM Sales.SalesOrderDetail 
ORDER BY SalesOrderID

SELECT * 
FROM Sales.SalesOrderDetail WITH (FASTFIRSTROW)
ORDER BY SalesOrderID
GO


-- JOIN HINTS

-- Note the join order; the outer(build) table is on top
SELECT * 
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h
	ON h.SalesOrderID = d.SalesOrderID

-- Even with the same type of join, the join order changes		   
SELECT * 
FROM Sales.SalesOrderDetail d
INNER HASH JOIN Sales.SalesOrderHeader h
	ON h.SalesOrderID = d.SalesOrderID
		   
SELECT * 
FROM Sales.SalesOrderDetail d
INNER LOOP JOIN Sales.SalesOrderHeader h
	ON h.SalesOrderID = d.SalesOrderID


-- OPTION HINTS
		   
SELECT * 
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h
	ON h.SalesOrderID = d.SalesOrderID
	OPTION (HASH JOIN)

-- AGGREGATIONS HINTS

SELECT SalesOrderID, COUNT(*)
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

SELECT SalesOrderID, COUNT(*)
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
OPTION (HASH GROUP);
GO

SELECT COUNT(*)
FROM Sales.SalesOrderDetail
OPTION (HASH GROUP)
GO

-- OPTIMIZATION HINTS

-- Variables can give unexpected behavior

SELECT * 
FROM Sales.SalesOrderDetail
WHERE ProductID = 897;

DECLARE @PID int = 897
SELECT * 
FROM Sales.SalesOrderDetail
WHERE ProductID = @PID;
GO
-- You can use RECOMPILE or OPTIMIZE FOR hint

-- The estimated plan can fool you
DECLARE @PID int;
SET @PID= 897;
SELECT * 
FROM sales.SalesOrderDetail
WHERE ProductID = @PID
OPTION (RECOMPILE);
GO
-- Turn on actual plan instead

-- Optimize for a specific value
DECLARE @PID int;
SET @PID= 897;
SELECT * 
FROM sales.SalesOrderDetail
WHERE ProductID = @PID
OPTION (OPTIMIZE FOR (@PID = 897));
GO

-- What if the value is different? 
DECLARE @PID int; 
SET @PID = 873;
SELECT * FROM sales.SalesOrderDetail
WHERE ProductID = @PID
OPTION (OPTIMIZE FOR (@PID = 897));
GO
-- What's so bad about a nonclustered index seek?

SET STATISTICS IO ON
GO

-- Compare performance with and without the hint
DECLARE @PID int; 
SET @PID = 873;
SELECT * FROM sales.SalesOrderDetail
WHERE ProductID = @PID

SELECT * FROM sales.SalesOrderDetail
WHERE ProductID = @PID
OPTION (OPTIMIZE FOR (@PID = 897));
GO

SET STATISTICS IO OFF
GO


--  FORCESEEK is new in 2008
SELECT *
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d 
    ON h.SalesOrderID = d.SalesOrderID 
WHERE h.TotalDue > 100
AND (d.OrderQty > 5 OR d.LineTotal < 1000.00);
GO
SELECT *
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d WITH (FORCESEEK)
    ON h.SalesOrderID = d.SalesOrderID 
WHERE h.TotalDue > 100
AND (d.OrderQty > 5 OR d.LineTotal < 1000.00);
GO

