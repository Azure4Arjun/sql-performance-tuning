USE ProcessTraceFiles;
GO

SET NOCOUNT ON;
GO
/*
CREATE TABLE AggregatedData
        ( [DBRevision] int,
          [RunDate] datetime,
          [PartialText] varchar(max),
          [Duration] int,
          [Reads] int,
          [Writes] int,
          [CPU] int,
		  [RowCounts] int,
          RunNumber int
        )

*/
/*Put trace data into a temp table for processing.  TextData needs to be converted to a VARCHAR(max) before PATINDEX AND CHARINDEX can be used. */

SELECT [RowNumber] ,CAST([TextData]AS VARCHAR(MAX)) AS TextData
      ,[BinaryData] ,[DatabaseID],[TransactionID],[LineNumber],[NTUserName]
      ,[NTDomainName],[HostName],[ClientProcessID],[ApplicationName],[LoginName]
      ,[SPID] ,[Duration],[StartTime],[EndTime],[Reads],[Writes],[CPU],[Permissions]
      ,[Severity],[EventSubClass],[ObjectID],[Success],[IndexID],[IntegerData],[ServerName]
      ,[EventClass] ,[ObjectType] ,[NestLevel] ,[State] ,[Error],[Mode] ,[Handle]
      ,[ObjectName] ,[DatabaseName],[FileName],[OwnerName],[RoleName],[TargetUserName]
      ,[DBUserName] ,[LoginSid] ,[TargetLoginName] ,[TargetLoginSid],[ColumnPermissions]
      ,[LinkedServerName],[ProviderName],[MethodName],[RowCounts],[RequestID]
      ,[XactSequence],[EventSequence] ,[BigintData1] ,[BigintData2] ,[GUID] ,[IntegerData2]
      ,[ObjectID2],[Type],[OwnerID],[ParentName],[IsSystem],[Offset] ,[SourceDatabaseID]
      ,[SqlHandle] ,[SessionLoginName],[PlanHandle] 
INTO #TestTable

 /* ---------------------------------------------------------
  
  Change the table name, the dbRevision, and the runNumber 
  
 --------------------------------------------------------- */

  FROM TestTrace;
 
DECLARE @DBRevision AS SMALLINT;
SET @DBRevision = 10195;
DECLARE @RunNumber AS SMALLINT; 
SET @RunNumber= 1;
/* --------------------------------------------------------- */


 
DECLARE @RunDate AS DATETIME
SELECT  @RunDate = MIN(StartTime)
FROM   #TestTable;

/* Display Run information for reference */

PRINT @RunDate

/* Extract stored procedure calls */

INSERT  INTO AggregatedData
        ( [DBRevision] ,
          [RunDate] ,
          [PartialText] ,
          [Duration] ,
          [Reads] ,
          [Writes] ,
          [CPU] ,
		  [RowCounts],
          RunNumber 
        )
        SELECT  @DBRevision AS DBRevision ,
                @RunDate AS RunDate ,
                SUBSTRING(TextData, ( PATINDEX('%EXEC %', textData) ),
                          ( CHARINDEX(CHAR(32), TextData,
                                      ( PATINDEX('%EXEC %', textData) ) + 5) )
                          - ( PATINDEX('%EXEC %', textData) )) AS PartialText ,
                COALESCE(duration, 0) AS duration ,
                COALESCE(reads, 0) AS reads ,
                COALESCE(writes, 0) AS writes ,
                COALESCE(cpu, 0) AS cpu ,
				 COALESCE(RowCounts, 0) AS RowCounts ,
                @RunNumber AS DBRevision
        
        FROM    #TestTable

        WHERE   PATINDEX('%EXEC %', TextData) > 0
                AND EventClass IN ( 10, 12 )
               
          
/* Extract BULK INSERTS and Adhoc SQL */

INSERT  INTO AggregatedData
        ( [DBRevision] ,
          [RunDate] ,
          [PartialText] ,
          [Duration] ,
          [Reads] ,
          [Writes] ,
          [CPU] ,
		  [RowCounts],
          RunNumber 
        )
        SELECT  @DBRevision AS DBRevision ,
                @RunDate AS RunDate ,
                 SUBSTRING(TextData, 0,100) AS PartialText ,
                COALESCE(duration, 0) AS duration ,
                COALESCE(reads, 0) AS reads ,
                COALESCE(writes, 0) AS writes ,
                COALESCE(cpu, 0) AS cpu ,
				COALESCE(RowCounts, 0) AS RowCounts ,
                @RunNumber AS DBRevision

        FROM    #TestTable
        WHERE   PATINDEX('%EXEC %', TextData) = 0
                AND EventClass IN ( 10, 12 )

/* Extract sp_executesql */

INSERT  INTO AggregatedData
        ( 
          [DBRevision] ,
          [RunDate] ,
          [PartialText] ,
          [Duration] ,
          [Reads] ,
          [Writes] ,
          [CPU] ,
		  [RowCounts],
          RunNumber 
        )
        SELECT   @DBRevision AS DBRevision ,
                @RunDate AS RunDate ,
                 SUBSTRING(TextData, 0,100) AS PartialText ,
                COALESCE(duration, 0) AS duration ,
                COALESCE(reads, 0) AS reads ,
                COALESCE(writes, 0) AS writes ,
                COALESCE(cpu, 0) AS cpu ,
				COALESCE(RowCounts, 0) AS RowCounts ,
                @RunNumber AS DBRevision

        FROM    #TestTable
        WHERE   PATINDEX('%sp_executesql%', TextData) > 0
                AND EventClass IN ( 10, 12 )                 



/* Clean Up */
DROP TABLE #TestTable;

SELECT * FROM AggregatedData;      



-- Aggregate trace data by query
SELECT
  PartialText,
  SUM(Duration) AS total_duration
FROM dbo.AggregatedData
GROUP BY PartialText;

-- Query Signature

-- Query template
DECLARE @my_templatetext AS NVARCHAR(MAX);
DECLARE @my_parameters   AS NVARCHAR(MAX);

EXEC sp_get_query_template 
  N'SELECT * FROM dbo.T1 WHERE col1 = 3 AND col2 > 78',
  @my_templatetext OUTPUT,
  @my_parameters OUTPUT;

SELECT @my_templatetext AS querysig, @my_parameters AS params;
GO

IF OBJECT_ID('dbo.fn_SQLSigTSQL') IS NOT NULL
  DROP FUNCTION dbo.fn_SQLSigTSQL;
GO

CREATE FUNCTION dbo.fn_SQLSigTSQL 
  (@p1 NTEXT, @parselength INT = 4000)
RETURNS NVARCHAR(4000)

--
-- This function is provided "AS IS" with no warranties,
-- and confers no rights. 
-- Use of included script samples are subject to the terms specified at
-- http://www.microsoft.com/info/cpyright.htm
-- 
-- Strips query strings
AS
BEGIN 
  DECLARE @pos AS INT;
  DECLARE @mode AS CHAR(10);
  DECLARE @maxlength AS INT;
  DECLARE @p2 AS NCHAR(4000);
  DECLARE @currchar AS CHAR(1), @nextchar AS CHAR(1);
  DECLARE @p2len AS INT;

  SET @maxlength = LEN(RTRIM(SUBSTRING(@p1,1,4000)));
  SET @maxlength = CASE WHEN @maxlength > @parselength 
                     THEN @parselength ELSE @maxlength END;
  SET @pos = 1;
  SET @p2 = '';
  SET @p2len = 0;
  SET @currchar = '';
  set @nextchar = '';
  SET @mode = 'command';

  WHILE (@pos <= @maxlength)
  BEGIN
    SET @currchar = SUBSTRING(@p1,@pos,1);
    SET @nextchar = SUBSTRING(@p1,@pos+1,1);
    IF @mode = 'command'
    BEGIN
      SET @p2 = LEFT(@p2,@p2len) + @currchar;
      SET @p2len = @p2len + 1 ;
      IF @currchar IN (',','(',' ','=','<','>','!')
        AND @nextchar BETWEEN '0' AND '9'
      BEGIN
        SET @mode = 'number';
        SET @p2 = LEFT(@p2,@p2len) + '#';
        SET @p2len = @p2len + 1;
      END 
      IF @currchar = ''''
      BEGIN
        SET @mode = 'literal';
        SET @p2 = LEFT(@p2,@p2len) + '#''';
        SET @p2len = @p2len + 2;
      END
    END
    ELSE IF @mode = 'number' AND @nextchar IN (',',')',' ','=','<','>','!')
      SET @mode= 'command';
    ELSE IF @mode = 'literal' AND @currchar = ''''
      SET @mode= 'command';

    SET @pos = @pos + 1;
  END
  RETURN @p2;
END
GO

-- Test fn_SQLSigTSQL Function
SELECT dbo.fn_SQLSigTSQL
  (N'SELECT * FROM dbo.T1 WHERE col1 = 3 AND col2 > 78', 4000);
GO

-- fn_SQLSigCLR and fn_RegexReplace Functions, C# Version
/*
using System.Text;
using Microsoft.SqlServer.Server;
using System.Data.SqlTypes;
using System.Text.RegularExpressions;

public partial class SQLSignature
{
    // fn_SQLSigCLR
    [SqlFunction(IsDeterministic = true, DataAccess = DataAccessKind.None)]
    public static SqlString fn_SQLSigCLR(SqlString querystring)
    {
        return (SqlString)Regex.Replace(
            querystring.Value,
            @"([\s,(=<>!](?![^\]]+[\]]))(?:(?:(?:(?#    expression coming
             )(?:([N])?(')(?:[^']|'')*('))(?#           character
             )|(?:0x[\da-fA-F]*)(?#                     binary
             )|(?:[-+]?(?:(?:[\d]*\.[\d]*|[\d]+)(?#     precise number
             )(?:[eE]?[\d]*)))(?#                       imprecise number
             )|(?:[~]?[-+]?(?:[\d]+))(?#                integer
             ))(?:[\s]?[\+\-\*\/\%\&\|\^][\s]?)?)+(?#   operators
             ))",
            @"$1$2$3#$4");
    }

    // fn_RegexReplace - for generic use of RegEx-based replace
    [SqlFunction(IsDeterministic = true, DataAccess = DataAccessKind.None)]
    public static SqlString fn_RegexReplace(
        SqlString input, SqlString pattern, SqlString replacement)
    {
        return (SqlString)Regex.Replace(
            input.Value, pattern.Value, replacement.Value);
    }
}
*/

-- Enable CLR
EXEC sp_configure 'clr enable', 1;
RECONFIGURE;
GO

-- Create assembly 
CREATE ASSEMBLY SQLSignature
FROM 'e:\SQLSignature.dll';
GO

-- Create fn_SQLSigCLR and fn_RegexReplace functions
CREATE FUNCTION dbo.fn_SQLSigCLR(@querystring AS NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
WITH RETURNS NULL ON NULL INPUT 
EXTERNAL NAME SQLSignature.SQLSignature.fn_SQLSigCLR;
GO

CREATE FUNCTION dbo.fn_RegexReplace(
  @input       AS NVARCHAR(MAX),
  @pattern     AS NVARCHAR(MAX),
  @replacement AS NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
WITH RETURNS NULL ON NULL INPUT 
EXTERNAL NAME SQLSignature.SQLSignature.fn_RegexReplace;
GO

-- Return trace data with query signature
SELECT
  dbo.fn_SQLSigCLR(PartialText) AS sig,
  Duration
FROM dbo.AggregatedData;

SELECT 
  dbo.fn_RegexReplace(PartialText,
    N'([\s,(=<>!](?![^\]]+[\]]))(?:(?:(?:(?#    expression coming
     )(?:([N])?('')(?:[^'']|'''')*(''))(?#      character
     )|(?:0x[\da-fA-F]*)(?#                     binary
     )|(?:[-+]?(?:(?:[\d]*\.[\d]*|[\d]+)(?#     precise number
     )(?:[eE]?[\d]*)))(?#                       imprecise number
     )|(?:[~]?[-+]?(?:[\d]+))(?#                integer
     ))(?:[\s]?[\+\-\*\/\%\&\|\^][\s]?)?)+(?#   operators
     ))',
    N'$1$2$3#$4') AS sig,
  duration
FROM dbo.AggregatedData;
