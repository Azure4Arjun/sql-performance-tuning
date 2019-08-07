USE master;
GO

-- Corrupt IAM chain for sys.syshobts
--
DBCC CHECKDB (DemoFatalCorruption1)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO

-- Corruption found by the metadata layer
-- of the Engine
DBCC CHECKDB (DemoFatalCorruption2)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO
