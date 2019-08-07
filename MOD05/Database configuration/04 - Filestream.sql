/*

	Training:	Optimizing and Troubleshooting
	Module:		06 - Database Configuration
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/

USE [master];
GO

IF DATABASEPROPERTYEX (N'FileStreamTestDB', N'Version') > 0
BEGIN
	ALTER DATABASE FileStreamTestDB SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE FileStreamTestDB;
END
GO

-- Setup FILESTREAM at the OS level
-- (this has already been done)

-- Setup FILESTREAM at the instance level
EXEC sys.sp_configure N'filestream access level', N'2'
GO
RECONFIGURE WITH OVERRIDE
GO

-- Create a database. Note the FILESTREAM filegroup
CREATE DATABASE FileStreamTestDB ON PRIMARY
  ( NAME = FileStreamTestDB_data,
    FILENAME = N'C:\sql\FSTestDB_data.mdf'),
FILEGROUP FileStreamFileGroup CONTAINS FILESTREAM
  ( NAME = FileStreamTestDBDocuments,
    FILENAME = N'C:\sql\Documents')
LOG ON 
  ( NAME = 'FileStreamTestDB_log', 
    FILENAME = N'C:\sql\FSTestDB_log.ldf');
GO
  
-- Look in the C:\DB\Documents directory at what's been created
-- $FSLOG - FILESTREAM log
-- filestream.hdr - FILESTREAM system file

-- Create two tables with FILESTREAM columns
USE FileStreamTestDB;
GO

CREATE TABLE FileStreamTest1 (
	TestId UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL UNIQUE,
	Name VARCHAR (25),
	Document VARBINARY(MAX) FILESTREAM);
GO

CREATE TABLE FileStreamTest2 (
	TestId UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL UNIQUE,
	Name VARCHAR (25),
	Document1 VARBINARY(MAX) FILESTREAM,
	Document2 VARBINARY(MAX) FILESTREAM);
GO

-- Now look at the filesystem again
-- New directories for the tables just created, with a
-- sub-directory for each FILESTREAM column

INSERT INTO FileStreamTest1 VALUES (
	NEWID (), 'Marcin Szeliga',
	CAST ('' AS VARBINARY(MAX)));
INSERT INTO FileStreamTest1 VALUES (
	NEWID (), '£ukasz Grala',
	CAST ('Some test data' AS VARBINARY(MAX)));
GO

-- Note - empty file creation useful for later
-- populations

SELECT * FROM FileStreamTest1;
GO

-- Note the two files in the FILESTREAM folder

-- Now what happens when we update a FILESTREAM value;
UPDATE FileStreamTest1
SET Document = CAST (REPLICATE ('a', 8000)
	AS VARBINARY(MAX))
WHERE Name LIKE '%al%';
GO

-- Look again and see that the original file hasn't been
-- deleted, there are three files now, representing two
-- values. It will be garbage collected later.

-- Open the second file in notepad to demonstrate that
-- someone with privileges can access the files.
-- Now delete the file and try selecting from the table
-- again.
SELECT * FROM FileStreamTest1;
GO

-- Connection broken. Look in the latest error log using
-- SSMS
-- Try DBCC CHECKDB
DBCC CHECKDB (FileStreamTestDB)
	WITH ALL_ERRORMSGS, NO_INFOMSGS;
GO

-- DBCC CHECKDB does an extensive check.
-- Try creating a random file in the FILESTREAM directory
-- and running DBCC CHECKDB again
DBCC CHECKDB (FileStreamTestDB)
	WITH ALL_ERRORMSGS, NO_INFOMSGS;
GO
-- And it finds it. Repair can fix all FILESTREAM
-- errors too.


