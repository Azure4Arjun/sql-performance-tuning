/* Create a Queue*/
DECLARE @rc INT;
DECLARE @TraceID INT;
DECLARE @maxfilesize BIGINT ;
SET @maxfilesize = 256;

/*INSERT YOUR DB NAME BELOW IN THE SINGLE QUOTES*/
DECLARE @dbName VARCHAR(50) ;
SET @dbName = 'AdventureWorks';

DECLARE @DateTime datetime;
SET @DateTime = GETDATE();
SET @DateTime = DATEADD(hh,1,@DateTime)

DECLARE @database_id INT; 
SET @database_id = DB_ID(@dbName);


DECLARE @filename NVARCHAR(100);

/*

Change the path and filename prefix on the next line, if necessary.  Also, make sure you're writing to a drive with plenty of room.
If the "C:\SQL\" path does not exist 
you will get this error:
Windows error occurred while running SP_TRACE_CREATE. Error = 0x80070003(The system cannot find the path specified.).

*/

SET @filename = N'C:\SQL\' + @dbname + '_' + CONVERT(VARCHAR(12), GETDATE(), 112)
    + '-' + LEFT(CONVERT(VARCHAR(8), GETDATE(), 108), 2)
    + SUBSTRING(CONVERT(VARCHAR(8), GETDATE(), 108), 4, 2)
    
PRINT @filename


/*
	sp_trace_create [ @traceid = ] trace_id OUTPUT 
          , [ @options = ] option_value 
          , [ @tracefile = ] 'trace_file' 
     [ , [ @maxfilesize = ] max_file_size ]
     [ , [ @stoptime = ] 'stop_time' ]
     [ , [ @filecount = ] 'max_rollover_files' ]
*/

EXEC @rc = sp_trace_create @TraceID OUTPUT, 2, @filename, @maxfilesize, @DateTime; 




IF (@rc != 0) 
   GOTO error

/* Set the events*/
DECLARE @on BIT
SET @on = 1
EXEC sp_trace_setevent @TraceID, 10, 15, @on
EXEC sp_trace_setevent @TraceID, 10, 16, @on
EXEC sp_trace_setevent @TraceID, 10, 48, @on
EXEC sp_trace_setevent @TraceID, 10, 1, @on
EXEC sp_trace_setevent @TraceID, 10, 17, @on
EXEC sp_trace_setevent @TraceID, 10, 10, @on
EXEC sp_trace_setevent @TraceID, 10, 18, @on
EXEC sp_trace_setevent @TraceID, 10, 3, @on
EXEC sp_trace_setevent @TraceID, 10, 11, @on
EXEC sp_trace_setevent @TraceID, 10, 35, @on
EXEC sp_trace_setevent @TraceID, 10, 12, @on
EXEC sp_trace_setevent @TraceID, 10, 13, @on
EXEC sp_trace_setevent @TraceID, 10, 6, @on
EXEC sp_trace_setevent @TraceID, 10, 14, @on
EXEC sp_trace_setevent @TraceID, 10, 4, @on

EXEC sp_trace_setevent @TraceID, 12, 15, @on
EXEC sp_trace_setevent @TraceID, 12, 16, @on
EXEC sp_trace_setevent @TraceID, 12, 48, @on
EXEC sp_trace_setevent @TraceID, 12, 1, @on
EXEC sp_trace_setevent @TraceID, 12, 17, @on
EXEC sp_trace_setevent @TraceID, 12, 6, @on
EXEC sp_trace_setevent @TraceID, 12, 10, @on
EXEC sp_trace_setevent @TraceID, 12, 14, @on
EXEC sp_trace_setevent @TraceID, 12, 18, @on
EXEC sp_trace_setevent @TraceID, 12, 3, @on
EXEC sp_trace_setevent @TraceID, 12, 11, @on
EXEC sp_trace_setevent @TraceID, 12, 35, @on
EXEC sp_trace_setevent @TraceID, 12, 12, @on
EXEC sp_trace_setevent @TraceID, 12, 13, @on
EXEC sp_trace_setevent @TraceID, 12, 4, @on

/*GetDeadlock Information*/
EXEC sp_trace_setevent @TraceID, 148, 11, @on
EXEC sp_trace_setevent @TraceID, 148, 12, @on
EXEC sp_trace_setevent @TraceID, 148, 14, @on
EXEC sp_trace_setevent @TraceID, 148, 1, @on


/*******************************************
Set the Filters 
******************************************

SYNTAX

sp_trace_setfilter [ @traceid = ] trace_id 
          , [ @columnid = ] column_id
          , [ @logical_operator = ] logical_operator
          , [ @comparison_operator = ] comparison_operator
          , [ @value = ] value

COMPARISON OPERATORS
0  = (Equal)
 
1 <> (Not Equal)
 
2  > (Greater Than)
 
3 < (Less Than)
 
4 >= (Greater Than Or Equal)
 
5  <= (Less Than Or Equal)
 
6 LIKE 
 
7  NOT LIKE 
 
*************************************************************/

DECLARE @intfilter INT
DECLARE @bigintfilter BIGINT

EXEC sp_trace_setfilter @TraceID, 10, 0, 7,
     N'SQL Server Profiler - 82f2cce0-73ef-432b-99f6-b0712f46348d'
--EXEC sp_trace_setfilter @TraceID, 1, 0, 7, N'%exec sp_reset_connection%'

/**********************************************************************
--filter for specific databaseID (column_id = 3)
***********************************************************************/

SET @intfilter = @database_id
--EXEC sp_trace_setfilter @TraceID, 3, 0, 0, @intfilter

/**********************************************************************
Start the Trace
***********************************************************************/
EXEC sp_trace_setstatus @TraceID, 1

/**********************************************************************
Display the StopTrace command 
***********************************************************************/


    
print '/*Issue the following commands to manually stop the tracing activity*/

'
print 'exec sp_trace_setstatus ' + cast(@TraceID as varchar) + ', 0'
print 'exec sp_trace_setstatus ' + cast(@TraceID as varchar) + ', 2'    
    
    
    
GOTO finish

error: 
SELECT
    ErrorCode = @rc

finish: 
go
