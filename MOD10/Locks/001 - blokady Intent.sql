USE AdventureWorks2012;

BEGIN TRANSACTION;
UPDATE  Production.Product 
SET     SafetyStockLevel = SafetyStockLevel
WHERE   ProductID =1;
--ROLLBACK TRAN;

SELECT   resource_type
        ,resource_subtype 
        ,resource_description
        ,resource_associated_entity_id
        ,request_mode
        ,request_status
FROM    sys.dm_tran_locks
WHERE   request_session_id = @@spid;
GO