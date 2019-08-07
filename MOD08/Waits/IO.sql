SELECT instance_name, cntr_value 'Log Growths'
FROM sys.dm_os_performance_counters 
WHERE counter_name = 'Log Growths';
GO

SELECT instance_name, cntr_value 'Percent Log Used'  
FROM sys.dm_os_performance_counters
WHERE counter_name ='Percent Log Used';  
GO

SELECT  
   DB_NAME(a.dbid) AS Database_name, 
   b.filename, 
   numberReads, 
   BytesRead, 
   IoStallReadMS, 
   NumberWrites, 
   BytesWritten, 
   IoStallWriteMS
FROM  
   fn_virtualfilestats(NULL,NULL) a INNER JOIN 
   sysaltfiles b ON a.dbid = b.dbid AND a.fileid = b.fileid;
GO

;WITH DBIO AS
(
  SELECT
    DB_NAME(IVFS.database_id) AS db,
    CASE WHEN MF.type = 1 THEN 'log' ELSE 'data' END AS file_type,
    SUM(IVFS.num_of_bytes_read + IVFS.num_of_bytes_written) AS io,
    SUM(IVFS.io_stall) AS io_stall
  FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS IVFS
    JOIN sys.master_files AS MF
      ON IVFS.database_id = MF.database_id
      AND IVFS.file_id = MF.file_id
  GROUP BY DB_NAME(IVFS.database_id), MF.type
)
SELECT db, file_type, 
  CAST(1. * io / (1024 * 1024) AS DECIMAL(12, 2)) AS io_mb,
  CAST(io_stall / 1000. AS DECIMAL(12, 2)) AS io_stall_s,
  CAST(100. * io_stall / SUM(io_stall) OVER()
       AS DECIMAL(10, 2)) AS io_stall_pct
FROM DBIO
ORDER BY io_stall DESC;
GO

SELECT DB_NAME(database_id) as Database_name, file_id, io_stall, io_pending_ms_ticks
FROM sys.dm_io_virtual_file_stats(NULL, NULL)t1, sys.dm_io_pending_io_requests as t2
WHERE t1.file_handle = t2.io_handle;
GO

SELECT TOP 50 text,
(total_logical_reads + total_logical_writes)*8 AS total,
(total_logical_reads/execution_count)*8 as avg_logical_reads, 
(total_logical_writes/execution_count)*8 as avg_logical_writes,
(total_physical_reads/execution_count)*8 as avg_phys_reads, 
Execution_count 
FROM sys.dm_exec_query_stats  
CROSS APPLY sys.dm_exec_sql_text (sql_handle) 
ORDER BY(total_logical_reads + total_logical_writes) DESC;

