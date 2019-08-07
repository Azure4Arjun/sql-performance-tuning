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

IF DATABASEPROPERTYEX (N'CheckpointTest', N'Version') > 0
BEGIN
	ALTER DATABASE [CheckpointTest] SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [CheckpointTest];
END
GO

CREATE DATABASE [CheckpointTest] ON PRIMARY (
    NAME = N'CheckpointTest_data',
    FILENAME = N'c:\sql\CheckpointTest_data.mdf')
LOG ON (
    NAME = N'CheckpointTest_log',
    FILENAME = N'c:\sql\CheckpointTest_log.ldf',
    SIZE = 250MB,
    FILEGROWTH = 20MB);
GO

USE [CheckpointTest];
GO

-- Create a table that will grow very
-- quickly and generate lots of transaction
-- log
CREATE TABLE [BigRows] (
	[c1] INT IDENTITY,
	[c2] CHAR (8000) DEFAULT 'a');
GO

-- Make sure the database is in SIMPLE
-- recovery model
ALTER DATABASE [CheckpointTest] SET RECOVERY SIMPLE;
GO

-- Startup perfmon with checkpoint pages/sec

-- Run the large insert in the second window...

-- Trace CHECKPOINT execution
DBCC TRACEON (3605, -1);
DBCC TRACEON (3502, -1);
GO
EXEC sp_cycle_errorlog;
GO

-- Exec 06b
-- Look at errorlog at background task...
EXEC xp_readerrorlog;
GO

-- Only shows start and end. What about details?
DBCC TRACEON (3504, -1);
GO

EXEC xp_readerrorlog;
GO

-- Clear up
DBCC TRACEOFF (3605, -1);
DBCC TRACEOFF (3502, -1);
DBCC TRACEOFF (3504, -1);
GO

USE [master];
GO

IF DATABASEPROPERTYEX (N'CheckpointTest', N'Version') > 0
BEGIN
	ALTER DATABASE [CheckpointTest] SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [CheckpointTest];
END
GO