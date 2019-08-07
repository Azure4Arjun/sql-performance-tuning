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

-- Create a table and insert 8MB
CREATE TABLE [BigTable] (
	[c1] INT IDENTITY,
	[c2] CHAR (8000) DEFAULT 'a');
GO
CREATE CLUSTERED INDEX [BigTable_CL] 
	ON [BigTable] ([c1]);
GO

SET NOCOUNT ON;
GO

INSERT INTO [BigTable] DEFAULT VALUES;
GO 1000

-- Put the database into the FULL recovery
-- model and clear out the log.
ALTER DATABASE [DBTranLog] SET RECOVERY FULL;
GO

BACKUP DATABASE [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog_Full_0.bak'
	WITH INIT, STATS;
GO

BACKUP LOG [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog_Log_0_Initial.bak'
	WITH INIT, STATS;
GO

-- Now rebuild the clustered index to
-- generate a bunch of log
ALTER INDEX [BigTable_CL] ON [BigTable] REBUILD;
GO

-- Backup the log to get a baseline size
BACKUP LOG [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog_Log_1_Baseline.bak'
	WITH INIT, STATS;
GO

-- Test 1
-- Now rebuilds the clustered index again
-- to generate more log
ALTER INDEX [BigTable_CL] ON [BigTable] REBUILD;
GO

-- Now try a full backup and see if it clears
-- the log
BACKUP DATABASE [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog_Full_1.bak'
	WITH INIT, STATS;
GO

-- If it did, this next log backup should be
-- very small
BACKUP LOG [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog_Log_2_FullTest.bak'
	WITH INIT, STATS;
GO

-- Test 2
-- Now rebuild the clustered index again
-- to generate more log
ALTER INDEX [BigTable_CL] ON [BigTable] REBUILD;
GO

-- Now try a checkpoint and see if it clears
-- the log
CHECKPOINT;
GO

-- If it did, this next log backup should be
-- very small
BACKUP LOG [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog_Log_3_CheckTest.bak'
	WITH INIT, STATS;
GO

-- Test 3
-- Now the case where there's a long-running
-- transaction and the log can't be cleared
-- by the backup. When does it get cleared?

-- In the other window, do a long-running
-- transaction...

-- In the other window, try a log backup

-- How much log is being used?
DBCC SQLPERF (LOGSPACE);
GO

-- Now let's take a log backup
BACKUP LOG [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog_Log_4_LongTest.bak'
	WITH INIT, STATS;
GO

-- How big is it?

-- Did the percentage used go down?
DBCC SQLPERF (LOGSPACE);
GO

-- Now commit the transaction...

-- Did the percentage used go down?
DBCC SQLPERF (LOGSPACE);
GO

-- Yes, why? Log space reservation.

-- How about a checkpoint?
CHECKPOINT;
GO
DBCC SQLPERF (LOGSPACE);
GO

-- How about a full backup?
BACKUP DATABASE [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog_Full_2.bak'
	WITH INIT, STATS;
GO
DBCC SQLPERF (LOGSPACE);
GO

-- How about a log backup?
BACKUP LOG [DBTranLog] TO
	DISK = 'c:\sql\DBTranLog_Log_5_LongTest2.bak'
	WITH INIT, STATS;
GO
DBCC SQLPERF (LOGSPACE);
GO
