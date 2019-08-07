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


-- Create a database
CREATE DATABASE [DBTranLog] ON PRIMARY (
    NAME = N'DBTranLog_data',
    FILENAME = N'c:\sql\DBTranLog_data.mdf')
LOG ON (
    NAME = N'DBTranLog_log',
    FILENAME = N'c:\sql\DBTranLog_log.ldf',
    SIZE = 10MB,
    FILEGROWTH = 10MB);
GO

-- Examine the size of the log
DBCC SQLPERF (LOGSPACE);
GO

-- Examine the VLF structure of the log
DBCC LOGINFO (N'DBTranLog');
GO

-- Increase the log file size
ALTER DATABASE [DBTranLog] MODIFY FILE (
    NAME = N'DBTranLog_log',
    SIZE = 20MB);
GO

-- Examine the size of the log
DBCC SQLPERF (LOGSPACE);
GO

-- Examine the VLF structure of the log
DBCC LOGINFO (N'DBTranLog');
GO


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
