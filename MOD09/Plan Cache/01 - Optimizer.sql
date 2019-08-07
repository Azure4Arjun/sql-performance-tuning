USE AdventureWorks
GO

--Simplification
SELECT * FROM HumanResources.Employee
WHERE ManagerID > 10 AND ManagerID < 5;
GO

SELECT * 
FROM HumanResources.Employee
WHERE VacationHours > 80;

SELECT * 
FROM HumanResources.Employee
WHERE VacationHours > 300;
GO

ALTER TABLE HumanResources.Employee 
NOCHECK CONSTRAINT CK_Employee_VacationHours;
GO

SELECT * 
FROM HumanResources.Employee
WHERE VacationHours > 80;

SELECT * 
FROM HumanResources.Employee
WHERE VacationHours > 300;
GO

ALTER TABLE HumanResources.Employee 
WITH CHECK CHECK CONSTRAINT CK_Employee_VacationHours;
GO

SELECT FirstName, LastName--, CustomerType
FROM Person.Contact AS C 
JOIN Sales.Individual AS I 
	ON C.ContactID = I.ContactID 
JOIN Sales.Customer AS Cu 
	ON I.CustomerID = Cu.CustomerID;
GO

ALTER TABLE Sales.Individual 
NOCHECK CONSTRAINT FK_Individual_Customer_CustomerID;
GO

SELECT FirstName, LastName--, CustomerType
FROM Person.Contact AS C 
JOIN Sales.Individual AS I 
	ON C.ContactID = I.ContactID 
JOIN Sales.Customer AS Cu 
	ON I.CustomerID = Cu.CustomerID;
GO

ALTER TABLE Sales.Individual 
WITH CHECK CHECK CONSTRAINT FK_Individual_Customer_CustomerID;
GO

