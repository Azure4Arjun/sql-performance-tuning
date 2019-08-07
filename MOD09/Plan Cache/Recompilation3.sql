USE AdventureWorks2008R2;
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name ='uspStatisticsChangeRecompliationv1')
	 DROP PROCEDURE uspStatisticsChangeRecompliationv1
GO

CREATE PROCEDURE uspStatisticsChangeRecompliationv1 AS 
BEGIN 
    CREATE TABLE tab1 (col int);
    DECLARE @i int = 0;
    WHILE (@i < 10)
    BEGIN
            INSERT INTO tab1 VALUES (@i);
            SET @i += 1; 
            SELECT col FROM tab1 GROUP BY col;
    END
    DROP TABLE tab1;
END 
GO

--start Profiler, capture a SP:Recompile event 

EXEC uspStatisticsChangeRecompliationv1;
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name ='uspStatisticsChangeRecompliationv2')
	 DROP PROCEDURE uspStatisticsChangeRecompliationv2
GO

CREATE PROCEDURE uspStatisticsChangeRecompliationv2 AS 
BEGIN 
    CREATE TABLE #tab1 (col int);
    DECLARE @i int = 0;
    WHILE (@i < 10) 
    BEGIN
            INSERT INTO #tab1 VALUES (@i);
            SET @i += 1; 
            SELECT col FROM #tab1 GROUP BY col;
    END
    TRUNCATE TABLE #tab1;
END 
GO

EXEC uspStatisticsChangeRecompliationv2;
GO 2

ALTER PROCEDURE uspStatisticsChangeRecompliationv2 AS 
BEGIN 
    CREATE TABLE #tab1 (col int);
    DECLARE @i int = 0;
    WHILE (@i < 10) 
    BEGIN
            INSERT INTO #tab1 VALUES (@i);
            SET @i += 1; 
            SELECT col FROM #tab1 
            GROUP BY col OPTION (KEEP PLAN)  
            --or KEEPFIXED PLAN if appropriate;
    END 
END 
GO

EXEC uspStatisticsChangeRecompliationv2;
GO 2
