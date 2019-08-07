DECLARE @TraceID INT
SET @TraceID = 2 --Insert Correct Trace ID Here


exec sp_trace_setstatus @TraceID, 0
exec sp_trace_setstatus @TraceID, 2
GO

