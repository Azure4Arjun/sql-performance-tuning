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

-- And a table
CREATE TABLE [TestTable] (
	[c1]	INT IDENTITY,
	[c2]	CHAR (1000) DEFAULT 'a');

CREATE CLUSTERED INDEX [TT_CL]
ON [TestTable] ([c1]);
GO

-- Insert 7000 records
SET NOCOUNT ON;
GO

INSERT INTO [TestTable] DEFAULT VALUES;
GO 7000

-- Clear the log
CHECKPOINT;
GO

-- Go into the BULK_LOGGED recovery model
ALTER DATABASE [DBTranLog] SET RECOVERY BULK_LOGGED;
GO

BACKUP DATABASE [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog.bck'
WITH INIT;
GO

-- Rebuild the clustered index
ALTER INDEX [TT_CL] ON [TestTable] REBUILD;
GO

-- Examine the log
SELECT * FROM fn_dblog (NULL, NULL);
GO

-- Now switch to FULL and clear the log
ALTER DATABASE [DBTranLog] SET RECOVERY FULL;
GO

BACKUP LOG [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog_log.bck'
WITH INIT;
GO

-- Rebuild the clustered index again
ALTER INDEX [TT_CL] ON [TestTable] REBUILD;
GO

-- Examine the log
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
