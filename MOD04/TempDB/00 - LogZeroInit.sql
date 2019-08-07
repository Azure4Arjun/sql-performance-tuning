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

-- Enable trace flags to watch zero-initialization
DBCC TRACEON (3605, 3004, -1);
GO

-- Flush the error log
EXEC sp_cycle_errorlog;
GO

-- Create a database
CREATE DATABASE [DBTranLog] ON PRIMARY (
    NAME = N'DBTranLog_data',
    FILENAME = N'c:\SQL\DBTranLog_data.mdf')
LOG ON (
    NAME = N'DBTranLog_log',
    FILENAME = N'c:\SQL\DBTranLog_log.ldf',
    SIZE = 10MB,
    FILEGROWTH = 10MB);
GO

-- Examine the errorlog
EXEC xp_readerrorlog;
GO

-- Drop the database again
DROP DATABASE [DBTranLog];
GO

-- Turn off the traceflags
DBCC TRACEOFF (3605, 3004, -1);
GO

-- In the other window, flush wait stats

-- Recreate the database
CREATE DATABASE [DBTranLog] ON PRIMARY (
    NAME = N'DBTranLog_data',
    FILENAME = N'c:\SQL\DBTranLog_data.mdf')
LOG ON (
    NAME = N'DBTranLog_log',
    FILENAME = N'c:\SQL\DBTranLog_log.ldf',
    SIZE = 10MB,
    FILEGROWTH = 10MB);
GO

-- Examine waits in the other window

-- Clear
USE [master];
GO

IF DATABASEPROPERTYEX (N'DBTranLog', N'Version') > 0
BEGIN
	ALTER DATABASE [DBTranLog] SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [DBTranLog];
END
GO