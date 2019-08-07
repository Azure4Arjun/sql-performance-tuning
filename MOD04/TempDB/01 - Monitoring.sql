/*

	Training:	Optimizing and Troubleshooting
	Module:		05 - SQL Server Configuration
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/

USE tempdb;
GO

SELECT * FROM sys.dm_db_task_space_usage;
GO
SELECT * FROM sys.dm_db_session_space_usage;
GO

SELECT SUM (user_object_reserved_page_count)*8 as [User Objects KB], 
SUM (internal_object_reserved_page_count)*8 as [Internal Objects KB], 
SUM (version_store_reserved_page_count)*8 as [Version Store KB], 
SUM (unallocated_extent_page_count)*8 as [Freespace KB]
FROM sys.dm_db_file_space_usage;
GO

SELECT t1.session_id, t1.task_alloc AS [Pages Allocated],
t1.task_dealloc AS [Pages Deallocated],sql.text AS [Last Query]
FROM (SELECT session_id, 
SUM(user_objects_alloc_page_count) AS task_alloc,
SUM (user_objects_dealloc_page_count) AS task_dealloc 
FROM sys.dm_db_session_space_usage
WHERE database_id = DB_ID('tempdb') 
GROUP BY session_id) AS t1 
INNER JOIN sys.dm_exec_connections AS t2
ON t1.session_id = t2.session_id 
CROSS APPLY sys.dm_exec_sql_text(t2.most_recent_sql_handle) AS sql
WHERE t1.session_id > 50
ORDER BY t1.task_alloc DESC;

SELECT session_id, wait_type, wait_duration_ms, blocking_session_id, resource_description,
ResourceType = Case
	WHEN CAST(RIGHT(resource_description, LEN(resource_description) - CHARINDEX(':', resource_description, 3)) As Int) - 1 % 8088 = 0 THEN 'Is PFS Page'
	WHEN CAST(RIGHT(resource_description, LEN(resource_description) - CHARINDEX(':', resource_description, 3)) As Int) - 2 % 511232 = 0 THEN 'Is GAM Page'
	WHEN CAST(RIGHT(resource_description, LEN(resource_description) - CHARINDEX(':', resource_description, 3)) As Int) - 3 % 511232 = 0 THEN 'Is SGAM Page'
	ELSE 'Is Not PFS, GAM, or SGAM page' 
END
FROM sys.dm_os_waiting_tasks
WHERE wait_type Like 'PAGE%LATCH_%'
AND resource_description Like '2:%'
GO

SELECT P.object_id, object_name(P.object_id) as object_name, P.index_id, BD.page_type
FROM sys.dm_os_buffer_descriptors BD, sys.allocation_units A, sys.partitions P 
WHERE  BD.allocation_unit_id = A.allocation_unit_id and  
       A.container_id = P.partition_id

