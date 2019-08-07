USE AdventureWorks2012;

BEGIN TRANSACTION;

UPDATE  Person.Person
SET     Suffix      = 'Junior'
WHERE   LastName    = 'Abbas'
AND     FirstName   = 'Syed';

COMMIT TRANSACTION;

/*
SELECT TOP   5 
             FirstName
            ,MiddleName 
            ,LastName
            ,Suffix 
FROM        Person.Person
ORDER BY    LastName;

UPDATE  Person.Person
SET     Suffix      = NULL
WHERE   LastName    = 'Abbas'
AND     FirstName   = 'Syed';
*/
