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

-- Create a database to use
CREATE DATABASE [DBTranLog];
GO

USE [DBTranLog];
GO

-- Create a small table
CREATE TABLE [TestTable] (
	[c1]	INT IDENTITY,
	[c2]	CHAR (1000) DEFAULT 'a');

CREATE CLUSTERED INDEX [TT_CL]
ON [TestTable] ([c1]);
GO

-- Insert 70 records in a transaction
SET NOCOUNT ON;
GO

BEGIN TRANSACTION;
GO

INSERT INTO [TestTable] DEFAULT VALUES;
GO 70

-- Force the data pages and log records to disk
CHECKPOINT;
GO

-- In another window, shutdown SQL Server

-- Then restart SQL Server

-- Make sure crash recovery has completed
EXEC xp_readerrorlog;
GO

-- Look at the log generated
USE [DBTranLog];
GO

SELECT * FROM fn_dblog (NULL, NULL);
GO

-- If recovery finished, it will have
-- checkpointed, so allow the log reader
-- to go further back in the log
DBCC TRACEON (2537);
GO

SELECT * FROM fn_dblog (NULL, NULL);
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
