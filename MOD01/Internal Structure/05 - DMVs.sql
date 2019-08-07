/*

	Training:	Optimizing and Troubleshooting
	Module:		01 - Internal Structure and Functioning SQL Server
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/
/*

	Training:	Optimizing and Troubleshooting
	Module:		01 - Internal Structure and Functioning SQL Server
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/
--
SELECT *
FROM sys.dm_os_sys_info;
GO

SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [Hyperthread Ratio],
cpu_count/hyperthread_ratio AS [Physical CPU Count], 
--physical_memory_in_bytes/1048576 AS [Physical Memory (MB)], 
physical_memory_kb/1024 AS [Physical Memory (MB)],
GETDATE() AS CurrentDate, (SELECT create_date FROM SYS.databases WHERE database_id=2) AS StartDate, DATEDIFF(DD,(SELECT create_date FROM SYS.databases WHERE database_id=2),GETDATE()) AS DaysRunning
FROM sys.dm_os_sys_info;
GO

SELECT
 database_id,
 convert(varchar(25), DB.name) as dbName,
 convert(varchar(10), Databasepropertyex(name, 'status')) as [Status],
 (SELECT COUNT(1) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'rows') AS DataFiles,
 (SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'rows') AS [Data MB],
 (SELECT COUNT(1) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'log') AS LogFiles,
 (SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'log') AS [Log MB],
 user_access_desc AS [User access],
 recovery_model_desc as [Recovery model],
 CASE compatibility_level
 WHEN 60 THEN '60 (SQL Server 6.0)'
 WHEN 65 THEN '65 (SQL Server 6.5)'
 WHEN 70 THEN '70 (SQL Server 7.0)'
 WHEN 80 THEN '80 (SQL Server 2000)'
 WHEN 90 THEN '90 (SQL Server 2005)'
 WHEN 100 THEN '100 (SQL Server 2008/2008 R2)' 
 WHEN 110 THEN '110 (SQL Server 2012)' 
END AS [compatibility level],
 CONVERT(VARCHAR(20), create_date, 103) + ' ' + CONVERT(VARCHAR(20), create_date, 108) as [Creation date],
 ISNULL((SELECT TOP 1
 CASE TYPE WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Transaction log' END + ' – ' +
ltrim(ISNULL(STR(ABS(DATEDIFF(day, GetDate(),Backup_finish_date))) + ' days ago', 'NEVER')) + ' – ' +
CONVERT(VARCHAR(20), backup_start_date, 103) + ' ' + CONVERT(VARCHAR(20), backup_start_date, 108) + ' – ' +
CONVERT(VARCHAR(20), backup_finish_date, 103) + ' ' + CONVERT(VARCHAR(20), backup_finish_date, 108) +
' (' + CAST(DATEDIFF(second, BK.backup_start_date,
 BK.backup_finish_date) AS VARCHAR(4)) + ' '
+ 'seconds)'
FROM msdb..backupset BK WHERE BK.database_name = DB.name ORDER BY backup_set_id DESC),'-') AS [Last backup],
 CASE WHEN is_fulltext_enabled = 1 THEN 'Fulltext enabled' ELSE '' END AS [fulltext],
 CASE WHEN is_auto_close_on = 1 THEN 'autoclose' ELSE '' END AS [autoclose],
 page_verify_option_desc AS [page verify option],
 CASE WHEN is_read_only = 1 THEN 'read only' ELSE '' END AS [read only],
 CASE WHEN is_auto_shrink_on = 1 THEN 'autoshrink' ELSE '' END AS [autoshrink],
 CASE WHEN is_auto_create_stats_on = 1 THEN 'auto create statistics' ELSE '' END AS [auto create statistics],
 CASE WHEN is_auto_update_stats_on = 1 THEN 'auto update statistics' ELSE '' END AS [auto update statistics],
 CASE WHEN  is_auto_update_stats_async_on  =1 THEN 'async auto update statistics' ELSE '' END AS [async auto update statistics],
 CASE WHEN is_parameterization_forced =1 THEN 'parameterization forced' ELSE '' END AS [parameterization forced]
 FROM sys.databases DB
 ORDER BY dbName, [Last backup] DESC, NAME;
GO

SELECT affinity_type_desc, process_user_time_ms, 
CAST (CAST(process_user_time_ms AS FLOAT) /
(CAST(process_kernel_time_ms AS FLOAT) + CAST (process_user_time_ms AS FLOAT)) 
* 100 AS DECIMAL(9,2)) AS [% SQL User Time],
process_kernel_time_ms,
CAST (CAST(process_kernel_time_ms AS FLOAT) /
(CAST(process_kernel_time_ms AS FLOAT) + CAST (process_user_time_ms AS FLOAT)) 
* 100 AS DECIMAL(9,2)) AS [% SQL Kernel Time]
FROM sys.dm_os_sys_info;
GO


SELECT *  
FROM sys.dm_exec_query_optimizer_info;
GO
-- Monitoring CLR
SELECT * FROM sys.dm_clr_appdomains;
GO
SELECT * FROM sys.dm_clr_loaded_assemblies;
GO
--IO operations
SELECT * FROM sys.dm_io_pending_io_requests;
GO
-- Monitoring Service Broker
SELECT * FROM sys.dm_broker_queue_monitors;
GO

