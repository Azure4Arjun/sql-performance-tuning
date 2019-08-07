-- Run a CHECKDB
DBCC CHECKDB (DemoNCIndex)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO


-- Is it just non-clustered indexes?
-- Scan through all the errors looking for index IDs
-- Maybe use WITH TABLERESULTS?
DBCC CHECKDB (DemoNCIndex)
WITH NO_INFOMSGS, ALL_ERRORMSGS, TABLERESULTS;
GO

-- If you wanted to fix them with CHECKDB, it
-- may do single row repairs or rebuild the index,
-- depending on the error.
DBCC CHECKDB (DemoNCIndex, REPAIR_REBUILD)
WITH NO_INFOMSGS, ALL_ERRORMSGS, TABLERESULTS;
GO













-- You need to be in SINGLE_USER mode! Just to
-- fix non-clustered indexes.
--
-- That doesn't make sense. Just rebuild them
-- manually and keep the database online. Try an
-- online rebuild...
USE DemoNCIndex
GO
EXEC sp_HelpIndex 'Customers';
GO

ALTER INDEX - ON Customers REBUILD
WITH (ONLINE = ON);
GO

-- And check again...
DBCC CHECKDB (DemoNCIndex)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO

















-- Didn't work! Online index rebuild scans
-- the old index...
-- Offline rebuild doesn't...
ALTER INDEX CustomerName ON Customers REBUILD;
GO

DBCC CHECKDB (DemoNCIndex)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO