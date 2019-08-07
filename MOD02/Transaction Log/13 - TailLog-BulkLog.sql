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

-- Create the database
CREATE DATABASE [DBTranLog];
GO

USE [DBTranLog];
GO

ALTER DATABASE [DBTranLog]
	SET RECOVERY FULL;
GO

-- Create a table
CREATE TABLE [TestTable] (
	[c1] INT IDENTITY,
	[c2] VARCHAR (100));
GO
CREATE CLUSTERED INDEX [TestTable_CL]
	ON [TestTable] ([c1]);
GO

INSERT INTO [TestTable]
	VALUES ('Initial data: transaction 1');
GO

-- And take a full backup
BACKUP DATABASE [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog.bck'
WITH INIT;
GO

-- Now add some more data
SET NOCOUNT ON;
GO
INSERT INTO [TestTable]
	VALUES ('More data...');
GO 1000

BACKUP LOG [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog_DB1.bck'
WITH INIT;
GO

-- Minimally-DBged operation
ALTER DATABASE [DBTranLog]
	SET RECOVERY BULK_LOGGED;
GO

ALTER INDEX [TestTable_CL] ON [TestTable] REBUILD;
GO

ALTER DATABASE [DBTranLog]
	SET RECOVERY FULL;
GO

-- And some more user transactions
INSERT INTO [TestTable]
	VALUES ('Transaction 2');
GO
INSERT INTO [TestTable]
	VALUES ('Transaction 3');
GO

-- Simulate a crash
SHUTDOWN WITH NOWAIT;
GO

-- Delete the data file and restart SQL

USE [DBTranLog];
GO

-- The backup doesn't have the most recent
-- transactions - if we restore it we'll
-- lose them.

-- Take a DB backup!
BACKUP LOG [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog_tail.bck'
WITH INIT, NO_TRUNCATE;
GO

-- Hmm - marked as corrupt!

-- Now restore
RESTORE DATABASE [DBTranLog] FROM
	DISK = 'c:\sql\DBTranLog.bck'
WITH REPLACE, NORECOVERY;
GO

RESTORE LOG [DBTranLog] FROM
	DISK = 'c:\sql\DBTranLog_DB1.bck'
WITH REPLACE, NORECOVERY;
GO

RESTORE LOG [DBTranLog] FROM
	DISK = 'c:\sql\DBTranLog_tail.bck'
WITH REPLACE;
GO

-- Force it with CONTINUE_AFTER_ERROR
RESTORE LOG [DBTranLog] FROM
	DISK = 'c:\sql\DBTranLog_tail.bck'
WITH REPLACE, CONTINUE_AFTER_ERROR;
GO

-- Hmm - doesn't look good.

-- Is everything there?
SELECT * FROM [DBTranLog].[dbo].[TestTable];
GO

-- Woah!
DBCC CHECKDB (N'DBTranLog') WITH NO_INFOMSGS;
GO

-- The tail-of-the-DB backup is essentially corrupt because
-- it couldn't back up the data file pages

-- Re-restore without the tail-of-the-DB
RESTORE DATABASE [DBTranLog] FROM
	DISK = 'c:\sql\DBTranLog.bck'
WITH REPLACE, NORECOVERY;
GO

RESTORE LOG [DBTranLog] FROM
	DISK = 'c:\sql\DBTranLog_DB1.bck'
WITH REPLACE;
GO

-- Is everything there?
SELECT * FROM [DBTranLog].[dbo].[TestTable];
GO

-- Nope - lost transaction 2 and 3
