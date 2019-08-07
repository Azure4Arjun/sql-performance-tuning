/*

	Training:	Optimizing and Troubleshooting
	Module:		02 - Transaction Log
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/
USE [master];
GO

SET NOCOUNT ON;
GO

-- Start the long-running transaction
BEGIN TRAN;
GO

INSERT INTO [DBTranLog].[dbo].[BigTable] DEFAULT VALUES;
GO 1000

-- Now switch-back...

COMMIT TRAN;
GO

