USE SparseColumnsTest
GO

-- Index to find all rows with non NULL c6
-- Non-filtered index in the Non-sparse document
-- repository
-- Note: DocId is the clustered index key so will
-- be covered by this index too
-- Note: Only need to INCLUDE c6 as it's not a key
CREATE NONCLUSTERED INDEX TestIndex 
ON dbo.NonSparseDocRepository (DocType)
INCLUDE (c6)

-- Filtered index in the Non-sparse repository
CREATE NONCLUSTERED INDEX TestFilteredIndex 
ON dbo.NonSparseDocRepository (DocType)
INCLUDE (c6)
WHERE c6 IS NOT NULL

-- Non-filtered index in the sparse repository
CREATE NONCLUSTERED INDEX TestIndexSparse 
ON dbo.SparseDocRepository (DocType)
INCLUDE (c6)

-- Filtered index in sparse directory
CREATE NONCLUSTERED INDEX TestFilteredIndexSparse 
ON dbo.SparseDocRepository (DocType)
INCLUDE (c6)
WHERE c6 IS NOT NULL

-- Create some rows with c6 set
UPDATE NonSparseDocRepository
SET c6 = 1 WHERE DocId IN (43, 45676, 3339);
UPDATE SparseDocRepository
SET c6 = 1 WHERE DocId IN (43, 45676, 3339);
GO

-- See how large all the indexes are
SELECT OBJECT_NAME(object_id), name, INDEX_ID
FROM sys.indexes
WHERE OBJECT_NAME(object_id) = 'SparseDocRepository'
	OR OBJECT_NAME(object_id) = 'NonSparseDocRepository';

SELECT OBJECT_NAME (object_id), index_id, page_count
FROM sys.dm_db_index_physical_stats (
	db_id(), null, null, null, 'limited');
GO

-- You can see that the filtered index on the sparse and
-- non-sparse document repositories are the same size
