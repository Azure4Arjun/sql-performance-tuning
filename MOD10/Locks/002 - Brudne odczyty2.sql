USE AdventureWorks2012;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT  FirstName
        ,LastName
FROM    Person.Person
WHERE   LastName = 'Jones';