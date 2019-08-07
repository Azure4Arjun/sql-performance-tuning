USE tempdb;
GO

CREATE TABLE t1(i INT)
CREATE TABLE t2(j INT)
GO

-- uses hash match
SELECT * FROM t1, t2 WHERE t1.i = t2.j
GO

-- make it use merge join
-- note that this works, even though the database is an old (pre-release) version
SELECT * FROM t1, t2 WHERE t1.i = t2.j OPTION (USE PLAN N'
<ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="0.5" Build="9.00.938">
  <BatchSequence>
    <Batch>
      <Statements>
        <StmtSimple StatementText="SELECT * FROM t1, t2 WHERE t1.i = t2.j" StatementId="1" 
         StatementCompId="1" StatementType="SELECT" StatementSubTreeCost="0.0514796" 
         StatementEstRows="1" StatementOptmLevel="FULL">
          <StatementSetOptions QUOTED_IDENTIFIER="true" ARITHABORT="true" CONCAT_NULL_YIELDS_NULL="true" 
           ANSI_NULLS="true" ANSI_PADDING="true" ANSI_WARNINGS="true" NUMERIC_ROUNDABORT="false" />
          <QueryPlan CachedPlanSize="20">
            <RelOp NodeId="0" PhysicalOp="Merge Join" LogicalOp="Inner Join" EstimateRows="1" 
             EstimateIO="0.000313" EstimateCPU="0.00564738" AvgRowSize="15" 
             EstimatedTotalSubtreeCost="0.0514796" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
              <OutputList>
                <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t1]" Column="i" />
                <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t2]" Column="j" />
              </OutputList>
              <Merge ManyToMany="1">
                <InnerSideJoinColumns>
                  <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t2]" Column="j" />
                </InnerSideJoinColumns>
                <OuterSideJoinColumns>
                  <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t1]" Column="i" />
                </OuterSideJoinColumns>
                <Residual>
                  <ScalarOperator ScalarString="[tempdb].[dbo].[t2].[j]=[tempdb].[dbo].[t1].[i]">
                    <Compare CompareOp="EQ">
                      <ScalarOperator>
                        <Identifier>
                          <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t2]" Column="j" />
                        </Identifier>
                      </ScalarOperator>
                      <ScalarOperator>
                        <Identifier>
                          <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t1]" Column="i" />
                        </Identifier>
                      </ScalarOperator>
                    </Compare>
                  </ScalarOperator>
                </Residual>
                <RelOp NodeId="1" PhysicalOp="Sort" LogicalOp="Sort" EstimateRows="1" EstimateIO="0.01625" 
                 EstimateCPU="0.000100011" AvgRowSize="11" EstimatedTotalSubtreeCost="0.0227581" Parallel="0" 
                 EstimateRebinds="0" EstimateRewinds="0">
                  <OutputList>
                    <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t1]" Column="i" />
                  </OutputList>
                  <MemoryFractions Input="1" Output="0.5" />
                  <Sort Distinct="0">
                    <OrderBy>
                      <OrderByColumn Ascending="1">
                        <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t1]" Column="i" />
                      </OrderByColumn>
                    </OrderBy>
                    <RelOp NodeId="2" PhysicalOp="Table Scan" LogicalOp="Table Scan" EstimateRows="1"
                     EstimateIO="0.0063285" EstimateCPU="7.96e-005" AvgRowSize="11" 
                     EstimatedTotalSubtreeCost="0.0064081" Parallel="0" EstimateRebinds="0" 
                     EstimateRewinds="0">
                      <OutputList>
                        <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t1]" Column="i" />
                      </OutputList>
                      <TableScan Ordered="0" ForcedIndex="0">
                        <DefinedValues>
                          <DefinedValue>
                            <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t1]" Column="i" />
                          </DefinedValue>
                        </DefinedValues>
                        <Object Database="[tempdb]" Schema="[dbo]" Table="[t1]" />
                      </TableScan>
                    </RelOp>
                  </Sort>
                </RelOp>
                <RelOp NodeId="3" PhysicalOp="Sort" LogicalOp="Sort" EstimateRows="1" 
                 EstimateIO="0.01625" EstimateCPU="0.000100011" AvgRowSize="11" 
                 EstimatedTotalSubtreeCost="0.0227581" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                  <OutputList>
                    <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t2]" Column="j" />
                  </OutputList>
                  <MemoryFractions Input="0.5" Output="0.5" />
                  <Sort Distinct="0">
                    <OrderBy>
                      <OrderByColumn Ascending="1">
                        <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t2]" Column="j" />
                      </OrderByColumn>
                    </OrderBy>
                    <RelOp NodeId="4" PhysicalOp="Table Scan" LogicalOp="Table Scan" EstimateRows="1" 
                     EstimateIO="0.0063285" EstimateCPU="7.96e-005" AvgRowSize="11" 
                     EstimatedTotalSubtreeCost="0.0064081" Parallel="0" EstimateRebinds="0" 
                     EstimateRewinds="0">
                      <OutputList>
                        <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t2]" Column="j" />
                      </OutputList>
                      <TableScan Ordered="0" ForcedIndex="0">
                        <DefinedValues>
                          <DefinedValue>
                            <ColumnReference Database="[tempdb]" Schema="[dbo]" Table="[t2]" Column="j" />
                          </DefinedValue>
                        </DefinedValues>
                        <Object Database="[tempdb]" Schema="[dbo]" Table="[t2]" />
                      </TableScan>
                    </RelOp>
                  </Sort>
                </RelOp>
              </Merge>
            </RelOp>
          </QueryPlan>
        </StmtSimple>
      </Statements>
    </Batch>
  </BatchSequence>
</ShowPlanXML>')
GO

-- Plan Guides
Use AdventureWorks

CREATE PROCEDURE test AS
SELECT FirstName, LastName
FROM Person.Contact AS C 
JOIN Sales.Individual AS I
	ON C.ContactID = I.ContactID;
GO

EXEC test
GO

EXEC sp_create_plan_guide 
@name = N'plan_guide_test', 
@stmt = N'SELECT FirstName, LastName FROM Person.Contact AS C JOIN Sales.Individual AS I ON C.ContactID = I.ContactID',
 @type = N'OBJECT',
 @module_or_batch = N'test', 
 @params = NULL, 
 @hints = N'OPTION (LOOP JOIN)';
GO

EXEC test
GO

EXEC sp_control_plan_guide N'DISABLE', N'plan_guide_test';
GO


EXEC test
GO

EXEC sp_control_plan_guide N'ENABLE', N'plan_guide_test';
GO

EXEC sp_control_plan_guide N'DROP', N'plan_guide_test';
GO
-- Force Hint to Limit Parallelization
DBCC FREEPROCCACHE
GO
USE AdventureWorks
GO
IF EXISTS(SELECT 1 FROM sys.plan_guides WHERE NAME = 'MAXDOP1_Plan')
   EXEC sp_control_plan_guide N'DROP', N'MAXDOP1_Plan';
GO

--Look at the query plan and note the parallelism
SELECT  *
FROM Sales.SalesOrderDetail
ORDER BY ModifiedDate DESC;
GO

-- Create a plan guide:
EXEC sp_create_plan_guide 
@name = N'MaxDOP1_Plan', 
@stmt = 
N'SELECT  *
FROM Sales.SalesOrderDetail
ORDER BY ModifiedDate DESC;', 
@type = N'SQL',
@module_or_batch = NULL, 
@params = NULL, 
@hints = N'OPTION (MAXDOP 1)';
GO


--Look at the query plan and note the lack of parallelism
-- Do NOT include the comment
SELECT  *
FROM dbo.SalesOrderDetail
ORDER BY ModifiedDate DESC;
 
   
-- Disable the PLAN GUIDE
EXEC sp_control_plan_guide N'DISABLE', N'MAXDOP1_Plan';

--Look at the query plan and note the parallelism
SELECT  *
FROM dbo.SalesOrderDetail
ORDER BY ModifiedDate DESC;
GO

-- Enable the PLAN GUIDE
EXEC sp_control_plan_guide N'ENABLE', N'MAXDOP1_Plan';
DBCC FREEPROCCACHE
--Look at the query plan and note the lack of parallelism
SELECT  *
FROM dbo.SalesOrderDetail
ORDER BY ModifiedDate DESC;
 

-----------------------------------------------------
-- Template Plan Guide



IF EXISTS(SELECT 1 FROM sys.plan_guides WHERE NAME = 'Template_Plan')
   EXEC sp_control_plan_guide N'DROP', N'Template_Plan';
GO
DBCC FREEPROCCACHE
GO
-- Note that these two queries use only adhoc plans
SELECT * FROM AdventureWorks.Sales.SalesOrderHeader AS h
INNER JOIN AdventureWorks.Sales.SalesOrderDetail AS d 
    ON h.SalesOrderID = d.SalesOrderID
WHERE h.SalesOrderID = 45639;
GO
SELECT * FROM AdventureWorks.Sales.SalesOrderHeader AS h
INNER JOIN AdventureWorks.Sales.SalesOrderDetail AS d 
    ON h.SalesOrderID = d.SalesOrderID
WHERE h.SalesOrderID = 45640;
GO
SELECT * FROM sys.dm_exec_cached_plans
WHERE cacheobjtype = 'Compiled Plan';
GO

-- Get plan template and create plan Guide
DECLARE @stmt nvarchar(max);
DECLARE @params nvarchar(max);
EXEC sp_get_query_template 
    N'SELECT * FROM AdventureWorks.Sales.SalesOrderHeader AS h
      INNER JOIN AdventureWorks.Sales.SalesOrderDetail AS d 
          ON h.SalesOrderID = d.SalesOrderID
      WHERE h.SalesOrderID = 45639;',
    @stmt OUTPUT, 
    @params OUTPUT
EXEC sp_create_plan_guide N'Template_Plan', 
    @stmt, 
    N'TEMPLATE', 
    NULL, 
    @params, 
    N'OPTION(PARAMETERIZATION FORCED)';
GO
-- Verify that optimizer is  now creating a parameterized plan
DBCC FREEPROCCACHE
GO
SELECT * FROM AdventureWorks.Sales.SalesOrderHeader AS h
INNER JOIN AdventureWorks.Sales.SalesOrderDetail AS d 
    ON h.SalesOrderID = d.SalesOrderID
WHERE h.SalesOrderID = 45639;
GO
SELECT * FROM AdventureWorks.Sales.SalesOrderHeader AS h
INNER JOIN AdventureWorks.Sales.SalesOrderDetail AS d 
    ON h.SalesOrderID = d.SalesOrderID
WHERE h.SalesOrderID = 45640;
GO
SELECT * FROM sys.syscacheobjects
WHERE cacheobjtype = 'Compiled Plan';
GO
