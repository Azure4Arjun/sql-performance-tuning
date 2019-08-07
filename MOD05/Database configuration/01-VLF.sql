-- DEMO: reading the log

-- DBCC LOG takes a dbid as a parameter

DBCC LOG(1)

-- The function fn_dblog works in the current database

SELECT * FROM fn_dblog(null, null)

-- As a table-valued function, you can select specific columns from the fn_dblog results, qualify the rows to be returned
--   or aggregate the results

-- what's taking up log space?

SELECT  Operation, 
  Context,
  [Log Size] = sum([Log Record Length])
FROM  fn_dblog(null, null)
GROUP BY Operation, Context

--Long-Running Active Transactions

USE pubs
GO
BEGIN TRAN
UPDATE dbo.authors
SET city=UPPER(city)

DBCC OPENTRAN

SELECT * 
FROM sys.dm_exec_sessions
WHERE session_id = 52

SELECT r.session_id, r.blocking_session_id, s.program_name, s.host_name, t.text 
FROM sys.dm_exec_requests r INNER JOIN sys.dm_exec_sessions s 
	ON r.session_id = s.session_id     
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t 
WHERE s.is_user_process = 1 
AND r.session_id = 52

--KILL 51

ROLLBACK TRAN

USE master
GO
IF DB_ID('VLF') IS NOT NULL drop database VLF;
GO

CREATE DATABASE VLF
GO
BACKUP DATABASE VLF TO DISK = 'c:\sql\VLF.bak' 
WITH INIT;

USE VLF
GO
EXEC SP_HELPDB VLF
DBCC LOGINFO
GO
CREATE TABLE [dbo].[t1](
     [SalesOrderID] [int]  ,
     [SalesOrderDetailID] [int]  ,
     [CarrierTrackingNumber] [nvarchar](25) DEFAULT 'p12-X' ,
     [OrderQty] [smallint]   DEFAULT 12,
     [ProductID] [int]   DEFAULT 1,
     [SpecialOfferID] [int]  NULL,
     [UnitPrice] [money]  DEFAULT 1121,
     [UnitPriceDiscount] [money]  NULL,
     [LineTotal] [numeric](38, 6)  NULL,
     [rowguid] [uniqueidentifier]  NULL,
     [ModifiedDate] [datetime]  DEFAULT GETDATE()
) ON [PRIMARY]
GO


DBCC TRACEON (3502,-1) --Checkpoints will be written to log


--PERF MON
DECLARE @Start     datetime, 
		 @Time     int
SET @Start = GETDATE()
INSERT INTO t1
SELECT *
FROM AdventureWorks.Sales.SalesOrderDetail
SET  @Time = DATEDIFF (ms, @Start, GETDATE()) 
SELECT @Time as 'Czas'
GO
DBCC LOGINFO
GO
BEGIN TRAN
WHILE 1=1
     INSERT INTO t1 DEFAULT VALUES
COMMIT TRAN
DBCC LOGINFO
EXEC SP_HELPFILE
GO
BACKUP LOG VLF TO DISK = 'c:\sql\VLFlog.bak' WITH INIT 
DBCC SHRINKFILE (VLF_log, TRUNCATEONLY)
GO
-- jesze raz
BACKUP LOG VLF TO DISK = 'c:\sql\VLFlog.bak'
DBCC SHRINKFILE (VLF_log)
DBCC LOGINFO
EXEC SP_HELPFILE
GO
ALTER DATABASE VLF
MODIFY FILE 
          ( NAME = VLF_log ,
          SIZE = 200,
          FILEGROWTH =20)
GO
EXEC SP_HELPFILE
DBCC LOGINFO
GO
TRUNCATE TABLE T1
GO
--compare times
DECLARE @Start     datetime, 
          @Time     int
SET @Start = getdate()
INSERT INTO t1
SELECT *
FROM AdventureWorks.Sales.SalesOrderDetail
SET  @Time = datediff (ms, @Start, getdate()) 
SELECT @Time as 'Czas'
GO


DBCC TRACEOFF (3502,-1)