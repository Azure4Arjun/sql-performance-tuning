USE AdventureWorks;
go

-----------------------------------------------------------------------------
-- Session settings
------------------------------------------------------------------------------

CREATE TABLE t1 
(
    a   INT,
    b   AS 2*a
);
go

-- Turn off two required session settings:
SET QUOTED_IDENTIFIER OFF;
SET ANSI_NULLs OFF;
go

-- Attempt to create an index on the computed column (b): 
CREATE INDEX i1 
ON t1 (b);
go

-- Turn quoted_identifier back on:
SET QUOTED_IDENTIFIER ON;
go

-- Attempt to create an index on the computed column (b): 
CREATE INDEX i1 
ON t1 (b);
go

-- Turn ANSI_NULLs back on:
SET ANSI_NULLs ON;
go

-- Finally, success! 
CREATE INDEX i1 
ON t1 (b);
go


-----------------------------------------------------------------------------
-- Deterministic Columns
------------------------------------------------------------------------------

CREATE TABLE t2 
(
    a   INT, 
    b   DATETIME,
    c   AS DATENAME(MM, b)
);
go

-- Attempt to create an index on a nondeterministic column:
CREATE INDEX i2 
ON t2 (c);
go

-- Check the column property for determinism:
SELECT COLUMNPROPERTY (OBJECT_ID('t2'), 'c', 'IsDeterministic');
go

-- Is the column indexable (but not why - if it's not):
SELECT COLUMNPROPERTY (OBJECT_ID('t2'), 'c', 'IsIndexable');
go

-- How about column a:
SELECT COLUMNPROPERTY (OBJECT_ID('t2'), 'a', 'IsIndexable');
go


USE Northwind;
go

-----------------------------------------------------------------------------
-- Attempt to index an imprecise column
------------------------------------------------------------------------------

ALTER TABLE [Order Details]
ADD 
    Final AS (Quantity * UnitPrice) 
                - Discount * (Quantity * UnitPrice);
go

CREATE INDEX OD_Final_Index 
ON [Order Details] (Final);
go

-- To check to see if a computed column must be persisted:
SELECT COLUMNPROPERTY (OBJECT_ID ('Order Details'), 'Final', 'IsPrecise');

-- Instead, if you drop the column and recreate it as a PERSISTED
-- computed column, you can then index it.

ALTER TABLE [Order Details]
DROP COLUMN Final;
go

ALTER TABLE [Order Details]
ADD 
    Final AS (Quantity * UnitPrice) 
                - Discount * (Quantity * UnitPrice) PERSISTED;
go

CREATE INDEX OD_Final_Index 
ON [Order Details](Final);
go
