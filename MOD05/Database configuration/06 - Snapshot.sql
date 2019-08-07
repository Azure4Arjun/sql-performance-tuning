/*

	Training:	Optimizing and Troubleshooting
	Module:		06 - Database Configuration
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/

CREATE DATABASE AdventureWorks_Snapshot1200 ON
(NAME = N'AdventureWorks2012_Data', 
FILENAME = N'C:\sql\AW_1200.ss')
AS SNAPSHOT OF AdventureWorks2012;
GO
SELECT AddressID, AddressLine1, ModifiedDate
FROM AdventureWorks2012.Person.Address
WHERE AddressID = 1;
GO

SELECT AddressID, AddressLine1, ModifiedDate
FROM AdventureWorks_Snapshot1200.Person.Address
WHERE AddressID = 1;
GO

UPDATE AdventureWorks2012.Person.Address
SET AddressLine1 = '1000 Napa Ct.'
WHERE AddressID = 1;
GO

DROP DATABASE [AdventureWorks_Snapshot1200]

