exec sp_configure 'show advanced options',1;
reconfigure;
go
exec sp_configure 'blocked process threshold', 20;
reconfigure;
