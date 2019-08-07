/*

	Training:	Optimizing and Troubleshooting
	Module:		06 - Database Configuration
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/
SELECT *
FROM sys.databases; 

SELECT DB_NAME([database_id])AS [Database Name],[file_id], name, physical_name,
type_desc, state_desc, size * 8 / 1024 AS [Size in MB], growth, is_percent_growth
FROM sys.master_files
WHERE [database_id] > 4 AND [database_id] <> 32767 OR [database_id] = 2;


SELECT DB_NAME(fs.database_id) AS [Database Name], name, io_stall_read_ms,num_of_reads,
CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS[Avg Read stall ms],
io_stall_write_ms,num_of_writes,
CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1)) AS [Avg Write stall ms],
io_stall_read_ms + io_stall_write_ms AS [io_stalls], 
num_of_reads + num_of_writes AS [total_io],
CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) 
AS NUMERIC(10,1)) AS [Avg io stall ms]
FROM sys.dm_io_virtual_file_stats(null,null) AS fs
INNER JOIN sys.master_files AS mf
ON fs.database_id = mf.database_id
AND fs.[file_id] = mf.[file_id]
ORDER BY [Avg io stall ms] DESC;

SELECT instance_name, cntr_value 'Log Growths'
FROM sys.dm_os_performance_counters 
WHERE counter_name = 'Log Growths';

SELECT db.[name] AS [Database Name], db.log_reuse_wait_desc, 
ls.cntr_value AS [Log Size (KB)], lu.cntr_value AS [Log Used (KB)],
CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) * 100 AS [Log Used %]
FROM sys.databases AS db
INNER JOIN sys.dm_os_performance_counters AS lu 
ON db.name = lu.instance_name
INNER JOIN sys.dm_os_performance_counters AS ls 
ON db.name = ls.instance_name
WHERE lu.counter_name LIKE N'Log File(s) Used Size (KB)%' 
AND ls.counter_name LIKE N'Log File(s) Size (KB)%'
AND ls.cntr_value > 0;


SELECT CASE
 WHEN database_id = 32767 THEN 'mssqlsystemresource'
 ELSE DB_NAME(database_id)
 END AS [Database],
CONVERT(numeric(38,2),(8.0 / 1024) * COUNT(*)) AS [In buffer cache (MB)]
FROM sys.dm_os_buffer_descriptors
GROUP BY database_id
ORDER BY 2 DESC;

SELECT DB_NAME(database_id),
non_transacted_access,
non_transacted_access_desc
FROM sys.database_filestream_options;
GO