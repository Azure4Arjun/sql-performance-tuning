USE AdventureWorks2012;

DECLARE @SafetyStockLevel   int = 0
        ,@Uplift            int = 5;

BEGIN TRAN;
SELECT  @SafetyStockLevel = SafetyStockLevel
FROM    Production.Product
WHERE   ProductID = 1;

SET     @SafetyStockLevel = @SafetyStockLevel + @Uplift;

WAITFOR DELAY '00:00:05.000';

UPDATE  Production.Product
SET     SafetyStockLevel = @SafetyStockLevel 
WHERE   ProductID = 1;

SELECT  SafetyStockLevel
FROM    Production.Product
WHERE   ProductID = 1;

COMMIT TRAN;
GO
/*
UPDATE  Production.Product
SET     SafetyStockLevel = 1000 
WHERE   ProductID = 1;
*/
