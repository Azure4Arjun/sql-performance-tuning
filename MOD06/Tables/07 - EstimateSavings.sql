
-- Need to be in the database context
USE LockEscalationTest;
GO

-- All partitions
EXEC sp_estimate_data_compression_savings
	@schema_name = 'dbo',
	@object_name = 'MyPartitionedTable',
	@index_id = 1,
	@partition_number = NULL,
	@data_compression = 'PAGE';
GO

-- Single partition
EXEC sp_estimate_data_compression_savings
	@schema_name = 'dbo',
	@object_name = 'MyPartitionedTable',
	@index_id = 1,
	@partition_number = 1,
	@data_compression = 'PAGE';
GO

-- Let's try a larger tables:
USE SparseColumnsTest;
GO

-- Try ROW first...
EXEC sp_estimate_data_compression_savings
	@schema_name = 'dbo',
	@object_name = 'NonSparseDocRepository',
	@index_id = NULL,
	@partition_number = NULL,
	@data_compression = 'ROW';
GO

-- Try PAGE next...
EXEC sp_estimate_data_compression_savings
	@schema_name = 'dbo',
	@object_name = 'NonSparseDocRepository',
	@index_id = NULL,
	@partition_number = NULL,
	@data_compression = 'PAGE';
GO

-- Unfortunately can't try both at once
-- Note the size of free space needed in TEMPDB - could
-- be a bottleneck on large systems
-- Note they're almost the same so not much point adding
-- PAGE compression

-- Don't try it on the table with SPARSE columns - seems
-- to go into an infinite loop and eats up all available
-- memory
--EXEC sp_estimate_data_compression_savings
	@schema_name = 'dbo',
	@object_name = 'SparseDocRepository',
	@index_id = NULL,
	@partition_number = NULL,
	@data_compression = 'ROW';
GO

