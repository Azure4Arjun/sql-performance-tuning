USE master;
GO


-- Check consistency
DBCC CHECKDB (DemoCorruptMetadata)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO















-- Try to repair...
ALTER DATABASE DemoCorruptMetadata SET SINGLE_USER;
GO
DBCC CHECKDB (DemoCorruptMetadata, REPAIR_ALLOW_DATA_LOSS)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO
ALTER DATABASE DemoCorruptMetadata SET MULTI_USER;
GO




















-- Ok - can we hack the system tables?
--
SELECT name FROM DemoCorruptMetadata.sys.objects;
GO

-- Hmm - narrow it down a bit
--
SELECT name FROM DemoCorruptMetadata.sys.objects
WHERE name LIKE '%col%';
GO












-- Try one...
SELECT * FROM DemoCorruptMetadata.sys.sysrowsetcolumns
WHERE 1 = 0;
GO







-- Check it worked...
DBCC CHECKDB (DemoCorruptMetadata)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO





-- ok - we can't bind to or change the system tables in 2005
-- UNLESS we use the Dedicated Admin Connection AND
-- single_user mode...
-- Documented in MSDN
-- http://msdn.microsoft.com/en-us/library/ms179503.aspx
-- http://forums.microsoft.com/MSDN/ShowPost.aspx?PostID=89594&SiteID=1


-- CMD window

-- Check it worked...
DBCC CHECKDB (DemoCorruptMetadata)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO






















-- DAC commands

SELECT * FROM sys.sysrowsetcolumns WHERE 1 = 0;
GO
SELECT * FROM sys.syshobtcolumns WHERE 1 = 0;
GO
SELECT * FROM sys.syscolpars WHERE 1 = 0;
GO




DELETE FROM sys.syscolpars WHERE id = 1977058079


USE master;
GO
ALTER DATABASE DemoCorruptMetadata
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

ALTER DATABASE AdventureWorks2012
SET MULTI_USER;
GO

-- do it again with the SERVER in single-user mode

