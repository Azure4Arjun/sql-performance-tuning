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

CREATE DATABASE [DBTranLog];
GO

USE [DBTranLog];
GO
SET NOCOUNT ON;
GO

-- Make sure the database is in SIMPLE
-- recovery model with no auto-stats (to avoid
-- unwanted log records)
ALTER DATABASE [DBTranLog] SET RECOVERY SIMPLE;
ALTER DATABASE [DBTranLog] SET AUTO_CREATE_STATISTICS OFF;
GO

-- Create a simple table with some records
CREATE TABLE [test] ([c1] INT, [c2] INT, [c3] INT);
CREATE CLUSTERED INDEX [test_cl] ON [test] ([c1]);

INSERT INTO [test] VALUES (1, 1, 1);
INSERT INTO [test] VALUES (2, 2, 2);
INSERT INTO [test] VALUES (3, 3, 3);
INSERT INTO [test] VALUES (4, 4, 4);
GO

-- Now delete a row, trigger ghost cleanup, and
-- wait for five seconds for other housekeeping
-- to generate log records we don't care about
DELETE FROM [test] WHERE [c1] = 3;
GO

SELECT * FROM [test] WHERE [c1] = 0;
GO

WAITFOR DELAY '00:00:05';
GO

-- Clear out the log 
CHECKPOINT;
GO

-- Now delete a record
DELETE FROM [test] WHERE [c1] = 4;
GO

SELECT * FROM fn_dblog (NULL, NULL);
GO

-- We may see the ghost cleanup task...
SELECT * FROM fn_dblog (NULL, NULL);
GO

-- Or we may need to trigger it...
SELECT * FROM [test];
GO

SELECT * FROM fn_dblog (NULL, NULL);
GO