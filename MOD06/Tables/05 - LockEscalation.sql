USE master;
GO

IF DB_ID('LockEscalationTest') IS NOT NULL 
	DROP DATABASE LockEscalationTest;
GO

CREATE DATABASE LockEscalationTest;
GO

USE LockEscalationTest;
GO

-- Create three partitions: -7999, 8000-15999, 16000+
CREATE PARTITION FUNCTION MyPartitionFunction (INT)
AS RANGE RIGHT FOR VALUES (8000, 16000);
GO

CREATE PARTITION SCHEME MyPartitionScheme
AS PARTITION MyPartitionFunction
ALL TO ([PRIMARY]);
GO

-- Create a partitioned table
CREATE TABLE MyPartitionedTable (c1 INT);
GO

CREATE CLUSTERED INDEX MPT_Clust ON MyPartitionedTable (c1)
ON MyPartitionScheme (c1);
GO

-- Fill the table
SET NOCOUNT ON;
GO

DECLARE @a INT = 1;
WHILE (@a < 17000)
BEGIN
	INSERT INTO MyPartitionedTable VALUES (@a);
	SELECT @a = @a + 1;
END;
GO

USE LockEscalationTest;
GO

-- Show how fast the partition 3 query is
SELECT COUNT (*) 
FROM MyPartitionedTable
WHERE c1 >= 16000;
GO

-- Cause escalation by updating 7500 rows from
-- partition 1 in a single transaction
BEGIN TRAN
UPDATE MyPartitionedTable 
SET c1 = c1 
WHERE c1 < 7500
GO

-- Session 2 tries querying partition 3
USE LockEscalationTest;
GO
SELECT COUNT (*) 
FROM MyPartitionedTable
WHERE c1 >= 16000;
GO

-- Check the locks being held...
USE LockEscalationTest;
GO
SELECT * FROM sys.partitions 
WHERE object_id = OBJECT_ID ('MyPartitionedTable');
GO

SELECT * 
FROM sys.dm_tran_locks
WHERE [resource_type] <> 'DATABASE';
GO


--Session 1
ROLLBACK TRAN;
GO

-- Specifically set lock escalation to be AUTO to
-- allow partition level escalation
ALTER TABLE MyPartitionedTable
SET (LOCK_ESCALATION = AUTO);

-- Cause escalation by updating 7500 rows from
-- partition 1 in a single transaction
BEGIN TRAN
UPDATE MyPartitionedTable 
SET c1 = c1 
WHERE c1 < 7500
GO

-- Try querying partition 3 again

-- Check the locks being held...

-- Cause escalation to another partition X lock by
-- updating all rows from partition 2 in a single
-- transaction
USE LockEscalationTest;
GO

BEGIN TRAN
UPDATE MyPartitionedTable 
SET c1 = c1
WHERE c1 > 8000 AND c1 < 16000;
GO

-- Check the locks being held...


-- Use this to cause a deadlock
-- Selects a row from partition 1 while that partition
-- is X locked

SELECT * 
FROM MyPartitionedTable 
WHERE c1 = 100;
GO


-- Use this to cause a deadlock
-- Selects a row from partition 2 while it is X locked.
SELECT * 
FROM MyPartitionedTable 
WHERE c1 = 8500;
GO

ROLLBACK TRAN;