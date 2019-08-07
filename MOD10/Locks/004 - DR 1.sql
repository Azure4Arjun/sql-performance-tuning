Use AdventureWorks2012;

BEGIN TRAN
UPDATE  Person.Person
SET     LastName    = 'Raheem_DOUBLE_READ_BLOCK'
WHERE   LastName    = 'Raheem'
AND     FirstName   = 'Kurt';
GO

--------------------------------
UPDATE  Person.Person
SET     LastName    = 'Raheem_DOUBLE_READ_REAL'
WHERE   LastName    = 'Raheem'
AND     FirstName   = 'Bethany';

COMMIT TRAN;