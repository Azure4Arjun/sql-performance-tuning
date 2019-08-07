-- Catalog Views for Storge Information

-- Three views are needed to give us the same info as in the 
-- old sysindexes... which is now a compatability view

USE AdventureWorks;
GO

-- compare the following two SELECTs

SELECT * FROM sysindexes;


-- sys.indexes contains only basic property information

SELECT * FROM sys.indexes;


-- sys.partitions contains object_id and number of rows

SELECT OBJECT_ID, Rows, Partition_ID 
FROM sys.partitions;

SELECT OBJECT_NAME(OBJECT_ID), Rows, Partition_ID
FROM sys.partitions
WHERE OBJECT_NAME(OBJECT_ID) = 'SalesOrderHeader'
	AND index_id  < 2;
	
-- sys.allocation_units contains a container_id to join
--   with partition_id, and also page counts

SELECT * FROM sys.allocation_units;
GO

SELECT OBJECT_NAME(OBJECT_ID), Rows, total_pages
FROM sys.partitions p JOIN sys.allocation_units a
	ON p.partition_id = a.container_id
WHERE OBJECT_NAME(OBJECT_ID) = 'SalesOrderHeader'
	AND index_id  < 2;
	
-- sys.system_internals_allocation_units contains the
-- same data as sys.allocation_units, plus 3 page numbers

SELECT * FROM sys.system_internals_allocation_units;
GO


SELECT  OBJECT_NAME(OBJECT_ID), Rows, total_pages, first_page, root_page, first_iam_page
FROM sys.partitions p JOIN sys.system_internals_allocation_units a
	ON p.partition_id = a.container_id
WHERE OBJECT_NAME(OBJECT_ID) = 'SalesOrderHeader'
	AND index_id  < 2;



-- To get more information, join all three views
SELECT  OBJECT_NAME(i.OBJECT_ID) AS ObjectName, Name as IndexName, i.index_id as IndexID, i.type_desc as IndexType, Rows, total_pages, first_page, root_page, first_iam_page
FROM sys.indexes i JOIN sys.partitions p 
    ON i.object_id = p.object_id AND i.index_id = p.index_id
  JOIN sys.system_internals_allocation_units a
	ON p.partition_id = a.container_id
WHERE OBJECT_NAME(i.OBJECT_ID) = 'SalesOrderHeader';


-- Find Heaps

SELECT o.name, i.type_desc, o.type_desc, o.create_date
FROM sys.indexes i INNER JOIN sys.objects o
	ON  i.object_id = o.object_id
WHERE o.type_desc = 'USER_TABLE'
AND i.type_desc = 'HEAP'
ORDER BY o.name
GO

-- Key Information


SELECT OBJECT_NAME(c.object_id) as 'Object',name as 'Index_Column', index_id, key_ordinal      			
FROM sys.index_columns ic
    JOIN sys.columns c
        ON ic.object_id = c.object_id
        AND ic.column_id = c.column_id
WHERE key_ordinal > 0
 AND OBJECT_NAME(c.object_id) = 'SalesOrderDetail'
ORDER BY index_id, key_ordinal
GO

--DBCC PAGE format 3 is very different for index pages

-- Make a copy of the Person.Contact table
IF EXISTS (SELECT 1 FROM sys.tables     
               WHERE name = 'Contacts')
        DROP TABLE Contacts;
GO

SELECT * INTO Contacts
FROM Person.Contact;
GO

-- Create a clustered and a nonclustered index on Contacts
CREATE CLUSTERED INDEX lastnameindex ON Contacts(LastName);
CREATE INDEX firstnameindex on Contacts(FirstName);

-- Get the index id for the nonclustered index
SELECT * FROM sys.indexes   
       WHERE object_id = object_id('Contacts');
       
-- Find a page number for that index
DBCC IND(AdventureWorks, Contacts, 2);

-- Look at that page with format 3
DBCC PAGE (AdventureWorks, 1, 31514, 3); -- substitute a page found by DBCC IND