SELECT * FROM sys.dm_os_spinlock_stats;
GO

SELECT * FROM sys.dm_os_spinlock_stats
WHERE spins > 0
ORDER BY name;
GO

