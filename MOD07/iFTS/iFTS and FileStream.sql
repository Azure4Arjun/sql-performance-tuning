:on error exit
go

!! if not exist c:\sql\Files mkdir c:\sql\Files
!! if exist c:\sql\Files\LogFiles rmdir /s /q c:\sql\Files\LogFiles
go
use master
go
if exists (select 1 from sys.databases where name = 'iFTS')
	alter database iFTS set single_user with rollback immediate
go
if exists (select 1 from sys.databases where name = 'iFTS')
	drop database iFTS 
go
create database iFTS ON 
( NAME = iFTS_data, 
    FILENAME = N'c:\sql\iFTS_data.mdf',
    SIZE = 5MB,
    MAXSIZE = 50MB, 
    FILEGROWTH = 15%),
 FILEGROUP FileStreamGroup1 CONTAINS FILESTREAM
  ( NAME = FileStreamLogFiles, 
    FILENAME = N'c:\sql\Files\LogFiles')
go
use iFTS
go
if object_id('iFTSDemo') IS NOT NULL 
	drop table iFTSDemo
go
create table iFTSDemo(filename varchar(2000))
go

!! dir  /b /S c:\*.log > c:\sql\AllLogFiles.txt
go
!! type c:\sql\AllLogFIles.txt
go
!! bcp iFTS.dbo.iFTSDemo in c:\sql\AllLogFiles.txt -S -T -c -t@
go
alter table iFTSDemo add fileId int identity(1,1)
                       , blob [varbinary](max) FILESTREAM NULL
                       , blobType varchar(10) null
                       , guidKey [UNIQUEIDENTIFIER]  NOT NULL ROWGUIDCOL DEFAULT NEWID()
                       , constraint UQ_iFTSDemo_guidKey UNIQUE (guidKey)
                       , constraint UQ_iFTSDemo_fileId UNIQUE (fileId)
go
:on error continue
go
set nocount on
declare @i int = 0

while @i < (select count(1) from iFTSDemo)
  begin
  declare @filename varchar(200) = (select filename from iFTSDemo where fileId = @i)
  declare @sql nvarchar(max) = '
  update iFTSDemo
     set blob = ( SELECT d
       FROM OPENROWSET(BULK N''' + replace(@filename,'''','''''') + ''', SINGLE_BLOB) AS Document(d)) 
        ,blobType = ''log''
   where fileId = @fileid'
 
  print @sql
  exec sp_executesql @sql, N'@fileId int',@i
 
  set @i += 1
  end
go

select *
from iFTSDemo
go

create fulltext catalog FTCatalog 
go
--drop FULLTEXT INDEX ON [dbo].[iFTSDemo]
go
--Create new index with new STOPLIST option
CREATE FULLTEXT INDEX ON [dbo].[iFTSDemo](
[blob] TYPE COLUMN blobtype)
KEY INDEX UQ_iFTSDemo_fileId ON ([FTCatalog], FILEGROUP [PRIMARY])
WITH (CHANGE_TRACKING = AUTO, STOPLIST = SYSTEM)
go
--wait until the data has been indexed
--if this doesn't complete check the crawler log
--C:\Program Files\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL\LOG\SQLFT********.Log
while (select objectpropertyex(object_id('iftsdemo'),'TableFulltextPopulateStatus'))=1
  waitfor delay '00:00:05'
  
print 'indexing completed'
go

--Show the new query plan without the docmap lookup

select * 
from containstable(iftsdemo,*, 'error') 
go

/*
select *
from containstable(iftsdemo,*, 'error') as ifts 
join iftsdemo as t on t.[fileId] = ifts.[key]
*/
--Show the new dmvs that display the index contents
--Can be used to understand the content or the data
--Index keywords
select * 
from sys.dm_fts_index_keywords(db_id(), object_id('iFtsDemo'))
order by document_count desc
go

select *
from [iFTSDemo]
where contains ([blob], 'NEAR(sql ,error)')


--Document keywords
--This dmv returns ALL keywords for your index and will ve VERY LARGE
--Because we are using an integer key the document_id is our table key
--
--If you want to use there in your application schedule a process to perisist this data to a table
select d.* 
from sys.dm_fts_index_keywords_by_document( DB_ID(), OBJECT_ID('iFtsDemo') ) d
join iFtsDemo on iFtsDemo.fileId = d.document_id
--where filename = 'c:\windows\svcpack.log'
order by occurrence_count desc

go
--If we were using a non integer key then we could map the documentId to key using the docidmap table. 
--
select * from sys.fulltext_indexes
select * from sys.internal_tables

go

use master
go
DROP DATABASE ifts