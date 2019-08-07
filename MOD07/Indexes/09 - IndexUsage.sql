-- Look at index usage stats
SELECT * FROM sys.dm_db_index_usage_stats;
GO

-- Now use a filter on the DMV
SELECT * FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID('AdventureWorks')
and object_id = OBJECT_ID('Person.Address');
GO

-- Do something to use the table
SELECT *
FROM AdventureWorks.Person.Address;
GO

-- Do something to use a non-clustered index
SELECT StateProvinceID
FROM AdventureWorks.Person.Address
WHERE StateProvinceID > 4
AND StateProvinceID < 15;
GO

-- Try again...
SELECT * FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID('AdventureWorks')
and object_id = OBJECT_ID('AdventureWorks.Person.Address');
GO

-- Create a table to hold the periodic snapshots of index
-- usage stats
USE Tempdb
go

IF OBJECTPROPERTY(object_id(N'MyIndexUsageStats'), 
	'IsUserTable') = 1
	DROP TABLE MyIndexUsageStats;
GO

SELECT GETDATE () AS ExecutionTime, *
INTO Tempdb.dbo.MyIndexUsageStats
FROM sys.dm_db_index_usage_stats WHERE database_id=0;
GO

-- Take a baseline snapshot of the index usage stats DMV
INSERT Tempdb.dbo.MyIndexUsageStats 
	SELECT getdate (), * 
FROM sys.dm_db_index_usage_stats;
GO

-- Do a bunch of stuff
SELECT * FROM AdventureWorks.Person.Address;
GO
SELECT * FROM AdventureWorks.Person.Address;
GO
SELECT StateProvinceID
FROM AdventureWorks.Person.Address
WHERE StateProvinceID > 4
AND StateProvinceID < 15;
GO

-- Take another snapshot
INSERT Tempdb.dbo.MyIndexUsageStats 
	SELECT getdate (), * 
FROM sys.dm_db_index_usage_stats;
GO

-- Look at the history of usage
SELECT * FROM Tempdb.dbo.MyIndexUsageStats
WHERE database_id = DB_ID('AdventureWorks')
and object_id = OBJECT_ID('AdventureWorks.Person.Address');
GO


SELECT db_name(database_id) AS 'Database Name'
	, object_name(object_id, database_id) AS 'Object Name'
	, index_id
	, partition_number
	, leaf_insert_count, leaf_delete_count, leaf_update_count, leaf_ghost_count
	, nonleaf_insert_count, nonleaf_delete_count, nonleaf_update_count
	, leaf_allocation_count, nonleaf_allocation_count
	, leaf_page_merge_count, nonleaf_page_merge_count 
	, range_scan_count
	, singleton_lookup_count
	, forwarded_fetch_count
	, lob_fetch_in_pages
	, lob_fetch_in_bytes
	, lob_orphan_create_count
	, lob_orphan_insert_count
	, row_overflow_fetch_in_pages
	, row_overflow_fetch_in_bytes
	, column_value_push_off_row_count
	, column_value_pull_in_row_count
	, row_lock_count
	, row_lock_wait_count
	, row_lock_wait_in_ms
	, page_lock_count
	, page_lock_wait_count
	, page_lock_wait_in_ms
	, index_lock_promotion_attempt_count
	, index_lock_promotion_count
	, page_latch_wait_count
	, page_latch_wait_in_ms
	, page_io_latch_wait_count
	, page_io_latch_wait_in_ms
FROM sys.dm_db_index_operational_stats 
	(db_id('credit'), null, null, null)
WHERE object_id > 100


-- Possible Bad NC Indexes (writes > reads)
-- Consider your complete workload
-- Investigate further before dropping an index

SELECT OBJECT_NAME(s.[object_id]) AS [Table Name], i.name AS [Index Name], i.index_id,
user_updates AS [Total Writes], user_seeks + user_scans + user_lookups AS [Total Reads],
user_updates - (user_seeks + user_scans + user_lookups) AS [Difference]
FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON s.[object_id] = i.[object_id]
AND i.index_id = s.index_id
WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
AND s.database_id = DB_ID()
AND user_updates > (user_seeks + user_scans + user_lookups)
AND i.index_id > 1
ORDER BY [Difference] DESC, [Total Writes] DESC, [Total Reads] ASC;


