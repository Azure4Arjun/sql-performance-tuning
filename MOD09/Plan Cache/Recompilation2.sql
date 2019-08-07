--Part 1

USE AdventureWorks2008R2;
GO

SELECT v.subclass_name, v.subclass_value
FROM sys.trace_events AS e 
JOIN sys.trace_subclass_values AS v
	ON e.trace_event_id = v.trace_event_id
WHERE e.name = 'SP:Recompile'
AND v.subclass_value < 1000
ORDER BY v.subclass_value;
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name ='uspSchemaChangeRecompilationsv1')
	 DROP PROCEDURE uspSchemaChangeRecompilationsv1
GO

CREATE PROCEDURE uspSchemaChangeRecompilationsv1 AS 
	CREATE TABLE tab1 (kol int);             
	SELECT * FROM tab1;                   
	
	CREATE TABLE tab2 (kol int);            
	SELECT * FROM tab2;
	
	CREATE INDEX tab1idx1 ON tab1(kol);   
	SELECT * FROM tab1;
	
	DROP TABLE tab1;
	DROP TABLE tab2;                          
GO

--start Profiler and capture a SP:Recompile event
EXEC uspSchemaChangeRecompilationsv1; 
GO 3


ALTER PROCEDURE uspSchemaChangeRecompilationsv1 AS 
	CREATE TABLE tab1 (kol int);  
	CREATE INDEX tab1idx1 ON tab1(kol);              
	CREATE TABLE tab2 (kol int);  
	
	SELECT * FROM tab1;                   
	SELECT * FROM tab2; 
	SELECT * FROM tab1;
	
	DROP TABLE tab1; 
	DROP TABLE tab2;                           
GO

EXEC uspSchemaChangeRecompilationsv1; 
GO 3

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name ='uspSchemaChangeRecompilationsv2')
	 DROP PROCEDURE uspSchemaChangeRecompilationsv2
GO

CREATE PROCEDURE uspSchemaChangeRecompilationsv2 AS 
	CREATE TABLE #tab1 (kol int);             
	SELECT * FROM #tab1;                   
	
	CREATE TABLE #tab2 (kol int);            
	SELECT * FROM #tab2;
	
	ALTER TABLE #tab1 ADD CONSTRAINT UQ_#tab1 UNIQUE (kol);   
	SELECT * FROM #tab1;                                 
GO

EXEC uspSchemaChangeRecompilationsv2; 
GO 3

ALTER PROCEDURE uspSchemaChangeRecompilationsv2 AS 
	CREATE TABLE #tab1 (kol int);
	CREATE UNIQUE INDEX tab1idx1 ON #tab1(kol);   
	CREATE TABLE #tab2 (kol int); 
	
	SELECT * FROM #tab1;                   
	SELECT * FROM #tab2; 
	SELECT * FROM #tab1;                                 
GO

EXEC uspSchemaChangeRecompilationsv2;
GO 3

--Part 2

SELECT objtype,attribute,value
FROM sys.dm_exec_cached_plans qp
CROSS APPLY sys.dm_exec_plan_attributes(plan_handle) ga
CROSS APPLY sys.dm_exec_sql_text(plan_handle) as qt
WHERE qt.text LIKE '%uspSchemaChangeRecompilationsv1%'
AND qt.text NOT LIKE '%dm_exec_sql_text%'
AND objtype='Proc'
AND is_cache_key=1;
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name ='uspSetChangeRecompliation')
	 DROP PROCEDURE uspSetChangeRecompliation
GO

CREATE PROCEDURE uspSetChangeRecompliation AS 
    SET DATEFORMAT ydm;
	DECLARE @dt datetime = '2012-02-12';
    SELECT MONTH(@dt);
GO

DECLARE @dt datetime = '2012-02-12';
SELECT MONTH(@DT);
GO 
 
EXEC uspSetChangeRecompliation;
GO 5
