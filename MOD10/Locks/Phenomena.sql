USE AdventureWorks
GO
--DIRTY READ
--S1
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRAN;
UPDATE HumanResources.Department
SET Name = 'ZmianaWToku'
WHERE DepartmentID=5;

--S2
USE AdventureWorks
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT Name
FROM HumanResources.Department
WHERE DepartmentID = 5;


--S1 
ROLLBACK

--NON-REPEATABLE READS
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRAN;
SELECT Name
FROM HumanResources.Department
WHERE DepartmentID = 5;

--S2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
UPDATE HumanResources.Department
SET Name = 'OdczytWToku'
WHERE DepartmentID=5;

--S1
SELECT Name
FROM HumanResources.Department
WHERE DepartmentID = 5;
COMMIT TRAN;

--CLEAN
UPDATE HumanResources.Department
SET Name = 'Purchasing'
WHERE DepartmentID=5;


--LOST UPDATE
--S1
BEGIN TRAN;
DECLARE @C1 MONEY =
(SELECT ListPrice
FROM Production.Product
WHERE ProductID=900)
PRINT @C1
SET @C1 *=1.1
PRINT @C1

--S2

BEGIN TRAN;
DECLARE @C2 MONEY =
(SELECT ListPrice
FROM Production.Product
WHERE ProductID=900)
PRINT @C2
SET @C2 *=0.9
PRINT @C2

--S1
UPDATE Production.Product
SET ListPrice = 366.76
WHERE ProductID=900;
COMMIT;

--S2
UPDATE Production.Product
SET ListPrice = 300.08
WHERE ProductID=900;
COMMIT;

--S1
SELECT ListPrice
FROM Production.Product
WHERE ProductID=900

--PHANTOM READS
--S1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRAN;
SELECT ProductID,Name, ListPrice
FROM Production.Product
WHERE ListPrice BETWEEN 10 AND 15;

--S2
UPDATE Production.Product
SET ListPrice = 12
WHERE ProductID =2;


--S1
SELECT ProductID,Name, ListPrice
FROM Production.Product
WHERE ListPrice BETWEEN 10 AND 15;

--S2
UPDATE Production.Product
SET ListPrice = 8
WHERE ProductID =2 

--S1
SELECT ProductID,Name, ListPrice
FROM Production.Product
WHERE ListPrice BETWEEN 10 AND 15;

COMMIT TRAN;

--CLEAN
UPDATE Production.Product
SET ListPrice = 0
WHERE ProductID =2


--SERIALIZABLE
--S1
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRAN;
SELECT ProductID, Name
FROM Production.Product
WHERE ListPrice BETWEEN 10 AND 15;

SELECT @@spid
SELECT resource_type, request_mode, request_type, request_status
FROM sys.dm_tran_locks
WHERE request_session_id = 51

--S2
UPDATE Production.Product
SET ListPrice = 12
WHERE ProductID =2;

--S1
COMMIT

CREATE INDEX ProductListPrice
ON Production.Product(ListPrice)

USE master;

CREATE DATABASE Wersjonowanie

ALTER DATABASE Wersjonowanie
SET READ_COMMITTED_SNAPSHOT ON
WITH ROLLBACK IMMEDIATE;

--SESJA 1
USE Wersjonowanie;

SELECT * 
INTO Employee
FROM AdventureWorks2008R2.HumanResources.Employee

BEGIN TRAN;
UPDATE Employee 
SET JobTitle = 'X'
WHERE BusinessEntityID <3;

--SESJA 2
USE Wersjonowanie;
SELECT BusinessEntityID, JobTitle
FROM Employee
WHERE BusinessEntityID <5;

--SESJA 1
ROLLBACK
USE master;
DROP DATABASE Wersjonowanie;