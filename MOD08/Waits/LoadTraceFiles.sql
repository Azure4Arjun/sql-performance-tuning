
USE master
GO
if exists (select * from sysdatabases where name='ProcessTraceFiles')
		DROP DATABASE ProcessTraceFiles;
go
CREATE DATABASE ProcessTraceFiles;
GO

USE ProcessTraceFiles;
GO


/*Change Table Name and File Name to appropriate values */

DECLARE @TableName AS VARCHAR(50);
SET @TableName = 'TestTrace';         
DECLARE @FileName AS VARCHAR(255) 
SET @FileName = 'C:\SQL\AdventureWorks_20120608-1033.trc';
DECLARE @Query AS NVARCHAR(max)

SET @Query = N'IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N''[dbo].[' + @TableName +']'')
                    AND type IN ( N''U'' ) ) 
    DROP TABLE [dbo].[' +@TableName +'];
	                                             
SELECT IDENTITY( int, 1, 1 ) AS RowNumber, *
INTO [' +@TableName +']
FROM
    fn_trace_gettable(''' +@FileName +''',
                      default);'     
                      
EXEC sp_executesql @Query