EXEC dbo.uspGetEmployeeManagers '10'
EXEC dbo.uspGetEmployeeManagers '21'
GO 30
EXEC dbo.uspGetEmployeeManagers '148'
GO
EXEC dbo.uspGetEmployeeManagers '40'
GO
EXEC dbo.uspGetEmployeeManagers '159'
GO
SELECT OrderQty
FROM Sales.SalesOrderDetail
WHERE OrderQty >30
ORDER BY OrderQty
GO 10

SELECT *
FROM Sales.SalesOrderHeader
WHERE DueDate ='2004-08-12 00:00:00.000'
GO 23

EXEC dbo.uspGetManagerEmployees '159'
GO
EXEC dbo.uspGetManagerEmployees '140'
SELECT * FROM HumanResources.vEmployee
SELECT EmployeeID,FirstName,LastName FROM HumanResources.vEmployee WHERE EmployeeID <100
GO
SELECT PC.Name, PS.name, COUNT(ProductID)
FROM Production.Product P JOIN Production.ProductSubCategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
join Production.ProductCategory PC on PC.ProductCategoryID = PS.ProductCategoryID
GROUP BY PC.Name, PS.name
WITH CUBE
GO 50
SELECT PC.Name, PS.name, COUNT(ProductID)
FROM Production.Product P JOIN Production.ProductSubCategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
join Production.ProductCategory PC on PC.ProductCategoryID = PS.ProductCategoryID
WHERE P.NaMe like 'f%'
GROUP BY PC.Name, PS.name
WITH CUBE
GO
SELECT PC.Name, PS.name, COUNT(ProductID)
FROM Production.Product P WITH (INDEX(1)) RIGHT OUTER JOIN Production.ProductSubCategory PS WITH (INDEX(0)) ON P.ProductSubcategoryID = PS.ProductSubcategoryID
join Production.ProductCategory PC WITH (INDEX(0)) on PC.ProductCategoryID = PS.ProductCategoryID
GROUP BY PC.Name, PS.name
WITH CUBE
SELECT PC.Name, PS.name, COUNT(ProductID)
FROM Production.Product P WITH (INDEX(2)) RIGHT OUTER JOIN Production.ProductSubCategory PS WITH (INDEX(2)) ON P.ProductSubcategoryID = PS.ProductSubcategoryID
join Production.ProductCategory PC WITH (INDEX(2)) on PC.ProductCategoryID = PS.ProductCategoryID
WHERE P.NaMe NOT like 'f%'
GROUP BY PC.Name, PS.name
WITH CUBE
GO 50
SELECT * FROM HumanResources.vEmployeeDepartment
SELECT * FROM HumanResources.vEmployeeDepartment WHERE FirstName LIKE 'A%'
GO
SELECT * FROM HumanResources.vEmployeeDepartmentHistory
SELECT * FROM HumanResources.vEmployeeDepartmentHistory
GO
SELECT * FROM HumanResources.vEmployeeDepartmentHistory
SELECT * FROM HumanResources.vJobCandidate
SELECT JobCandidateID, [Edu.Level] FROM HumanResources.vJobCandidateEducation
SELECT JobCandidateID,[Edu.Level] FROM HumanResources.vJobCandidateEducation 
SELECT * FROM HumanResources.vJobCandidateEmployment
GO
SELECT JobCandidateID,[Emp.Loc.City]
FROM HumanResources.vJobCandidateEmployment
ORDER BY [Emp.StartDate]
SELECT * FROM Person.vAdditionalContactInfo
SELECT * FROM HumanResources.vJobCandidateEmployment
SELECT * FROM HumanResources.vJobCandidateEmployment
SELECT * FROM HumanResources.vJobCandidateEmployment
GO 5
SELECT * FROM Person.vAdditionalContactInfo
SELECT * FROM Person.vStateProvinceCountryRegion
SELECT * FROM HumanResources.vJobCandidateEmployment 
SELECT * FROM Person.vStateProvinceCountryRegion
SELECT * FROM Production.vProductAndDescription
SELECT Name,Description
FROM Production.vProductAndDescription
WHERE ProductID <800
SELECT * FROM Production.vProductModelCatalogDescription
SELECT * FROM Production.vProductModelInstructions
GO
SELECT * FROM Purchasing.vVendor
SELECT * FROM Sales.vIndividualCustomer
SELECT * FROM Sales.vIndividualCustomer 
SELECT CustomerID FROM Sales.vIndividualCustomer WHERE CustomerID >2000
SELECT * FROM Sales.vIndividualDemographics
SELECT * FROM Sales.vSalesPerson
GO 30
SELECT * FROM Sales.vSalesPerson
GO
SELECT * FROM Sales.vSalesPerson
SELECT * FROM Sales.vSalesPerson
GO
SELECT * FROM Sales.vSalesPerson
SELECT * FROM Sales.vSalesPerson
SELECT * FROM Sales.vSalesPerson
SELECT * FROM Sales.vSalesPersonSalesByFiscalYears
SELECT * FROM Sales.vSalesPersonSalesByFiscalYears
SELECT * FROM Sales.vSalesPersonSalesByFiscalYears
SELECT * FROM Sales.vSalesPersonSalesByFiscalYears
SELECT * FROM Sales.vStoreWithDemographics
SELECT * FROM HumanResources.Department,HumanResources.Employee
SELECT HumanResources.Employee.EmployeeID FROM HumanResources.Employee, 
HumanResources.EmployeeAddress
WHERE HumanResources.Employee.EmployeeID <100
GO 20
EXEC dbo.uspGetBillOfMaterials 100,'19000101'
EXEC dbo.uspGetEmployeeManagers '30'
EXEC dbo.uspGetEmployeeManagers '140'
GO
EXEC dbo.uspGetEmployeeManagers '10'
EXEC dbo.uspGetEmployeeManagers '21'
EXEC dbo.uspGetEmployeeManagers '148'
EXEC dbo.uspGetEmployeeManagers '40'
EXEC dbo.uspGetEmployeeManagers '159'
GO
EXEC dbo.uspGetManagerEmployees '159'
EXEC dbo.uspGetManagerEmployees '140'
GO
DECLARE @SalesPersonID AS INT, @OrderDate AS DATETIME, @PrevSalesPersonID AS INT, @PrevOrderDate AS DATETIME
DECLARE SelOrdersCursor CURSOR FAST_FORWARD
FOR SELECT SalesPersonID, OrderDate FROM Sales.SalesOrderHeader ORDER BY SalesPersonID, OrderDate
OPEN SelOrdersCursor
FETCH NEXT FROM SelOrdersCursor INTO @SalesPersonID, @OrderDate
SELECT @PrevSalesPersonID = @SalesPersonID, @PrevOrderDate = @OrderDate
WHILE @@fetch_status = 0
BEGIN
IF @PrevSalesPersonID != @SalesPersonID AND @PrevOrderDate < '20040801'
PRINT @PrevSalesPersonID
SELECT @PrevSalesPersonID = @SalesPersonID, @PrevOrderDate = @OrderDate
FETCH NEXT FROM SelOrdersCursor
INTO @SalesPersonID, @OrderDate
END
IF @PrevOrderDate < '20040801' PRINT @PrevSalesPersonID
CLOSE SelOrdersCursor
DEALLOCATE SelOrdersCursor
GO 10
