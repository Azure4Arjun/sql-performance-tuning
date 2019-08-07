/*

	Training:	Optimizing and Troubleshooting
	Module:		01 - Internal Structure and Functioning SQL Server
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/
-- EDNPOINTS
SELECT * FROM sys.endpoints;
GO

SELECT * FROM sys.dm_tcp_listener_states;
GO

-- Executions - All connections
SELECT * FROM sys.dm_exec_connections;
GO

SELECT * FROM sys.dm_os_hosts;
GO





