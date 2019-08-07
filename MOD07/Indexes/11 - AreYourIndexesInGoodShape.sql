USE Credit
GO

---------------------------------------------------------------------------------------------------
--1) Create a working version of the Member table called Member2. 
---------------------------------------------------------------------------------------------------

IF OBJECTPROPERTY(object_id('Member2'), 'IsUserTable') = 1
	DROP TABLE dbo.Member2 
GO

SELECT * 
INTO dbo.Member2
FROM dbo.Member



---------------------------------------------------------------------------------------------------
--2) Create indexes on the Member2 table to simulate a realworld environment.
---------------------------------------------------------------------------------------------------

ALTER TABLE dbo.Member2
ADD CONSTRAINT Member2PK
	PRIMARY KEY CLUSTERED (Member_no)
go

CREATE INDEX Member2NameInd 
ON dbo.Member2(LastName, FirstName, MiddleInitial)
go

CREATE INDEX Member2RegionFK
ON dbo.Member2(region_no)
go

CREATE INDEX Member2CorpFK
ON dbo.Member2(corp_no)
go

---------------------------------------------------------------------------------------------------
--3)  Verify the indexes
---------------------------------------------------------------------------------------------------
EXEC sp_helpindex Member2
go

SELECT object_name([object_id]) AS tablename, [index_id], name
FROM sys.indexes
WHERE object_id('Member2') = [object_id]
go

---------------------------------------------------------------------------------------------------
--4) Verify the fragmentation of the indexes
---------------------------------------------------------------------------------------------------
-- 	NOTE: Because the indexes have just been created no fragmentation should exist.
--	In other words, the scan density should be 100% and the extent scan fragmentation 
--	will likely be 0 (however, this is not necessarily guaranteed).

-- Prior to SQL Server 2000 you needed the object ID (so you might run into this "snippet" of code)
	DECLARE @ObjID	int
	SELECT @ObjID = object_id('Member2')
	DBCC SHOWCONTIG(@ObjID)
-- but
-- SQL Server 2000+ supports the object name 
	DBCC SHOWCONTIG('Member2') 
-- and
-- SQL Server 2005 uses DMVs to review density and fragmentation
-- must be in SQL Server 2005 compatibility mode or you'll get syntax errors

SELECT * 
FROM sys.dm_db_index_physical_stats
(db_id(), OBJECT_ID('Credit.dbo.Member2'), 1, NULL, 'detailed')

USE [master]
GO
ALTER DATABASE [Credit] SET COMPATIBILITY_LEVEL = 90
GO

USE Credit
GO
SELECT * 
FROM sys.dm_db_index_physical_stats
(db_id(), OBJECT_ID('Credit.dbo.Member2'), 1, NULL, 'detailed')
---------------------------------------------------------------------------------------------------
-- 5) Simulate Data Modifications/Activity
---------------------------------------------------------------------------------------------------

-- By updating varchar data you will cause the row size to change. Modifications against the 
-- Member2 table will be performed by executing a single update statement that updates 
-- roughly 5% of the table. For completeness, the script takes note of the total time it takes to 
-- execute the modification (this can be helpful to compare).

DECLARE @StartTime	datetime, 
		@EndTime	datetime,
		@NumRowsMod		int,
		@TotalTime			int
SELECT @StartTime = getdate()
UPDATE Member2
	SET street = '1234 Main St.',
		city = 'Anywhere'
WHERE Member_no % 19 = 0
SELECT @NumRowsMod = @@RowCount
SELECT @EndTime = getdate()
SELECT  @TotalTime = datediff (ms, @StartTime, @EndTime) 
SELECT @NumRowsMod AS 'RowsModified', @TotalTime AS 'TOTAL TIME (ms)',
	convert(decimal(10,3), @NumRowsMod)/@TotalTime AS 'Rows per ms',
	convert(decimal(10,3), @NumRowsMod)/@TotalTime*1000 AS 'Estimated Rows per sec'
go
---------------------------------------------------------------------------------------------------
-- 6) Let's look at the effect that this has had on our Member2 table.
---------------------------------------------------------------------------------------------------

-- Use the DMV to review the table's fragmentation
SELECT * 
FROM sys.dm_db_index_physical_stats(db_id(), OBJECT_ID('Credit.dbo.Member2'), 1, NULL, 'detailed')
go

-- 	NOTE: the fragmentation should be extreme as the 
--  avg_fragmentation_in_percent will probably be a VERY high
-- 	number. (should be somewhere around 83%)
--	For such a "fast" operation, I bet you didn't really
--  expect that much fragmentation?



ALTER INDEX Member2PK ON Member2 REBUILD
	WITH (ONLINE = ON, FILLFACTOR = 90)
go
ALTER INDEX Member2PK ON Member2 REBUILD
	WITH (ONLINE = OFF, FILLFACTOR = 90)
go


-- Here's the syntax to the old way to do this:
-- DBCC DBREINDEX (Member2, Member2PK, 90)
go

---------------------------------------------------------------------------------------------------
-- 9) Recheck the fragmentation
---------------------------------------------------------------------------------------------------
SELECT * 
FROM sys.dm_db_index_physical_stats(db_id(), OBJECT_ID('Credit.dbo.Member2'), 1, NULL, 'detailed')
go

---------------------------------------------------------------------------------------------------
-- 10) Execute another modification - of more rows with the potential for more fragmentation....
---------------------------------------------------------------------------------------------------

DECLARE @StartTime	datetime, 
		@EndTime	datetime,
		@NumRowsMod		int,
		@TotalTime			int
SELECT @StartTime = getdate()
UPDATE Member2
	SET street = '1234 Main St.',
		city = 'Anywhere'
WHERE Member_no % 17 = 0
SELECT @NumRowsMod = @@RowCount
SELECT @EndTime = getdate()
SELECT  @TotalTime = datediff (ms, @StartTime, @EndTime) 
SELECT @NumRowsMod AS 'RowsModified', @TotalTime AS 'TOTAL TIME (ms)',
	convert(decimal(10,3), @NumRowsMod)/@TotalTime AS 'Rows per ms',
	convert(decimal(10,3), @NumRowsMod)/@TotalTime*1000 AS 'Estimated Rows per sec'
go
-- Keep track of the time: 10
-- Keep track of the number of rows: 588
-- Keep track of the rows/ms: 58.8

---------------------------------------------------------------------------------------------------
-- 11) Again, check the fragmentation....
---------------------------------------------------------------------------------------------------

SELECT * 
FROM sys.dm_db_index_physical_stats(db_id(), OBJECT_ID('Credit.dbo.Member2'), 1, NULL, 'detailed')
go

-- NOTE: While more rows were modified it took less time and did not create fragmentation.

---------------------------------------------------------------------------------------------------
-- 12) Execute another modification - of even more rows with the potential for even more fragmentation....
---------------------------------------------------------------------------------------------------

DECLARE @StartTime	datetime, 
		@EndTime	datetime,
		@NumRowsMod		int,
		@TotalTime			int
SELECT @StartTime = getdate()
UPDATE Member2
	SET street = '1234 Main St.',
		city = 'Anywhere'
WHERE Member_no % 11 = 0
SELECT @NumRowsMod = @@RowCount
SELECT @EndTime = getdate()
SELECT  @TotalTime = datediff (ms, @StartTime, @EndTime) 
SELECT @NumRowsMod AS 'RowsModified', @TotalTime AS 'TOTAL TIME (ms)',
	convert(decimal(10,3), @NumRowsMod)/@TotalTime AS 'Rows per ms',
	convert(decimal(10,3), @NumRowsMod)/@TotalTime*1000 AS 'Estimated Rows per sec'
go
-- Keep track of the time: 23
-- Keep track of the number of rows: 909
-- Keep track of the rows/ms: 39.5

---------------------------------------------------------------------------------------------------
-- 13) Again, check the fragmentation....
---------------------------------------------------------------------------------------------------

SELECT * 
FROM sys.dm_db_index_physical_stats(db_id(), OBJECT_ID('Credit.dbo.Member2'), 1, NULL, 'detailed')
go


-- Automatically rebuild/reorganize database indexes 
-- Ensure a USE <databasename> statement has been executed first. 

SET NOCOUNT ON; 
DECLARE @objectid int; 
DECLARE @indexid int; 
DECLARE @partitioncount bigint; 
DECLARE @schemaname nvarchar(130); 
DECLARE @objectname nvarchar(130); 
DECLARE @indexname nvarchar(130); 
DECLARE @partitionnum bigint; 
DECLARE @partitions bigint; 
DECLARE @frag float; 
DECLARE @command nvarchar(4000); 
DECLARE @dbid smallint; 

-- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function
-- and convert object and index IDs to names. 

SET @dbid = DB_ID(); 
SELECT 
    [object_id] AS objectid, 
    index_id AS indexid, 
    partition_number AS partitionnum, 
    avg_fragmentation_in_percent AS frag, page_count 
INTO #work_to_do 
FROM sys.dm_db_index_physical_stats (@dbid, NULL, NULL , NULL, N'LIMITED') 
WHERE avg_fragmentation_in_percent > 10.0  -- Allow limited fragmentation 
AND index_id > 0 -- Ignore heaps 
AND page_count > 25; -- Ignore small tables 

-- Declare the cursor for the list of partitions to be processed. 

DECLARE partitions CURSOR FOR SELECT objectid,indexid, partitionnum,frag FROM #work_to_do; 
-- Open the cursor. 
OPEN partitions; 
-- Loop through the partitions. 
WHILE (1=1) 
	BEGIN 
	FETCH NEXT FROM partitions 
	INTO @objectid, @indexid, @partitionnum, @frag; 
	IF @@FETCH_STATUS < 0 BREAK; 
	SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name) 
	FROM sys.objects AS o 
	JOIN sys.schemas as s ON s.schema_id = o.schema_id 
	WHERE o.object_id = @objectid; 
	SELECT @indexname = QUOTENAME(name) 
	FROM sys.indexes 
	WHERE object_id = @objectid AND index_id = @indexid; 
	SELECT @partitioncount = count (*) 
	FROM sys.partitions 
	WHERE object_id = @objectid AND index_id = @indexid; 
-- 30 is an arbitrary decision point at which to switch between reorganizing and rebuilding.
	IF @frag < 30.0 
		SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';
	IF @frag >= 30.0 
		SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD';
	IF @partitioncount > 1 
		SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10)); 
	EXEC (@command); 
	PRINT N'Executed: ' + @command; 
END 

-- Close and deallocate the cursor. 
CLOSE partitions; 
DEALLOCATE partitions; 

-- Drop the temporary table. 
DROP TABLE #work_to_do; 
GO 
