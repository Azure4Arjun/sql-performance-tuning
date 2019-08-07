--SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
UPDATE Production.Product
SET ReorderPoint = 600
WHERE ProductID = 316

WAITFOR DELAY '00:00:05';

SELECT ProductID, LocationID, Shelf, Bin, Quantity, ModifiedDate
FROM Production.ProductInventory
WHERE ProductID = 316
AND LocationID = 5

--ROLLBACK