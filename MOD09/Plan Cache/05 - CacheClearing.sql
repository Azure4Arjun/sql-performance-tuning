CHECKPOINT				--writes dirty pages to disk
DBCC FREEPROCCACHE		--clears entire plan cache
DBCC DROPCLEANBUFFERS	--clears all clean data cache pages

DECLARE @DBID	smallint
SELECT @DBID = db_id('AdventureWorks')
DBCC FLUSHPROCINDB(@DBID)	--clears all clean plan cache for specified database
GO

USE AdventureWorks;
GO

DBCC FREESYSTEMCACHE ('SQL Plans')
DBCC FREESYSTEMCACHE ('Bound Trees')
DBCC FREESYSTEMCACHE('TokenAndPermUserStore')
GO

SELECT * FROM Person.Address;
GO

SELECT plan_handle, st.text
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE text LIKE N'SELECT * FROM Person.Address%';

DBCC FREEPROCCACHE	(0x060008001ECA270E003B1DEA0100000001000000000000000000000000000000000000000000000000000000)
GO


