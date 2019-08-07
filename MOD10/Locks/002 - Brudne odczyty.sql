USE AdventureWorks2012;

BEGIN TRANSACTION;

UPDATE  Person.Person
SET     FirstName = 'James'
WHERE   LastName = 'Jones';

WAITFOR DELAY '00:00:05.000';

ROLLBACK TRANSACTION;

SELECT  FirstName
        ,LastName
FROM    Person.Person
WHERE   LastName = 'Jones';
GO