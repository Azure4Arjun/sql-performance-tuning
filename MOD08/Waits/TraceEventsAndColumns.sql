SELECT 
  te.trace_event_id
, te.name AS EventName
, tc.name AS Category 
FROM sys.trace_events te
INNER JOIN sys.trace_categories tc 
ON te.category_id = tc.category_id;
GO

SELECT 
  trace_column_id
, name
FROM sys.trace_columns;
GO
