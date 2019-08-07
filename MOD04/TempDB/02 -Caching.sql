/*

	Training:	Optimizing and Troubleshooting
	Module:		05 - SQL Server Configuration
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/
USE [master];
GO

IF DATABASEPROPERTYEX (N'DBTestTempDB', N'Version') > 0
BEGIN
	ALTER DATABASE [DBTestTempDB] SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [DBTestTempDB];
END
GO

CREATE DATABASE [DBTestTempDB];
GO

USE DBTestTempDB;
GO

CREATE PROC TestTableCaching
AS
CREATE TABLE #Tab (col1 INT IDENTITY PRIMARY KEY, col2 UNIQUEIDENTIFIER DEFAULT NEWID());
INSERT INTO #Tab DEFAULT VALUES;
GO

DBCC FREEPROCCACHE
GO

DECLARE @Before BIGINT;
SELECT @Before = cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Temp Tables Creation Rate';

DECLARE @i INT;
SET @i=0;
WHILE @i<15
BEGIN
	EXEC TestTableCaching;
	SET @i=@i+1;
END

DECLARE @After BIGINT;
SELECT @After = cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Temp Tables Creation Rate';

SELECT @After - @Before AS 'Temp Tables Created'
GO
