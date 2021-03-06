USE tempdb
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SQLIO_Import](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[ParameterRowID] [int] NULL,
	[ResultText] [varchar](max) NULL,
 CONSTRAINT [PK_SQLIO_Import] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
))
GO
CREATE TABLE [dbo].[SQLIO_TestPass](
	[TestPassID] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [nvarchar](50) NOT NULL,
	[DriveQty] [int] NOT NULL,
	[DriveRPM] [int] NOT NULL,
	[DriveRaidLevel] [nvarchar](10) NOT NULL,
	[TestDate] [datetime] NOT NULL,
	[SANmodel] [nvarchar](50) NOT NULL,
	[SANfirmware] [nvarchar](50) NULL,
	[PartitionOffset] [int] NULL,
	[Filesystem] [nvarchar](50) NULL,
	[FSClusterSizeBytes] [int] NULL,
	[SQLIO_Version] [nvarchar](20) NULL,
	[Threads] [int] NULL,
	[ReadOrWrite] [nchar](1) NULL,
	[DurationSeconds] [int] NULL,
	[SectorSizeKB] [int] NULL,
	[IOpattern] [nvarchar](50) NULL,
	[IOsOutstanding] [int] NULL,
	[Buffering] [nvarchar](50) NULL,
	[FileSizeMB] [int] NULL,
	[IOs_Sec] [decimal](18, 0) NULL,
	[MBs_Sec] [decimal](18, 0) NULL,
	[LatencyMS_Min] [int] NULL,
	[LatencyMS_Avg] [int] NULL,
	[LatencyMS_Max] [int] NULL,
 CONSTRAINT [PK_SQLIO_TestPass] PRIMARY KEY CLUSTERED 
(
	[TestPassID] ASC
))
GO

CREATE PROCEDURE [dbo].[USP_Import_SQLIO_TestPass]
                @ServerName         NVARCHAR(50),
                @DriveQty           INT,
                @DriveRPM           INT,
                @DriveRaidLevel     NVARCHAR(10),
                @TestDate           DATETIME,
                @SANmodel           NVARCHAR(50),
                @SANfirmware        NVARCHAR(50),
                @PartitionOffset    INT,
                @Filesystem         NVARCHAR(50),
                @FSClusterSizeBytes INT
AS
  SET nocount off
  
  IF @TestDate IS NULL
    SET @TestDate = Getdate()

  /* Add a blank record to the end so the last test result is captured */
  INSERT INTO dbo.SQLIO_Import
    (ParameterRowID, 
     ResultText)
  VALUES
    (0,
     '');
                               
  /* Update the ParameterRowID field for easier querying */
  UPDATE dbo.sqlio_import
  SET    parameterrowid = (SELECT   TOP 1 rowid
                           FROM     dbo.sqlio_import parm
                           WHERE    parm.resulttext LIKE '%\%'
                                    AND parm.rowid <= upd.rowid
                           ORDER BY rowid DESC)
  FROM   dbo.sqlio_import upd
         
  /* Add new SQLIO_TestPass records from SQLIO_Import */
  INSERT INTO dbo.sqlio_testpass
             (servername,
              driveqty,
              driverpm,
              driveraidlevel,
              testdate,
              sanmodel,
              sanfirmware,
              partitionoffset,
              filesystem,
              fsclustersizebytes,
              sqlio_version,
              threads,
              readorwrite,
              durationseconds,
              sectorsizekb,
              iopattern,
              iosoutstanding,
              buffering,
              filesizemb,
              ios_sec,
              mbs_sec,
              latencyms_min,
              latencyms_avg,
              latencyms_max)
  SELECT   @ServerName,
           @DriveQty,
           @DriveRPM,
           @DriveRaidLevel,
           @TestDate,
           @SANmodel,
           @SANfirmware,
           @PartitionOffset,
           @Filesystem,
           @FSClusterSizeBytes,
           (SELECT REPLACE(resulttext,'sqlio ','')
            FROM   dbo.sqlio_import impsqlio_version
            WHERE  imp.rowid + 1 = impsqlio_version.rowid) AS sqlio_version,
           (SELECT LEFT(resulttext,(Charindex(' threads',resulttext)))
            FROM   dbo.sqlio_import impthreads
            WHERE  imp.rowid + 3 = impthreads.rowid) AS threads,
           (SELECT Upper(Substring(resulttext,(Charindex('threads ',resulttext)) + 8,
                                   1))
            FROM   dbo.sqlio_import impreadorwrite
            WHERE  imp.rowid + 3 = impreadorwrite.rowid) AS readorwrite,
           (SELECT Substring(resulttext,(Charindex(' for',resulttext)) + 4,
                             (Charindex(' secs ',resulttext)) - (Charindex(' for',resulttext)) - 4)
            FROM   dbo.sqlio_import impdurationseconds
            WHERE  imp.rowid + 3 = impdurationseconds.rowid) AS durationseconds,
           (SELECT Substring(resulttext,7,(Charindex('KB',resulttext)) - 7)
            FROM   dbo.sqlio_import impsectorsizekb
            WHERE  imp.rowid + 4 = impsectorsizekb.rowid) AS sectorsizekb,
           (SELECT Substring(resulttext,(Charindex('KB ',resulttext)) + 3,
                             (Charindex(' IOs',resulttext)) - (Charindex('KB ',resulttext)) - 3)
            FROM   dbo.sqlio_import impiopattern
            WHERE  imp.rowid + 4 = impiopattern.rowid) AS iopattern,
           (SELECT Substring(resulttext,(Charindex('with ',resulttext)) + 5,
                             (Charindex(' outstanding',resulttext)) - (Charindex('with ',resulttext)) - 5)
            FROM   dbo.sqlio_import impiosoutstanding
            WHERE  imp.rowid + 5 = impiosoutstanding.rowid) AS iosoutstanding,
           (SELECT REPLACE(CAST(resulttext AS NVARCHAR(50)),'buffering set to ',
                           '')
            FROM   dbo.sqlio_import impbuffering
            WHERE  imp.rowid + 6 = impbuffering.rowid) AS buffering,
           (SELECT Substring(resulttext,(Charindex('size: ',resulttext)) + 6,
                             (Charindex(' for ',resulttext)) - (Charindex('size: ',resulttext)) - 9)
            FROM   dbo.sqlio_import impfilesizemb
            WHERE  imp.rowid + 7 = impfilesizemb.rowid) AS filesizemb,
           (SELECT RIGHT(resulttext,(Len(resulttext) - 10))
            FROM   dbo.sqlio_import impios_sec
            WHERE  imp.rowid + 11 = impios_sec.rowid) AS ios_sec,
           (SELECT RIGHT(resulttext,(Len(resulttext) - 10))
            FROM   dbo.sqlio_import impmbs_sec
            WHERE  imp.rowid + 12 = impmbs_sec.rowid) AS mbs_sec,
           (SELECT RIGHT(resulttext,(Len(resulttext) - 17))
            FROM   dbo.sqlio_import implatencyms_min
            WHERE  imp.rowid + 14 = implatencyms_min.rowid) AS latencyms_min,
           (SELECT RIGHT(resulttext,(Len(resulttext) - 17))
            FROM   dbo.sqlio_import implatencyms_avg
            WHERE  imp.rowid + 15 = implatencyms_avg.rowid) AS latencyms_avg,
           (SELECT RIGHT(resulttext,(Len(resulttext) - 17))
            FROM   dbo.sqlio_import implatencyms_max
            WHERE  imp.rowid + 16 = implatencyms_max.rowid) AS latencyms_max
  FROM     dbo.sqlio_import imp
           INNER JOIN dbo.sqlio_import impfulltest
             ON imp.rowid + 20 = impfulltest.rowid
                AND impfulltest.resulttext = ''
  WHERE    imp.rowid = imp.parameterrowid
           /*AND (SELECT Substring(resulttext,(Charindex('size: ',resulttext)) + 6,
                                 (Charindex(' for ',resulttext)) - (Charindex('size: ',resulttext)) - 9)
                FROM   dbo.sqlio_import impfilesizemb
                WHERE  imp.rowid + 7 = impfilesizemb.rowid) > 0 */
  ORDER BY imp.parameterrowid
           
  /* Empty out the ETL table */
  DELETE dbo.sqlio_import
         
  SET nocount off
GO


/*
�In SQL Server Management Studio, right-click on the database where you want to store the SQLIO performance data and click Tasks, Import Data.
�For Data Source, choose "Flat File Source". Browse to your results.txt file, and set the Format to Delimited, Text Qualifier to None, Header row delimiter to {CR}{LF}, and Header Rows to Skip to 0.
�Click on the Advanced tab on the left, and there should only be one column, Column 0. Set the DataType to text stream. Click Next.
�Your database server and storage database should be shown. Click Next.
�For the Destination Table, choose SQLIO_Import and click Edit Mappings. Set the Column 0 destination to be ResultText. Click OK, and click Next.
�Click Next until the wizard finishes and imports the data, and then close the wizard.
*/

--Sample execution
EXECUTE [dbo].[USP_Import_SQLIO_TestPass] 
   'MyServerName'
  ,10
  ,15000
  ,'RAID 10'
  ,'2008/5/6'
  ,'IBM DS4800'
  ,'6.62'
  ,1024
  ,'NTFS'
  ,'64000'
GO


SELECT * 
FROM dbo.SQLIO_TestPass 
ORDER BY MBs_Sec DESC