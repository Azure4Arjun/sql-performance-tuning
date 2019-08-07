DROP DATABASE SQLOS_SCHEDULING
GO

CREATE DATABASE SQLOS_SCHEDULING
GO

USE SQLOS_SCHEDULING
GO

CREATE TABLE tEmployee(intRoll int, strName varchar(50))
GO

SET NOCOUNT ON
INSERT INTO tEmployee VALUES(1001,'AAAA')
GO 10000

-- Get  SPID of this session. To be used later.
SELECT @@SPID

-- Run below *poor* query (parallelism is forced with 8649 traceflag). 
SELECT * FROM tEmployee A 
CROSS JOIN tEmployee B  
OPTION (RECOMPILE, QUERYTRACEON 8649)

-- Open new session and run below queries one by one
-- Query 1: User Connection and Query as Request. 

SELECT 
 REQ.connection_id,
 REQ.database_id,
 REQ.session_id,
 REQ.command,
 REQ.request_id,
 REQ.start_time,
 REQ.task_address,
 QUERY.text
FROM SYS.dm_exec_requests req
Cross apply sys.dm_exec_sql_text (req.sql_handle) as query
WHERE req.session_id = 53 

-- Query 2: User quey is divided as X Tasks (Parallelism forced)

SELECT 
 task.task_address,
 task.parent_task_address,
 task.task_state,
 REQ.request_id,
 REQ.database_id,
 REQ.session_id,
 REQ.start_time,
 REQ.command,
 REQ.connection_id,
 REQ.task_address,
 QUERY.text
FROM SYS.dm_exec_requests req
INNER JOIN sys.dm_os_tasks task 
	ON req.task_address = task.task_address or req.task_address = task.parent_task_address
CROSS APPLY sys.dm_exec_sql_text (req.sql_handle) AS query
WHERE req.session_id = 52

-- Query 3: Each task is assigned to worker

SELECT 
 worker.worker_address,
 worker.last_wait_type,
 worker.state,
 task.task_address,
 task.parent_task_address,
 task.task_state,
 REQ.request_id,
 REQ.database_id,
 REQ.session_id,
 REQ.start_time,
 REQ.command,
 REQ.connection_id,
 REQ.task_address,
 QUERY.text
FROM SYS.dm_exec_requests req
INNER JOIN sys.dm_os_tasks task 
	ON req.task_address = task.task_address or req.task_address = task.parent_task_address
INNER JOIN SYS.dm_os_workers WORKER 
	ON TASK.task_address = WORKER.task_address
CROSS APPLY sys.dm_exec_sql_text (req.sql_handle) as query
WHERE req.session_id = 52

-- Query 4: User request as Tasks. Task assigned to worker. Each worker is associated with a thread

-- User Query as Request becomes Task(s)
-- Task is given to available Worker
-- Threads associated with Workers

SELECT 
 thread.thread_address,
 thread.priority,
 thread.processor_group,
 thread.started_by_sqlservr,
 worker.worker_address,
 worker.last_wait_type,
 worker.state,
 task.task_address,
 task.parent_task_address,
 task.task_state,
 REQ.request_id,
 REQ.database_id,
 REQ.session_id,
 REQ.start_time,
 REQ.command,
 REQ.connection_id,
 REQ.task_address,
 QUERY.text
FROM SYS.dm_exec_requests req
INNER JOIN sys.dm_os_tasks task 
	ON req.task_address = task.task_address or req.task_address = task.parent_task_address
INNER JOIN SYS.dm_os_workers WORKER 
	ON TASK.task_address = WORKER.task_address
INNER JOIN sys.dm_os_threads thread 
	ON worker.thread_address = thread.thread_address
CROSS APPLY sys.dm_exec_sql_text (req.sql_handle) as query
WHERE req.session_id = 53


-- Query 5: CPU time is scheduled for task by Scheduler

-- User Query as Request becomes Task(s)
-- Task is given to available Worker
-- Threads associated with Workers
-- Schedulers associated with CPU schedules CPU time for Workers
SELECT 
 sch.scheduler_address,
 sch.runnable_tasks_count,
 sch.cpu_id,
 sch.status,
 thread.thread_address,
 thread.priority,
 thread.processor_group,
 thread.started_by_sqlservr,
 worker.worker_address,
 worker.last_wait_type,
 worker.state,
 task.task_address,
 task.parent_task_address,
 task.task_state,
 REQ.request_id,
 REQ.database_id,
 REQ.session_id,
 REQ.start_time,
 REQ.command,
 REQ.connection_id,
 REQ.task_address,
 QUERY.text
FROM SYS.dm_exec_requests req
INNER JOIN sys.dm_os_tasks task 
	ON req.task_address = task.task_address or req.task_address = task.parent_task_address
INNER JOIN SYS.dm_os_workers WORKER 
	ON TASK.task_address = WORKER.task_address
INNER JOIN sys.dm_os_threads thread 
	ON worker.thread_address = thread.thread_address
INNER JOIN sys.dm_os_schedulers sch 
	ON sch.scheduler_address = worker.scheduler_address
CROSS APPLY sys.dm_exec_sql_text (req.sql_handle) as query
WHERE req.session_id = 53

