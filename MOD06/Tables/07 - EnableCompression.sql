USE SparseColumnsTest;
GO

-- Time updating all rows
DBCC DROPCLEANBUFFERS;
GO

UPDATE NonSparseDocRepository
SET c103 = 1;
GO
-- Time: approx 51 seconds
-- Explain about DBCC DROPCLEANBUFFERS, how update is a
-- good test as it needs to read all the pages plus crack
-- the row format

-- How many pages total?
SELECT * FROM sys.dm_db_index_physical_stats (
	DB_ID ('SparseColumnsTest'),
	OBJECT_ID ('SparseColumnsTest.dbo.NonSparseDocRepository'),
	NULL, NULL, 'DETAILED');
GO
-- Page count: 100000 + 371 + 1

-- Turn on compression
ALTER TABLE NonSparseDocRepository REBUILD
WITH (DATA_COMPRESSION = ROW);
GO
-- Takes about 1 minute

-- Explain about the new syntax, extra disk space, extra
-- log/backup space. Especially problematic for VLDBs
-- that may not be able to rebuild normally.
-- Trying page compression would take much longer for no
-- gain

-- Time the update again
DBCC DROPCLEANBUFFERS;
GO

UPDATE NonSparseDocRepository
SET c103 = 2;
GO
-- Wow. Must be a huge decrease in the number of pages

SELECT * FROM sys.dm_db_index_physical_stats (
	DB_ID ('SparseColumnsTest'),
	OBJECT_ID ('SparseColumnsTest.dbo.NonSparseDocRepository'),
	NULL, NULL, 'DETAILED');
GO
-- Page count:

-- Out of interest, show the estimation for *removing*
-- compression
EXEC sp_estimate_data_compression_savings
	@schema_name = 'dbo',
	@object_name = 'NonSparseDocRepository',
	@index_id = NULL,
	@partition_number = NULL,
	@data_compression = 'NONE';
GO

