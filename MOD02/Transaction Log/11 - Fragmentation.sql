/*

	Training:	Optimizing and Troubleshooting
	Module:		02 - Transaction Log
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/
USE [master];
GO

IF DATABASEPROPERTYEX (N'DBTranLog', N'Version') > 0
BEGIN
	ALTER DATABASE [DBTranLog] SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [DBTranLog];
END
GO

-- Create the database to use
CREATE DATABASE [DBTranLog] ON PRIMARY (
    NAME = N'DBTranLog_data',
    FILENAME = N'c:\sql\DBTranLog_data.mdf')
LOG ON (
    NAME = N'DBTranLog_log',
    FILENAME = N'c:\sql\DBTranLog_log.ldf',
    SIZE = 512KB,
    FILEGROWTH = 1MB);
GO

USE [DBTranLog];
GO

-- Create a table that will grow very
-- quickly and generate lots of transaction
-- log
CREATE TABLE [BigRows] (
	[c1] INT IDENTITY,
	[c2] CHAR (8000) DEFAULT 'a');
GO

-- Make sure the database is in FULL
-- recovery model
ALTER DATABASE [DBTranLog] SET RECOVERY FULL;
GO

BACKUP DATABASE [DBTranLog] TO
	DISK = N'c:\sql\DBTranLog.bck'
	WITH INIT, STATS;
GO

-- Cause a bunch of log growth
SET NOCOUNT ON;
GO
INSERT INTO [BigRows] DEFAULT VALUES;
GO 150

-- This will take a while...

-- How many VLFs do we have?
DBCC LOGINFO (N'DBTranLog');
GO
CHECKPOINT
-- Shrink the log
DBCC SHRINKFILE (2);
GO

-- Backup the log to allow log clearing
BACKUP LOG [DBTranLog] TO
	DISK = N'c:\sql\DBTranLog_log.bck'
	WITH STATS;
GO

-- Shrink the log again.. does it go down?
-- If not, do another backup and re-shrink
DBCC SHRINKFILE (2);
GO

-- Now grow it manually and set auto growth
ALTER DATABASE [DBTranLog]
	MODIFY FILE (
		NAME = N'DBTranLog_Log',
		SIZE = 300MB,
		FILEGROWTH = 20MB);
GO

-- And check VLFs again
DBCC LOGINFO (N'DBTranLog');
GO

USE [master];
GO

IF DATABASEPROPERTYEX (N'DBTranLog', N'Version') > 0
BEGIN
	ALTER DATABASE [DBTranLog] SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [DBTranLog];
END
GO
