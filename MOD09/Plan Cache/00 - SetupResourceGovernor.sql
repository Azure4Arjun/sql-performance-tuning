
USE master;
GO

--ALTER SERVER CONFIGURATION SET PROCESS AFFINITY CPU = 0
--GO

EXEC sp_configure 'show advanced options',1
RECONFIGURE
EXEC sp_configure 'affinity mask',1
RECONFIGURE

-- Examine the current configuration
SELECT * FROM sys.dm_resource_governor_configuration;
GO


--Define two resource pools, one with 10% CPU max, and the other with 90%
CREATE RESOURCE POOL MarketingPool
WITH (MAX_CPU_PERCENT = 10);
GO

CREATE RESOURCE POOL DevelopmentPool
WITH (MAX_CPU_PERCENT = 90);
GO

-- Look at our configuration
SELECT * FROM sys.dm_resource_governor_resource_pools;
GO

-- Need to reconfigure
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO
SELECT * FROM sys.dm_resource_governor_resource_pools;
GO

-- Add two workload groups
CREATE WORKLOAD GROUP MarketingGroup
USING MarketingPool;
GO

CREATE WORKLOAD GROUP DevelopmentGroup
USING DevelopmentPool;
GO

-- Look at our configuration
SELECT * FROM sys.dm_resource_governor_workload_groups;
GO

-- Need to reconfigure again
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO
SELECT * FROM sys.dm_resource_governor_workload_groups;
GO

-- Create some dummy databases. The classifier function will
-- use the database name in the connection string to decide
-- which group to put the connection in.
IF DB_ID ('MarketingDB') IS NULL CREATE DATABASE MarketingDB;
GO
IF DB_ID ('DevelopmentDB') IS NULL CREATE DATABASE DevelopmentDB;
GO

-- Define a classifier function
IF OBJECT_ID ('dbo.MyClassifier') IS NOT NULL
	DROP FUNCTION dbo.MyClassifier;
GO

CREATE FUNCTION dbo.MyClassifier ()
RETURNS SYSNAME WITH SCHEMABINDING
AS
BEGIN
	DECLARE @GroupName SYSNAME;
	IF ORIGINAL_DB_NAME () = 'MarketingDB'
		SET @GroupName = 'MarketingGroup';
	ELSE IF  ORIGINAL_DB_NAME () = 'DevelopmentDB'
		SET @GroupName = 'DevelopmentGroup';
	ELSE SET @GroupName = 'Default';
	RETURN @GroupName;
END;
GO

-- Register it
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = dbo.MyClassifier);
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

-- Look at our configuration again
SELECT * FROM sys.dm_resource_governor_configuration;
GO

-- Now open System Monitor, Action | New Window From Here.
-- Add the SQL Resource Pools counters for Marketing and Development

-- Go to Demos
-- sqlcmd /E /S. /d<dbname> /iRunQueries.sql
-- Do marketing first and then development

--ALTER SERVER CONFIGURATION SET PROCESS AFFINITY CPU = AUTO
--GO


EXEC sp_configure 'affinity mask',0
RECONFIGURE
EXEC sp_configure 'show advanced options',0
RECONFIGURE