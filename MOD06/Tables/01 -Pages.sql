-- DBCC PAGE
-- We'll look at a simple page from the pubs database authors table

-- First take a look at the data
USE AdventureWorks2012
GO
SELECT * FROM Person.Person

SELECT sys.fn_physLocFormatter (%%physloc%%),%%physloc%%, * 
FROM Person.Person
WHERE BusinessEntityID < 50

DBCC TRACEON(3604)

-- Examine Buffer and Page Header
DBCC PAGE(AdventureWorks2012, 1, 1472, 0)

-- Examine header plus each row
DBCC PAGE(AdventureWorks2012, 1, 1472, 1)

-- Dump the page
DBCC PAGE(AdventureWorks2012, 1, 1472, 2)

-- Examine header plus full details for each row

DBCC PAGE(AdventureWorks2012, 1, 1472, 3)


-----------------------------------------------

-- DBCC PAGE for order of rows

DBCC PAGE(AdventureWorks2012,1,1,3)

DBCC PAGE(AdventureWorks2012,1,2,3)

DBCC PAGE(AdventureWorks2012,1,3,3)

DBCC PAGE(AdventureWorks2012,1,9,3)
