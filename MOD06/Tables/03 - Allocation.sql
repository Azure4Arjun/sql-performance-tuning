USE master
GO
IF DB_ID('Storage') IS NOT NULL DROP DATABASe Storage;
GO

CREATE DATABASE Storage
GO
-- Basic Data Storage Metadata

USE Storage;


IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'hugerows')
   DROP TABLE hugerows;
GO


-- Create a table with rows that practically fill a page
CREATE TABLE hugerows 
   (a char(1000),  
    b varchar(7000) )
GO
INSERT INTO hugerows 
     SELECT REPLICATE('a', 1000), REPLICATE('b', 1000)
	
GO

-- Look at the main storage views
--  Note there is one row in each view for our hugerows table
SELECT * 
FROM sys.indexes
WHERE object_id = object_id('hugerows')
GO

SELECT * 
FROM sys.partitions
WHERE object_id = object_id('hugerows')
GO

SELECT * 
FROM sys.allocation_units
WHERE container_id = 
   (SELECT partition_id FROM sys.partitions
     WHERE object_id = object_id('hugerows'))
GO

-- There are 3 extra columns in undoc'd view
SELECT * 
FROM sys.system_internals_allocation_units
WHERE container_id = 
   (SELECT partition_id FROM sys.partitions
     WHERE object_id = object_id('hugerows'))
GO

-- Recreate the table with a text column


IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'hugerows')
   DROP TABLE hugerows;
GO

CREATE TABLE hugerows 
   (a char(1000),  
    b varchar(7000),
    c text )
GO
INSERT INTO hugerows 
     SELECT REPLICATE('a', 1000), REPLICATE('b', 1000),
	      REPLICATE('c', 10000)
GO


SELECT * 
FROM sys.allocation_units
WHERE container_id = 
   (SELECT partition_id FROM sys.partitions
     WHERE object_id = object_id('hugerows'))
GO

-- There are 3 extra columns in undoc'd view
SELECT * 
FROM sys.system_internals_allocation_units
WHERE container_id = 
   (SELECT partition_id FROM sys.partitions
     WHERE object_id = object_id('hugerows'))
GO


-- Observe how space is allocated to a table
-- Observe the relationship between reserved, data, and unused 
-- in the sp_spaceused output

SET NOCOUNT ON

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'AllocationTest')
	DROP TABLE AllocationTest;
GO
CREATE TABLE AllocationTest
(col1 int identity, col2 char(8000) default 'default')
GO

INSERT INTO AllocationTest DEFAULT VALUES
GO
EXEC sp_spaceused 'AllocationTest'

DBCC EXTENTINFO (Storage, AllocationTest, -1)

INSERT INTO AllocationTest DEFAULT VALUES
GO 5

EXEC sp_spaceused 'AllocationTest'

-- In SQL Server 2005, (re)creating a clustered index would always
--  get rid of any mixed extents
-- In SQL Server 2008, you must have more than 3-extents worth of 
--  pages to get have mixed extents removed


DBCC EXTENTINFO (Storage, AllocationTest, -1)

INSERT INTO AllocationTest DEFAULT VALUES
GO 20

EXEC sp_spaceused 'AllocationTest'
DBCC EXTENTINFO (Storage, AllocationTest, -1)

CREATE CLUSTERED INDEX alloc_index on AllocationTest(col1)

EXEC sp_spaceused 'AllocationTest'
DBCC EXTENTINFO (Storage, AllocationTest, -1)


-- Getting page numbers
-- fn_physLocFormatter

USE pubs;
GO

SELECT sys.fn_physLocFormatter (%%physloc%%), *
FROM authors;
GO

---- sys.system_internals_allocation_units
SELECT  OBJECT_NAME(OBJECT_ID), Rows, total_pages, first_page, root_page, first_iam_page
FROM sys.partitions p JOIN sys.system_internals_allocation_units a
	ON p.partition_id = a.container_id
WHERE OBJECT_NAME(OBJECT_ID) = 'authors'
	AND index_id  < 2;

-- Example: 0x9D0000000100	-- use the value you get for first_page

-- Separate into bytes, 2 digits each:  9D 00 00 00 01 00
-- Reverse bytes: 00 01 00 00 00 9D
-- First two bytes are file number: 00 01 = File 1
-- Last four bytes are page number: 00 00 00 9D = Page 157

----DBCC IND

DBCC IND (pubs, authors, -1)

-- A small table will only return a few rows
-- A large table will return LOTS of rows, one row for every 
-- page of every index, and one row for each page of 
-- special storage formats

DBCC IND (AdventureWorks, 'Sales.SalesOrderHeader', -1)


-- It's hard to visually scan almost 1000 rows of output to 
-- the information of interest


-- Create a table to hold the output of DBCC IND


USE master

IF exists (SELECT 1 FROM sys.tables WHERE name = 'sp_DBCC_IND_info')
    DROP TABLE sp_DBCC_IND_info;
GO
CREATE TABLE sp_DBCC_IND_info
(PageFID  tinyint, 
  PagePID int,   
  IAMFID   tinyint, 
  IAMPID  int, 
  ObjectID  int,
  IndexID  tinyint,
  PartitionNumber tinyint,
  PartitionID bigint,
  iam_chain_type  varchar(30),    
  PageType  tinyint, 
  IndexLevel  tinyint,
  NextPageFID  tinyint,
  NextPagePID  int,
  PrevPageFID  tinyint,
  PrevPagePID int, 
  Primary Key (PageFID, PagePID));

-- Examples of use:

-- Look at small table in pubs
USE pubs;

TRUNCATE TABLE sp_DBCC_IND_info;

 INSERT INTO sp_DBCC_IND_info
    EXEC ('DBCC IND ( pubs, authors, -1 )');
GO
SELECT * FROM sp_DBCC_IND_info;
GO

-- Look at bigger table in AdventureWorks

USE AdventureWorks;
GO

TRUNCATE TABLE sp_DBCC_IND_info;
GO
INSERT INTO sp_DBCC_IND_info
    EXEC ('DBCC IND (AdventureWorks, [Sales.SalesOrderHeader], -1) ');
GO
-- Find first data page
SELECT  * 
FROM sp_DBCC_IND_info
WHERE pagetype = 1 AND prevpagePID = 0 AND prevpageFID = 0;


-- how many pages of each type
SELECT PageType, number = count(*)
FROM sp_DBCC_IND_info
GROUP BY PageType;

--how many pages for each index 
-- You must be in the AdventureWorks database to get the index name
USE AdventureWorks;

SELECT Index_ID, name,  number = count(*)
FROM sp_DBCC_IND_info info JOIN sys.indexes 
	ON IndexID = Index_ID AND ObjectID = Object_ID
GROUP BY Index_ID, name
ORDER BY Index_ID; 

