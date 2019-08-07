USE AdventureWorks2012;

SET TRANSACTION ISOLATION LEVEL
READ COMMITTED;
--SERIALIZABLE;

BEGIN TRANSACTION;

SELECT TOP   5 
             FirstName
            ,MiddleName 
            ,LastName
            ,Suffix
FROM        Person.Person
ORDER BY    LastName;

WAITFOR DELAY '00:00:05.000';

SELECT TOP   5
             FirstName
            ,MiddleName
            ,LastName
            ,Suffix
FROM        Person.Person
ORDER BY    LastName;

COMMIT TRANSACTION;
GO