USE [master];
GO

IF DATABASEPROPERTYEX (N'DBMaint2012', N'Version') > 0
BEGIN
	ALTER DATABASE [DBMaint2012] SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [DBMaint2012];
END
GO

CREATE DATABASE [DBMaint2012];
GO

USE [DBMaint2012];
GO
SET NOCOUNT ON;
GO

-- Make sure the database is in SIMPLE
-- recovery model with no auto-stats (to avoid
-- unwanted log records)
ALTER DATABASE [DBMaint2012] SET RECOVERY SIMPLE;
ALTER DATABASE [DBMaint2012] SET AUTO_CREATE_STATISTICS OFF;
GO

-- Create a simple table with a clustered index
CREATE TABLE [test] ([c1] INT, [c2] CHAR (1000));
CREATE CLUSTERED INDEX [test_cl] ON [test] ([c1]);
GO

-- Insert records for page 1
INSERT INTO [test] VALUES (1, 'a');
INSERT INTO [test] VALUES (2, 'b');
INSERT INTO [test] VALUES (3, 'c');
INSERT INTO [test] VALUES (5, 'e');
INSERT INTO [test] VALUES (6, 'f');
INSERT INTO [test] VALUES (7, 'g');
INSERT INTO [test] VALUES (8, 'h');
GO

-- Insert records for page 2
INSERT INTO [test] VALUES (9, 'i');
INSERT INTO [test] VALUES (10, 'j');
GO

-- Clear out the log (more on this in Module 5)
CHECKPOINT;
GO

-- Insert a record that will split page 1
INSERT INTO [test] VALUES (4, 'd');
GO

-- Look in the log
SELECT * FROM fn_dblog (NULL, NULL);
GO