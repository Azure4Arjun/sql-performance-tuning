-- (1)
use AdventureWorks2008
go
begin tran

update HumanResources.Department
set Name = 'aaa'
where DepartmentID = 2

-- (3)

update HumanResources.Department
set Name = 'aaab'
where DepartmentID = 1

--rollback