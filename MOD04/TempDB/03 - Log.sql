/*

	Training:	Optimizing and Troubleshooting
	Module:		05 - SQL Server Configuration
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/

USE [master];
GO

IF DATABASEPROPERTYEX (N'DBTestTempDB', N'Version') > 0
BEGIN
	ALTER DATABASE [DBTestTempDB] SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [DBTestTempDB];
END
GO

CREATE DATABASE [DBTestTempDB];
GO

USE DBTestTempDB;
GO

CREATE TABLE ##tlog (c1 INT, c2 CHAR(100));
CREATE TABLE tlog (c1 INT, c2 CHAR(100));


CHECKPOINT

DECLARE @i INT;
SET @i=0;
WHILE @i<10
BEGIN
	INSERT INTO ##tlog
	VALUES (@i, REPLICATE ('A',100));
	INSERT INTO Tlog
	VALUES (@i, REPLICATE ('A',100));
	SET @i=@i+1;
END

UPDATE ##tlog
SET c2 =  REPLICATE ('b',100);

UPDATE tlog
SET c2 =  REPLICATE ('b',100);


USE tempdb;
GO
SELECT Operation, CONTEXT, [LOG record length]
FROM fn_dblog(null, null)
WHERE AllocUnitName = 'dbo.##tlog'
ORDER BY  [LOG record length] DESC

USE DBTestTempDB;
GO
SELECT Operation, CONTEXT, [LOG record length]
FROM fn_dblog(null, null)
WHERE AllocUnitName = 'dbo.tlog'
ORDER BY  [LOG record length] DESC
GO


USE tempdb;
GO
SELECT SUM([LOG record length]) 'SUM LOG records length'
FROM fn_dblog(null, null)
WHERE AllocUnitName = 'dbo.##tlog'
GO
USE DBTestTempDB;
GO
SELECT SUM([LOG record length]) 'SUM LOG records length'
FROM fn_dblog(null, null)
WHERE AllocUnitName = 'dbo.tlog'
GO
