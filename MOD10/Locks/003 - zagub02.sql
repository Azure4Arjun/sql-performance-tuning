USE AdventureWorks2012;

DECLARE @SafetyStockLevel   int = 0
        ,@Uplift            int = 100;

BEGIN TRAN;
SELECT  @SafetyStockLevel = SafetyStockLevel
FROM    Production.Product
WHERE   ProductID = 1;

SET     @SafetyStockLevel = @SafetyStockLevel + @Uplift;

UPDATE  Production.Product
SET     SafetyStockLevel = @SafetyStockLevel 
WHERE   ProductID = 1;

SELECT  SafetyStockLevel
FROM    Production.Product
WHERE   ProductID = 1;

COMMIT TRAN;