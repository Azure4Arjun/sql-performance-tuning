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

CREATE PROCEDURE [dbo].[usp_temp_table]
AS 
    CREATE TABLE #tmpTable
        (
          c1 INT,
          c2 INT,
          c3 CHAR(5000)
        ) ;
    CREATE UNIQUE CLUSTERED INDEX cix_c1 ON #tmptable ( c1 ) ;
    DECLARE @i INT = 0 ;
    WHILE ( @i < 10 ) 
        BEGIN
            INSERT  INTO #tmpTable ( c1, c2, c3 )
            VALUES  ( @i, @i + 100, 'coeo' ) ;
            SET  @i += 1 ;
        END ;
GO

CREATE PROCEDURE [dbo].[usp_loop_temp_table]
AS 
    SET nocount ON ;
    DECLARE @i INT = 0 ;
    WHILE ( @i < 100 )
        BEGIN
            EXEC DBTestTempDB.dbo.usp_temp_table ;
            SET  @i += 1 ;
        END ;
GO

--- ostress
DBCC sqlperf('sys.dm_os_wait_stats',clear);
--- Change TempDB and reapeat test
ALTER DATABASE tempdb
ADD FILE (NAME = tempdev2, FILENAME = 'C:\sql\tempdb2.mdf', SIZE = 200);
ALTER DATABASE tempdb
ADD FILE (NAME = tempdev3, FILENAME = 'C:\sql\tempdb3.mdf', SIZE = 200);
ALTER DATABASE tempdb
ADD FILE (NAME = tempdev4, FILENAME = 'C:\sql\tempdb4.mdf', SIZE = 200);
GO


--Cleanup
USE tempdb
GO
DBCC SHRINKFILE (tempdev2,EMPTYFILE)
DBCC SHRINKFILE (tempdev3,EMPTYFILE)
DBCC SHRINKFILE (tempdev4,EMPTYFILE)
GO
ALTER DATABASE [tempdb] 
REMOVE FILE tempdev2
GO
ALTER DATABASE [tempdb] 
REMOVE FILE tempdev3
GO
ALTER DATABASE [tempdb] 
REMOVE FILE tempdev4
GO
