/*

	Training:	Optimizing and Troubleshooting
	Module:		01 - Internal Structure and Functioning SQL Server
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/
-- Server configurations
SELECT * FROM sys.configurations
GO

EXEC sys.sp_configure N'show advanced options', N'1'  
RECONFIGURE WITH OVERRIDE
GO

EXEC sys.sp_configure N'cost threshold for parallelism', N'10'
GO
RECONFIGURE WITH OVERRIDE
GO

SELECT * FROM sys.dm_os_server_diagnostics_log_configurations;
GO
--- Continued after DMV