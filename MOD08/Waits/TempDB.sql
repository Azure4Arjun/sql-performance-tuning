SELECT cntr_value 'Data Files(s) Size (KB) '
FROM sys.dm_os_performance_counters 
WHERE object_name LIKE '%Databases%' 
AND counter_name ='Data File(s) Size (KB)'
AND instance_name = 'tempdb';

SELECT cntr_value 'Log File(s) Size (KB) '
FROM sys.dm_os_performance_counters 
WHERE object_name LIKE '%Databases%' 
AND counter_name ='Log File(s) Size (KB) '
AND instance_name = 'tempdb';
GO

SELECT SUM (user_object_reserved_page_count)*8 as user_objects_kb, 
SUM (internal_object_reserved_page_count)*8 as internal_objects_kb, 
SUM (version_store_reserved_page_count)*8  as version_store_kb, 
SUM (unallocated_extent_page_count)*8 as freespace_kb
FROM sys.dm_db_file_space_usage
WHERE database_id = 2;
GO

SELECT TOP 25
    t1.session_id, 
    (t1.internal_objects_alloc_page_count + task_alloc)*8 as allocated, 
    (t1.internal_objects_dealloc_page_count + task_dealloc)*8 as     
    deallocated  
from sys.dm_db_session_space_usage as t1,  
    (select session_id,  
        sum(internal_objects_alloc_page_count) 
            as task_alloc, 
    sum (internal_objects_dealloc_page_count) as  
        task_dealloc  
      from sys.dm_db_task_space_usage group by session_id) as t2 
where t1.session_id = t2.session_id and t1.session_id >50 
order by allocated DESC;
GO

SELECT session_id, wait_type, wait_duration_ms, blocking_session_id, resource_description,
ResourceType = Case
	WHEN CAST(RIGHT(resource_description, LEN(resource_description) - CHARINDEX(':', resource_description, 3)) As Int) - 1 % 8088 = 0 THEN 'Is PFS Page'
	WHEN CAST(RIGHT(resource_description, LEN(resource_description) - CHARINDEX(':', resource_description, 3)) As Int) - 2 % 511232 = 0 THEN 'Is GAM Page'
	WHEN CAST(RIGHT(resource_description, LEN(resource_description) - CHARINDEX(':', resource_description, 3)) As Int) - 3 % 511232 = 0 THEN 'Is SGAM Page'
	ELSE 'Is Not PFS, GAM, or SGAM page' 
END
FROM sys.dm_os_waiting_tasks WITH (NOLOCK)
WHERE wait_type Like 'PAGE%LATCH_%'
AND resource_description Like '2:%';
GO
