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
    FILENAME = N'C:\DB\DBTranLog_data.mdf')
LOG ON (
    NAME = N'DBTranLog_log',
    FILENAME = N'C:\DB\DBTranLog_log.ldf',
    SIZE = 20GB,
    FILEGROWTH = 256MB);
GO

-- This will take a few minutes...

-- Examine VLFs
DBCC LOGINFO (N'DBTranLog'); 
GO 

-- Better method is to do it in stages

-- Drop and recreate with 8GB log
IF DATABASEPROPERTYEX (N'DBTranLog', N'Version') > 0
BEGIN
	ALTER DATABASE [DBTranLog] SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [DBTranLog];
END
GO

CREATE DATABASE [DBTranLog] ON PRIMARY (
    NAME = N'DBTranLog_data',
    FILENAME = N'c:\sql\DBTranLog_data.mdf')
LOG ON (
    NAME = N'DBTranLog_log',
    FILENAME = N'c:\sql\DBTranLog_log.ldf',
    SIZE = 8GB,
    FILEGROWTH = 256MB);
GO

-- This will take about a minute...

-- Examine VLFs
DBCC LOGINFO (N'DBTranLog'); 
GO

-- Now grow it 3 times in 8GB steps
ALTER DATABASE [DBTranLog]
MODIFY FILE ( 
    NAME = N'DBTranLog_log', 
    SIZE = 16GB);

ALTER DATABASE [DBTranLog]
MODIFY FILE ( 
    NAME = N'DBTranLog_log', 
    SIZE = 24GB);

ALTER DATABASE [DBTranLog]
MODIFY FILE ( 
    NAME = N'DBTranLog_log', 
    SIZE = 32GB);
GO

-- This will take a few minutes...

-- Examine VLFs
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
