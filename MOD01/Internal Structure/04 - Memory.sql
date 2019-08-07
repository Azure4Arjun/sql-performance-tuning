/*

	Training:	Optimizing and Troubleshooting
	Module:		01 - Internal Structure and Functioning SQL Server
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/
-- DBCC Memory Status
-- Change Results to Text (Ctrl+T)
DBCC MEMORYSTATUS;
GO
-- Change result to Grid (Ctrl+D)
SELECT * FROM sys.dm_os_memory_clerks;
GO

SELECT type, name, pages_kb, memory_node_id,
virtual_memory_reserved_kb, virtual_memory_committed_kb
FROM sys.dm_os_memory_clerks
ORDER BY pages_kb DESC;
GO

SELECT * FROM sys.dm_os_nodes;
GO

SELECT total_physical_memory_kb / 1024 AS total_physical_memory_mb,
available_physical_memory_kb / 1024 AS available_physical_memory_mb, 
total_page_file_kb / 1024 AS total_page_file_mb, 
available_page_file_kb / 1024 AS available_page_file_mb
FROM sys.dm_os_sys_memory;

SELECT cntr_value 'Total AND Target Pages' 
FROM sys.dm_os_performance_counters 
WHERE object_name LIKE '%Buffer Manager%' 
AND counter_name ='Total Pages'
UNION ALL
SELECT cntr_value 
FROM sys.dm_os_performance_counters 
WHERE object_name LIKE '%Buffer Manager%' 
AND counter_name ='Target Pages';


SELECT cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Buffer Manager' 
AND counter_name = 'Page life expectancy';


SELECT CAST
((SELECT CAST(cntr_value * 100 AS FLOAT) 
FROM sys.dm_os_performance_counters 
WHERE counter_name = 'Buffer cache hit ratio') / 
(SELECT cntr_value 
FROM sys.dm_os_performance_counters 
WHERE counter_name = 'Buffer cache hit ratio base') AS NUMERIC (5, 2));

SELECT *
FROM sys.dm_os_ring_buffers
WHERE ring_buffer_type='RING_BUFFER_MEMORY_BROKER';

SELECT 
    x.value('(//Record/@time)[1]', 'bigint') as [Time Stamp], 
    x.value('(//Notification)[1]', 'varchar(100)')  
    as [Last Notification] 
FROM 
    (SELECT CAST(record as xml) 
     FROM sys.dm_os_ring_buffers  
     WHERE ring_buffer_type = 'RING_BUFFER_MEMORY_BROKER') 
     as R(x) 
ORDER BY 
    [Time Stamp] desc;


SELECT  
    x.value('(//Notification)[1]', 'varchar(max)') as [Type], 
    x.value('(//Record/@time)[1]', 'bigint') as [Time Stamp], 
    x.value('(//AvailablePhysicalMemory)[1]', 'bigint')  
    as [Avail Phys Mem, Kb], 
    x.value('(//AvailableVirtualAddressSpace)[1]', 'bigint') 
    as [Avail VAS, Kb] 
FROM  
    (SELECT cast(record as xml) 
     FROM sys.dm_os_ring_buffers  
     WHERE ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR') 
     as R(x) 
    ORDER BY 
    [Time Stamp] desc;


SELECT SUM(multi_pages_kb + virtual_memory_committed_kb
+ shared_memory_committed_kb + awe_allocated_kb) / 1024 AS [Used by BPool with AWE, MB]
FROM sys.dm_os_memory_clerks 
WHERE type = 'MEMORYCLERK_SQLBUFFERPOOL';

SELECT TOP(10) [type], [name], SUM(single_pages_kb)/ 1024.00 AS [SPA Mem, MB] 
FROM sys.dm_os_memory_clerks 
GROUP BY [type], [name] 
ORDER BY SUM(single_pages_kb) DESC;

SELECT buckets_count, buckets_in_use_count, buckets_min_length, buckets_max_length, buckets_avg_length, buckets_avg_scan_hit_length
FROM sys.dm_os_memory_cache_hash_tables;

SELECT clock_hand, clock_status, rounds_count, removed_all_rounds_count
FROM sys.dm_os_memory_cache_clock_hands;



-- Source: http://blog.sqltechie.com/2011/03/dmvs-for-memory.html

-- This will give us detail for physical memory, available memory , toatl page file and available page file and 
-- high/low memory status. If  memory status is low then it means system is facing memory pressure

SELECT total_physical_memory_kb / ( 1024.0 * 1024 )     total_physical_memory_gb,
       available_physical_memory_kb / ( 1024.0 * 1024 ) available_physical_memory_gb,
       total_page_file_kb / ( 1024.0 * 1024 )           total_page_file_gb,
       available_page_file_kb / ( 1024.0 * 1024 )       available_page_file_gb,
       system_high_memory_signal_state,
       system_low_memory_signal_state,
       system_memory_state_desc
FROM   sys.dm_os_sys_memory 

-- Below dmv is supprted on SQL 2008 and later versions
-- it provides some  more detailed information about memory in sql server
-- All details are in kb 


SELECT physical_memory_in_use_kb,
       large_page_allocations_kb,
       locked_page_allocations_kb,
       total_virtual_address_space_kb,
       virtual_address_space_reserved_kb,
       virtual_address_space_committed_kb,
       virtual_address_space_available_kb,
       page_fault_count,
       memory_utilization_percentage,
       available_commit_limit_kb,
       process_physical_memory_low,
       process_virtual_memory_low
FROM   sys.dm_os_process_memory


select 
    sum(awe_allocated_kb) / 1024 as [AWE allocated, Mb] 
from 
    sys.dm_os_memory_clerks


-- Source: http://mssqlwiki.com/sqlwiki/sql-performance/troubleshooting-sql-server-memory/

-- sys.dm_os_memory_clerks can provide a complete picture of SQL Server memory status 
-- and can be drilled down using sys.dm_os_memory_objects

-- Note:  single_pages_kb is Bpool and  multi_pages_kb is MTL 

-- sys.dm_os_memory_clerks output will also indicate which memory clerk is consuming 
-- majority of memory in MTL. 
-- Use the below query. You can further break down using sys.dm_os_memory_objects 

select  *  from sys.dm_os_memory_clerks order by  multi_pages_kb  desc

select b.type,a.type,* 
from sys.dm_os_memory_objects a,sys.dm_os_memory_clerks b 
where a.page_allocator_address=b.page_allocator_address 
order by  b.multi_pages_kb,a.max_pages_allocated_count


-- If the Problem is with BPOOL 
-- Capture sum of singlePageAllocator for all nodes (Memory node Id = 0,1..n)
-- from DBCC memorystatus output printed immediately after OOM errors in SQL Server errorlog.

-- This will tell us how many KB each memory clerk is using in MTL.

-- sys.dm_os_memory_clerks output will also indicate which memory clerk is consuming majority 
-- of memory in BPOOL (single_pages_kb). 
-- Use the below query. You can further break down using sys.dm_os_memory_objects 

select  *  from sys.dm_os_memory_clerks order by  Single_pages_kb  desc

select b.type,a.type,* from sys.dm_os_memory_objects a,sys.dm_os_memory_clerks b 
where a.page_allocator_address=b.page_allocator_address 
order by  b.single_pages_kb

-- Other views which can help to troubleshoot SQL Server memory issues are

select * from sys.dm_os_memory_objects 
select * from sys.dm_os_memory_pools   
select * from sys.dm_os_memory_nodes 
select * from sys.dm_os_memory_cache_entries 
select * from sys.dm_os_memory_cache_hash_tables

 

-- Few queries which we use to troubleshoot SQL Server memory issues.
 --Bpool statsselect (bpool_committed * 8192)/ (1024*1024) as bpool_committed_mb, 
 -- (cast(bpool_commit_target as bigint) * 8192) / (1024*1024) as bpool_target_mb,
 -- (bpool_visible * 8192) / (1024*1024) as bpool_visible_mbfrom sys.dm_os_sys_infogo  
 -- Get me physical RAM installed-- and size of user VASselect physical_memory_in_bytes/(1024*1024) as phys_mem_mb, virtual_memory_in_bytes/(1024*1024) as user_virtual_address_space_sizefrom sys.dm_os_sys_infogo---- Get me other information about system memory--select total_physical_memory_kb/(1024) as phys_mem_mb,available_physical_memory_kb/(1024) as avail_phys_mem_mb,system_cache_kb/(1024) as sys_cache_mb,(kernel_paged_pool_kb+kernel_nonpaged_pool_kb)/(1024) as kernel_pool_mb,total_page_file_kb/(1024) as total_virtual_memory_mb,available_page_file_kb/(1024) as available_virtual_memory_mb,system_memory_state_descfrom sys.dm_os_sys_memorygo-- Get me memory information about SQLSERVR.EXE process-- GetMemoryProcessInfo() API used for this-- physical_memory_in_use_kbselect physical_memory_in_use_kb/(1024) as sql_physmem_inuse_mb,locked_page_allocations_kb/(1024) as awe_memory_mb,total_virtual_address_space_kb/(1024) as max_vas_mb,virtual_address_space_committed_kb/(1024) as sql_committed_mb,memory_utilization_percentage as working_set_percentage,virtual_address_space_available_kb/(1024) as vas_available_mb,process_physical_memory_low as is_there_external_pressure,process_virtual_memory_low as is_there_vas_pressurefrom sys.dm_os_process_memorygoselect * from sys.dm_os_ring_buffers where ring_buffer_type like 'RING_BUFFER_RESOURCE%'goselect memory_node_id as node, virtual_address_space_reserved_kb/(1024) as VAS_reserved_mb,virtual_address_space_committed_kb/(1024) as virtual_committed_mb,locked_page_allocations_kb/(1024) as locked_pages_mb,single_pages_kb/(1024) as single_pages_mb,multi_pages_kb/(1024) as multi_pages_mb,shared_memory_committed_kb/(1024) as shared_memory_mbfrom sys.dm_os_memory_nodeswhere memory_node_id != 64go  

;with vasummary([Size],reserved,free) as 
( 
select size = vadump.size,
	reserved = SUM(case(convert(int, vadump.base) ^ 0)  when 0 then 0 else 1 end),
	free = SUM(case(convert(int, vadump.base) ^ 0x0) when 0 then 1 else 0 end)
from(select CONVERT(varbinary, sum(region_size_in_bytes)) as size,
region_allocation_base_address as base
from sys.dm_os_virtual_address_dump 
where region_allocation_base_address <> 0x0
group by region_allocation_base_address
UNION
(select CONVERT(varbinary, region_size_in_bytes),region_allocation_base_address
from sys.dm_os_virtual_address_dump where region_allocation_base_address = 0x0))as vadump
group by size)
select * from vasummary
go 

-- Get me all clerks that take some memory
select * from sys.dm_os_memory_clerks
where (single_pages_kb > 0) or (multi_pages_kb > 0)or (virtual_memory_committed_kb > 0)go

-- Get me stolen pages--

select (SUM(single_pages_kb)*1024)/8192 as total_stolen_pages
from sys.dm_os_memory_clerks
go

-- Breakdown clerks with stolen pages

select type, name, sum((single_pages_kb*1024)/8192) as stolen_pages
from sys.dm_os_memory_clerks
where single_pages_kb > 0
group by type, name 
order by stolen_pages desc
go

-- Get me the total amount of memory consumed by multi_page consumers--

select SUM(multi_pages_kb)/1024 as total_multi_pages_mb
from sys.dm_os_memory_clerks 
go

-- What about multi_page consumers--

select type, name, sum(multi_pages_kb)/1024 as multi_pages_mb
from sys.dm_os_memory_clerks
where multi_pages_kb > 0
group by type, name 
order by multi_pages_mb desc
go

-- Let's now get the total consumption of virtual allocator--
select SUM(virtual_memory_committed_kb)/1024 as total_virtual_mem_mb
from sys.dm_os_memory_clerks
go

-- Breakdown the clerks who use virtual allocator--

select type, name, sum(virtual_memory_committed_kb)/1024 as virtual_mem_mb
from sys.dm_os_memory_clerks
where virtual_memory_committed_kb > 0group by type, name
order by virtual_mem_mb desc
go

-- Is anyone using AWE allocator?--
select SUM(awe_allocated_kb)/1024 as total_awe_allocated_mb
from sys.dm_os_memory_clerks
go

-- Who is the AWE user?--
select type, name, sum(awe_allocated_kb)/1024 as awe_allocated_mb
from sys.dm_os_memory_clerks
where awe_allocated_kb > 0
group by type, name
order by awe_allocated_mb desc
go

-- What is the total memory used by the clerks?--

select (sum(multi_pages_kb)+SUM(virtual_memory_committed_kb)+SUM(awe_allocated_kb))/1024
from sys.dm_os_memory_clerks
go

---- Does this sync up with what the node thinks?--

select 
SUM(virtual_address_space_committed_kb)/1024 as total_node_virtual_memory_mb,
SUM(locked_page_allocations_kb)/1024 as total_awe_memory_mb,
SUM(single_pages_kb)/1024 as total_single_pages_mb,
SUM(multi_pages_kb)/1024 as total_multi_pages_mb
from sys.dm_os_memory_nodes
where memory_node_id != 64
go

---- Total memory used by SQL Server through SQLOS memory nodes
-- including DAC node
-- What takes up the rest of the space?

select 
	(SUM(virtual_address_space_committed_kb)+
		SUM(locked_page_allocations_kb)+
		SUM(multi_pages_kb))/1024 as total_sql_memusage_mb
from sys.dm_os_memory_nodes
go

-- Who are the biggest cache stores?

select name, type, (SUM(single_pages_kb)+SUM(multi_pages_kb))/1024 as cache_size_mb
from sys.dm_os_memory_cache_counters 
where type like 'CACHESTORE%'
group by name, type
order by cache_size_mb desc
go

---- Who are the biggest user stores?
select name, type, (SUM(single_pages_kb)+SUM(multi_pages_kb))/1024 as cache_size_mb
from sys.dm_os_memory_cache_counters
where type like 'USERSTORE%'
group by name, type
order by cache_size_mb desc
go

---- Who are the biggest object stores?
select name, type, (SUM(single_pages_kb)+SUM(multi_pages_kb))/1024 as cache_size_mb
from sys.dm_os_memory_clerkswhere type like 'OBJECTSTORE%'
group by name, type
order by cache_size_mb desc
go

select mc.type, mo.type 
from sys.dm_os_memory_clerks mc
	join sys.dm_os_memory_objects moon mc.page_allocator_address = mo.page_allocator_address
group by mc.type, mo.type
order by mc.type, mo.typego
