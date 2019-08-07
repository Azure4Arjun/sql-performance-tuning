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
SET NOCOUNT ON;
GO

-- Create a table to play with
CREATE TABLE [ProdTable] (
	[c1] INT IDENTITY,
	[c2] DATETIME DEFAULT GETDATE (),
	[c3] AS c1 * 2 PERSISTED,
	[c4] CHAR (5) DEFAULT 'a');
GO

INSERT INTO [ProdTable] DEFAULT VALUES;
GO 1000

-- Take initial backups
BACKUP DATABASE [DBTranLog]
TO DISK = N'c:\sql\DBTranLog_Full.bak'
WITH INIT;
GO

BACKUP LOG [DBTranLog]
TO DISK = N'c:\sql\DBTranLog_Log1.bak'
WITH INIT;
GO

-- Insert some more data
INSERT INTO [ProdTable] DEFAULT VALUES;
GO 1000

CREATE CLUSTERED INDEX [Prod_CL]
ON [ProdTable] ([c1]);
GO
CREATE NONCLUSTERED INDEX [Prod_NCL]
ON [ProdTable] ([c2]);
GO

INSERT INTO [ProdTable] DEFAULT VALUES;
GO 1000

-- Now do something specific
DROP INDEX [Prod_NCL] ON [ProdTable];
GO

INSERT INTO [ProdTable] DEFAULT VALUES;
GO 1000

-- Can we find it?
SELECT * FROM fn_dblog (NULL, NULL);
GO

SELECT * FROM fn_dblog (NULL, NULL)
WHERE [Transaction Name] LIKE N'%DROP%';
GO

SELECT * FROM fn_dblog (NULL, NULL)
WHERE [Transaction Id] = N'0000:00000f7d';
GO

-- Prove its a drop index on the table we're
-- interested in...
SELECT TOP (1) [Lock Information] FROM fn_dblog (NULL, NULL)
WHERE [Transaction Id] = N'0000:00000f7d'
AND [Lock Information] LIKE N'%SCH_M OBJECT%';
GO

HoBt 0:ACQUIRE_LOCK_SCH_M OBJECT: 172455759130 
SELECT OBJECT_NAME (245575913);
GO

-- You could also find out which SPID did the drop and if
-- you're logging failed AND successful logins, you can see
-- who did the deed!

-- Now what if the log isn't there any more...
BACKUP LOG [DBTranLog]
TO DISK = N'c:\sql\DBTranLog_Log2.bak'
WITH INIT;
GO

SELECT * FROM fn_dblog (NULL, NULL);
GO

-- Use the ability to return log from a backup...
SELECT * FROM fn_dump_dblog (
	NULL, NULL, N'DISK', 1, N'c:\sql\DBTranLog_Log2.bak',
	DEFAULT,DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
GO

SELECT * FROM fn_dump_dblog (
	NULL, NULL, N'DISK', 1, N'c:\sql\DBTranLog_Log2.bak',
	DEFAULT,DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
	DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT)
WHERE [Transaction Name] LIKE N'%DROP%';
GO

-- And so on...

-- Imagine that was a DROP TABLE command, we could
-- restore a copy of the database back to just before
-- the drop...

-- Restore full backup and all log backups....
-- Need to convert the LSN to decimal in format
-- 'lsn:<VLFSeqnum><10character log block><5character log rec)'
-- e.g. '00000028:0000003a:0001' becomes '40000000005800001'
--

DECLARE @LSN varchar(22),
    @LSN1 varchar(11),
    @LSN2 varchar(10),
    @LSN3 varchar(5)

Set @LSN = '0000001e:00000038:0001';
Set @LSN1 = LEFT(@LSN, 8);
Set @LSN2 = SUBSTRING(@LSN, 10, 8);
Set @LSN3 = RIGHT(@LSN, 4);

-- Convert to binary style 1 -> int
Set @LSN1 = CAST(CONVERT(VARBINARY, '0x' +
        RIGHT(REPLICATE('0', 8) + @LSN1, 8), 1) As int);

Set @LSN2 = CAST(CONVERT(VARBINARY, '0x' +
        RIGHT(REPLICATE('0', 8) + @LSN2, 8), 1) As int);

Set @LSN3 = CAST(CONVERT(VARBINARY, '0x' +
        RIGHT(REPLICATE('0', 8) + @LSN3, 8), 1) As int);

-- Add padded 0's to 2nd and 3rd string
Select CAST(@LSN1 as varchar(8)) +
    CAST(RIGHT(REPLICATE('0', 10) + @LSN2, 10) as varchar(10)) +
    CAST(RIGHT(REPLICATE('0', 5) + @LSN3, 5) as varchar(5));
GO

RESTORE LOG DBTranLog
FROM DISK = N'c:\sql\DBTranLog_Log1.bak'
WITH NORECOVERY;

RESTORE LOG [DBTranLog]
	FROM DISK = N'c:\sql\DBTranLog_Log2.bak'
	WITH STOPBEFOREMARK = N'lsn:41000000049700001',
	NORECOVERY, STATS;
GO

RESTORE DATABASE DBTranLog