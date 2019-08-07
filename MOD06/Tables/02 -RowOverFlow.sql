USE AdventureWorks
SELECT OBJECT_NAME(OBJECT_ID) AS name,
    partition_id, partition_number AS pnum, rows,
    allocation_unit_id AS au_id, type_desc as page_type_desc,
    total_pages AS pages
FROM sys.partitions p JOIN sys.allocation_units a
   ON p.partition_id = a.container_id
WHERE OBJECT_ID=OBJECT_ID('HumanResources.Employee');
GO


USE tempdb;
IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '%rowoverflowtest%' ) BEGIN DROP TABLE rowoverflowtest END

CREATE TABLE rowoverflowtest (c1 INT, c2 VARCHAR (8000), c3 VARCHAR (8000));
GO
CREATE CLUSTERED INDEX row_cl ON rowoverflowtest (c1);
GO

INSERT INTO rowoverflowtest 
VALUES (1, REPLICATE ('a', 100), REPLICATE ('b', 100)),
	(2, REPLICATE ('a', 100), REPLICATE ('b', 100)),
	(3, REPLICATE ('a', 100), REPLICATE ('b', 100)),
	(4, REPLICATE ('a', 100), REPLICATE ('b', 100)),
	(5, REPLICATE ('a', 100), REPLICATE ('b', 100));
GO

DBCC IND ('tempdb', 'rowoverflowtest', 1);
GO

SELECT sys.fn_physLocFormatter (%%physloc%%),%%physloc%%, * FROM rowoverflowtest

DBCC TRACEON (3604);
GO

DBCC PAGE (tempdb, 3, 40, 3);
GO

UPDATE rowoverflowtest 
SET c3 = REPLICATE ('c', 8000) WHERE c1 = 3;
GO

DBCC IND ('tempdb', 'rowoverflowtest', 1);
GO

DBCC PAGE (tempdb, 3, 40, 3);
GO
