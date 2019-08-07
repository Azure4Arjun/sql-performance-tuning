--SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,NULL);
SELECT * FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID() and (index_id = 1 or index_id = 0)