-- (2)
use AdventureWorks2008
go
begin tran

update HumanResources.Department
set Name = 'aaaa'
where DepartmentID = 1

update HumanResources.Department
set Name = 'aaab'
where DepartmentID = 2

--rollback