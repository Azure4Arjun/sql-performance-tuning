SELECT name 
FROM sys.sysobjects -- for SQL Server 2K use sysobjects
WHERE name LIKE 'sp_help%'
ORDER BY name;
GO

EXEC sp_helpdb 'master';
GO

EXEC sp_helpfile 'master'; 
GO

SELECT 
	SERVERPROPERTY('servername') AS 'ServerName'
	,SERVERPROPERTY('Collation') AS 'Collation'
	,SERVERPROPERTY('Edition') AS 'Edition'
	,SERVERPROPERTY('Engine Edition') AS 'EngineEdition' 
	,SERVERPROPERTY('InstanceName') AS 'InstanceName' 
	,SERVERPROPERTY('IsClustered') AS 'Clustered' 
	,SERVERPROPERTY('IsFullTextInstalled') AS 'FullTextInstalled'
	,SERVERPROPERTY('IsIntegratedSecurityOnly') AS 'SeucityMode'
	,SERVERPROPERTY('IsSingleUser') AS 'SingleUser'
	,SERVERPROPERTY('IsSyncWithBackup') AS 'Replication' 
	,SERVERPROPERTY('LicenseType') AS 'LicenseType'
	,SERVERPROPERTY('MachineName') AS 'MachineName'
	,SERVERPROPERTY('NumLicenses') AS 'NumberOfLicenses'
	,SERVERPROPERTY('ProcessID') AS 'WindowsProcessID'
	,SERVERPROPERTY('ProductVersion') AS 'ProductVersion'
	,SERVERPROPERTY('ProductLevel') AS 'ProductLevel';
GO
SELECT
	DATABASEPROPERTY('master', 'IsAnsiNullDefault') AS 'AnsiNullsDefault'
	,DATABASEPROPERTY('master', 'IsAnsiNullsEnabled') AS 'AnsiNullsEnabled' 
	,DATABASEPROPERTY('master', 'IsAnsiWarningsEnabled') AS 'AnsiWarningsEnabled' 
	,DATABASEPROPERTY('master', 'IsAutoClose') AS 'AutoClose' 
	,DATABASEPROPERTY('master', 'IsAutoCreateStatistics') AS 'AutoCreateStats' 
	,DATABASEPROPERTY('master', 'IsAutoShrink') AS 'AutoSchrink' 
	,DATABASEPROPERTY('master', 'IsAutoUpdateStatistics') AS 'AutoUpdateStats' 
	,DATABASEPROPERTY('master', 'IsBulkCopy') AS 'BulkCopyEnabled' 
	,DATABASEPROPERTY('master', 'IsCloseCursorsOnCommitEnabled') AS 'CloseCursorCommit' 
	,DATABASEPROPERTY('master', 'IsDboOnly') AS 'DBOOnlyMode' 
	,DATABASEPROPERTY('master', 'IsDetached') AS 'Detached' 
	,DATABASEPROPERTY('master', 'IsEmergencyMode') AS 'EmergencyMode' 
	,DATABASEPROPERTY('master', 'IsFulltextEnabled') AS 'FullText' 
	,DATABASEPROPERTY('master', 'IsInLoad') AS 'LoadingData' 
	,DATABASEPROPERTY('master', 'IsInRecovery') AS 'InRecoveryMode' 
	,DATABASEPROPERTY('master', 'IsInStandBy') AS 'StandyMode' 
	,DATABASEPROPERTY('master', 'IsLocalCursorsDefault') AS 'LocalCursors' 
	,DATABASEPROPERTY('master', 'IsNotRecovered') AS 'NotRecovered' 
	,DATABASEPROPERTY('master', 'IsNullConcat') AS 'NullConcatentation' 
	,DATABASEPROPERTY('master', 'IsOffline') AS 'OfflineMode' 
	,DATABASEPROPERTY('master', 'IsQuotedIdentifiersEnabled') AS 'QuotedIdentifiers' 
	,DATABASEPROPERTY('master', 'IsReadOnly') AS 'ReadOnlyMode' 
	,DATABASEPROPERTY('master', 'IsRecursiveTriggersEnabled') AS 'RecursiveTriggers' 
	,DATABASEPROPERTY('master', 'IsShutDown') AS 'ShutdownMode' 
	,DATABASEPROPERTY('master', 'IsSingleUser') AS 'SingleUserMode' 
	,DATABASEPROPERTY('master', 'IsSuspect') AS 'MarkedSuspect' 
	,DATABASEPROPERTY('master', 'IsTruncLog') AS 'RecoveryModel'
	,DATABASEPROPERTY('master', 'Version') AS 'Version' 
GO
/* Extended Database Properties */
SELECT 
	DATABASEPROPERTYEX('master', 'Collation') AS 'Collation'
	,DATABASEPROPERTYEX('master', 'IsAnsiPaddingEnabled') AS 'AnsiPadding' 
	,DATABASEPROPERTYEX('master', 'IsArithmeticAbortEnabled') AS 'ArthiAbort' 
	,DATABASEPROPERTYEX('master', 'IsMergePublished') AS 'MergeReplication' 
	,DATABASEPROPERTYEX('master', 'IsNumericRoundAbortEnabled') AS 'NumericRoundAbort' 
	,DATABASEPROPERTYEX('master', 'IsSubscribed') AS 'SubscribedToReplication' 
	,DATABASEPROPERTYEX('master', 'IsTornPageDetectionEnabled') AS 'TornPageDetection' 
	,DATABASEPROPERTYEX('master', 'Recovery') AS 'RecoveryModel' 
	,DATABASEPROPERTYEX('master', 'Status') AS 'Status'
	,DATABASEPROPERTYEX('master', 'Updateability') AS 'UpdateStatus'
	,DATABASEPROPERTYEX('master', 'UserAccess') AS 'UserAccessType'
GO

SELECT * 
FROM sys.sysdatabases;

SELECT * 
FROM sys.filegroups;

SELECT * 
FROM sys.database_files;

SELECT * 
FROM sys.master_files;

SELECT * 
FROM sys.data_spaces;

DBCC TRACESTATUS (-1)
GO
DBCC TRACEON (3604);
GO
DBCC DBINFO ('AdventureWorks')
WITH TABLERESULTS;

DBCC PAGE ('AdventureWorks',1,9,3); --Page 9: the boot page 
DBCC PAGE ('AdventureWorks',1,0,3); --Page 0: the file header page 
DBCC PAGE ('AdventureWorks',1,1,3); --Page 1: the first PFS page 
DBCC PAGE ('AdventureWorks',1,2,3); --Page 2: the first GAM page 
DBCC PAGE ('AdventureWorks',1,3,3); --Page 3: the first SGAM page 
DBCC PAGE ('AdventureWorks',1,6,3); --Page 6: the first DIFF map page 
DBCC PAGE ('AdventureWorks',1,7,3); --Page 7: the first ML map page

