USE AdventureWorks2008R2
GO
IF EXISTS (SELECT 1 FROM sys.sysusers WHERE name ='Test')
	 DROP USER Test 
GO

CREATE USER Test WITHOUT LOGIN;
GRANT SELECT ON [dbo].[ErrorLog] TO Test;
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name ='uspExecutionContext')
	 DROP PROCEDURE uspExecutionContext
GO

CREATE PROC uspExecutionContext
AS
SELECT name, type 
FROM sys.user_token;
GO

GRANT EXECUTE ON uspExecutionContext TO Test;
GO

DECLARE @ID INT;
SET @ID = DB_ID(); 
DBCC FLUSHPROCINDB  (@ID);
GO

EXECUTE uspExecutionContext;
GO

EXECUTE AS USER = 'Test';
EXECUTE uspExecutionContext;
REVERT;
GO

SELECT execution_count ,plan_handle
FROM sys.dm_exec_query_stats
CROSS APPLY sys.dm_exec_sql_text (plan_handle)
WHERE text LIKE '%uspExecutionContext%'
AND text NOT LIKE '%dm%';
GO

SELECT *
FROM SYS.dm_exec_plan_attributes (0x05000C00C3B00B19B0E958F70400000001000000000000000000000000000000000000000000000000000000);

ALTER USER Test
WITH DEFAULT_SCHEMA = HumanResources;
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name ='uspErrorLog')
	 DROP PROCEDURE uspErrorLog
GO
CREATE PROCEDURE uspErrorLog AS
SELECT UserName,ErrorMessage, ErrorTime
FROM ErrorLog;
GO
GRANT CONTROL ON uspErrorLog TO Test;
GO

EXECUTE uspErrorLog;
GO
EXECUTE AS USER = 'Test';
EXECUTE uspErrorLog;
REVERT;



EXECUTE AS USER = 'Test';
GO

ALTER PROCEDURE uspErrorLog 
WITH EXECUTE AS self
AS
SELECT UserName,ErrorMessage, ErrorTime
FROM dbo.ErrorLog;
GO

REVERT
GO

EXECUTE uspErrorLog;
GO
EXECUTE AS USER = 'Test';
EXECUTE uspErrorLog;
REVERT;
GO


EXECUTE AS USER = 'Test';
GO

ALTER PROCEDURE uspErrorLog 
WITH EXECUTE AS owner
AS
SELECT UserName,ErrorMessage, ErrorTime
FROM dbo.ErrorLog;
GO

REVERT
GO
