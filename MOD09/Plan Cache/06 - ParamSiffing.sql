USE tempdb;
-- create a table with 2000 rows.  1000 of them have the values 1 to 1000 each once (no 
-- duplicates).  Then we have 1000 rows with the value 5000.

--drop table t

CREATE TABLE t(col1 int);
DECLARE @i int;

SET @i = 0;
WHILE @i < 1000
BEGIN
	INSERT INTO t(col1) VALUES (@i);
	SET @i = @i + 1;
END

SET @i = 0
WHILE @i < 1000
BEGIN
	INSERT INTO t(col1) VALUES (5000)
	SET @i = @i + 1
END
GO
 
-- Let's create some fullscan statistics on the column in our table

CREATE STATISTICS t_col1 ON t(col1) 
WITH FULLSCAN;

-- note that the selectivity (all density) for the table in the statistics is 1/1001 = 9.9900097E-4;  There are 1001 distinct values in the table

DBCC SHOW_STATISTICS ('dbo.t','t_col1')
GO
 
-- compile with no value to sniff.  We should use the "density" for the whole table to make our estimate
-- which means that we'll take 2000 rows * 1/1001 = about 2 rows returned

DBCC FREEPROCCACHE
GO

DECLARE @p int;
SET @p=2;
SELECT * 
FROM T 
WHERE COL1 = @P;
GO

DBCC FREEPROCCACHE
GO

DECLARE @p int;
SET @p=5000;
SELECT * 
FROM T 
WHERE COL1 = @P;
GO

-- Let's use the option recompile as a workaround. 

DBCC FREEPROCCACHE
GO

-- now look at the compiled plan for this case - we've recompiled and correctly estimate 1 or 5000 row(s)
DECLARE @p int;
SET @p=2;
SELECT * 
FROM T 
WHERE COL1 = @P
OPTION(RECOMPILE);
GO

DECLARE @p int;
SET @p=5000;
SELECT * 
FROM T 
WHERE COL1 = @P
OPTION(RECOMPILE);
GO

-- Another (better) workaround is to use the new optimize for hint - it avoids the recompile
-- and we estimate 1 row

DBCC FREEPROCCACHE
GO

DECLARE @p int;
SET @p=1;
SELECT * 
FROM T 
WHERE COL1 = @P
OPTION (OPTIMIZE FOR (@p = 1))


DBCC FREEPROCCACHE
GO

DECLARE @p int;
SET @p=1;
SELECT * 
FROM T 
WHERE COL1 = @P
OPTION (OPTIMIZE FOR UNKNOWN) 
