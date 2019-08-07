
--	Q. How many sockets does my machine have?
select cpu_count/hyperthread_ratio AS sockets
from  sys.dm_os_sys_info

--Q. How many either cores or logical CPU share the same socket?

select hyperthread_ratio AS cores_or_logical_cpus_per_socket
from sys.dm_os_sys_info

--	Q. Does my 32 bit system have /3GB or /Userva switch in boot.ini? 
select  CASE 
	WHEN virtual_memory_in_bytes / 1024 / (2048*1024) 
	< 1 THEN 'No switch' 
	ELSE '/3GB' 
	END 
from sys.dm_os_sys_info

select  CASE 
	WHEN virtual_memory_kb / (2048*1024) 
	< 1 THEN 'No switch' 
	ELSE '/3GB' 
	END 
from sys.dm_os_sys_info


--	Q. How much physical memory my machine has?
select physical_memory_in_bytes/1024 AS physical_memory_in_kb 
from sys.dm_os_sys_info 

select physical_memory_kb
from sys.dm_os_sys_info 



-- Q. How many threads/workers SQL Server would use if the default value in sp_configure for max worker threads is zero:

select max_workers_count
from sys.dm_os_sys_info

-- Q. Do I need to by more CPUs?
select AVG (runnable_tasks_count) 
from  sys.dm_os_schedulers 
where status = 'VISIBLE ONLINE'

-- Q. What is affinity of my schedulers to CPUs?

select scheduler_id, CAST (cpu_id as varbinary) AS scheduler_affinity_mask
from sys.dm_os_schedulers 

-- Does my machine have either hard or soft NUMA configuration enabled?

select 
	CASE count( DISTINCT parent_node_id)
	WHEN 1 THEN 'NUMA disabled'
	ELSE 'NUMA enabled'
	END
from sys.dm_os_schedulers
where parent_node_id <> 32

--Q: Is my system I/O bound?
/*You can answer this question by monitoring length of I/O queues.
*/
select pending_disk_io_count 
from sys.dm_os_schedulers
