ALTER DATABASE AdventureWorks
ADD FILEGROUP Group2
GO 
ALTER DATABASE AdventureWorks
ADD FILEGROUP Group3
GO
ALTER DATABASE AdventureWorks
ADD FILE (NAME = File2, FILENAME = 'c:\SQL\plik2.ndf')
TO FILEGROUP Group2
GO
ALTER DATABASE AdventureWorks
ADD FILE (NAME = File3, FILENAME = 'c:\SQL\plik3.ndf')
TO FILEGROUP Group3
GO
USE AdventureWorks
CREATE PARTITION FUNCTION emailPF (nvarchar(50))
AS RANGE RIGHT FOR VALUES ('G', 'N')
GO
SELECT $PARTITION.emailPF ('Abramowski'), 
$PARTITION.emailPF ('Kowlaski'),
$PARTITION.emailPF ('Nowak')
GO
CREATE PARTITION SCHEME emailPS
AS PARTITION emailPF TO ([Default], Group2, Group3)
GO
CREATE TABLE Person.Email
(PersonID int, email nvarchar(50))
ON emailPS (Email)
GO
INSERT INTO Person.Email
SELECT TOP 300 ContactID, EmailAddress 
FROM Person.Contact ORDER BY Title 
GO
SELECT * FROM Person.Email
WHERE $PARTITION.emailPF(email) = 2
GO
CREATE INDEX IdxEmail
ON Person.Email (email)
ON emailPS (Email)
GO
ALTER PARTITION FUNCTION emailPF()
MERGE RANGE ('N')
GO
SELECT partition_number, rows
FROM sys.partitions 
WHERE object_id = OBJECT_ID('Person.Email')
  AND index_id <= 1
GO
CREATE TABLE Person.TempEmail
(PersonID int, email nvarchar(50))
ON Grupa2
GO
ALTER TABLE Person.Email SWITCH PARTITION 2 TO Person.TempEmail 
GO
SELECT * FROM Person.TempEmail 
GO
SELECT * FROM Person.Email
WHERE $PARTITION.emailPF(email) = 2
GO
DROP TABLE Person.TempEmail
GO
--Clean up
DROP TABLE Person.Email
GO
DROP PARTITION SCHEME emailPS
GO
DROP PARTITION FUNCTION emailPF
GO
ALTER DATABASE AdventureWorks
REMOVE FILE File2
GO
ALTER DATABASE AdventureWorks
REMOVE FILE File3
GO
ALTER DATABASE AdventureWorks
REMOVE FILEGROUP Group3
GO
ALTER DATABASE AdventureWorks
REMOVE FILEGROUP Group2
GO