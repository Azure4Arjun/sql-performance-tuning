USE master

IF OBJECTPROPERTY(OBJECT_ID('sp_ExposeColsInIndexLevels_INCLUDE_UNORDERED'), 'IsProcedure') = 1 
   DROP PROCEDURE sp_ExposeColsInIndexLevels_INCLUDE_UNORDERED
go

CREATE PROCEDURE sp_ExposeColsInIndexLevels_INCLUDE_UNORDERED
(
 @object_id INT,
 @index_id INT,
 @ColsInTree NVARCHAR(2126) OUTPUT,
 @ColsInLeaf NVARCHAR(MAX) OUTPUT
)
AS 
BEGIN
      DECLARE @nonclus_uniq INT,
              @column_id INT,
              @column_name NVARCHAR(260),
              @col_descending BIT,
              @colstr NVARCHAR(MAX) ;

	-- Get clustered index keys (id and name)
      SELECT    sic.column_id,
                QUOTENAME(sc.name, N']') AS column_name,
                is_descending_key
      INTO      #clus_keys
      FROM      sys.index_columns AS sic
      JOIN      sys.columns AS sc ON sic.column_id = sc.column_id
                                     AND sc.object_id = sic.object_id
      WHERE     sic.[object_id] = @object_id
                AND [index_id] = 1 ;
	
	-- Get nonclustered index keys
      SELECT    sic.column_id,
                sic.is_included_column,
                QUOTENAME(sc.name, N']') AS column_name,
                is_descending_key
      INTO      #nonclus_keys
      FROM      sys.index_columns AS sic
      JOIN      sys.columns AS sc ON sic.column_id = sc.column_id
                                     AND sc.object_id = sic.object_id
      WHERE     sic.[object_id] = @object_id
                AND sic.[index_id] = @index_id ;
		
	-- Is the nonclustered unique?
      SELECT    @nonclus_uniq = is_unique
      FROM      sys.indexes
      WHERE     [object_id] = @object_id
                AND [index_id] = @index_id ;


      IF (@nonclus_uniq = 0) 
         BEGIN
		-- Case 1: nonunique nonclustered index
		
		
		-- cursor for nonclus columns not included and
		-- nonclus columns included but also clus keys
		       SELECT   @colstr = ''
               DECLARE mycursor CURSOR FOR
               SELECT column_id, column_name, is_descending_key  
               FROM #nonclus_keys
               WHERE is_included_column = 0
               OPEN mycursor ;
               FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending ;
               WHILE @@FETCH_STATUS = 0 
                     BEGIN
                           SELECT   @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)'
                                                                                         ELSE N''
                                                                                    END + N', ' ;
                           FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending ;
                     END
               CLOSE mycursor ;
               DEALLOCATE mycursor ;
		
		-- cursor over clus_keys if clustered
               DECLARE mycursor CURSOR FOR
               SELECT column_id, column_name, is_descending_key 
               FROM #clus_keys
               WHERE column_id NOT IN (SELECT column_id FROM #nonclus_keys
               WHERE is_included_column = 0)
               OPEN mycursor ;
               FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending ;
               WHILE @@FETCH_STATUS = 0 
                     BEGIN
                           SELECT   @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)'
                                                                                         ELSE N''
                                                                                    END + N', ' ;
                           FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending ;
                     END
               CLOSE mycursor ;
               DEALLOCATE mycursor ;	
		
               SELECT   @ColsInTree = SUBSTRING(@colstr, 1, LEN(@colstr) - 1) ;
			
		-- find columns not in the nc and not in cl - that are still left to be included.
               DECLARE mycursor CURSOR FOR
               SELECT column_id, column_name, is_descending_key
               FROM #nonclus_keys
               WHERE column_id NOT IN (SELECT column_id FROM #clus_keys UNION SELECT column_id FROM #nonclus_keys WHERE is_included_column = 0)
               ORDER BY column_name
               OPEN mycursor ;
               FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending ;
               WHILE @@FETCH_STATUS = 0 
                     BEGIN
                           SELECT   @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)'
                                                                                         ELSE N''
                                                                                    END + N', ' ;
                           FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending ;
                     END
               CLOSE mycursor ;
               DEALLOCATE mycursor ;	
		
               SELECT   @ColsInLeaf = SUBSTRING(@colstr, 1, LEN(@colstr) - 1) ;
		
         END

	-- Case 2: unique nonclustered
      ELSE 
         BEGIN
		-- cursor over nonclus_keys that are not includes
               SELECT   @colstr = ''
               DECLARE mycursor CURSOR FOR
               SELECT column_id, column_name, is_descending_key 
               FROM #nonclus_keys
               WHERE is_included_column = 0
               OPEN mycursor ;
               FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending ;
               WHILE @@FETCH_STATUS = 0 
                     BEGIN
                           SELECT   @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)'
                                                                                         ELSE N''
                                                                                    END + N', ' ;
                           FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending ;
                     END
               CLOSE mycursor ;
               DEALLOCATE mycursor ;

               SELECT   @ColsInTree = SUBSTRING(@colstr, 1, LEN(@colstr) - 1) ;
	
		-- start with the @ColsInTree and add remaining columns not present...
               DECLARE mycursor CURSOR FOR
               SELECT column_id, column_name, is_descending_key 
               FROM #nonclus_keys 
               WHERE is_included_column = 1 ;
               OPEN mycursor ;
               FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending ;
               WHILE @@FETCH_STATUS = 0 
                     BEGIN
                           SELECT   @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)'
                                                                                         ELSE N''
                                                                                    END + N', ' ;
                           FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending ;
                     END
               CLOSE mycursor ;
               DEALLOCATE mycursor ;

		-- get remaining clustered column as long as they're not already in the nonclustered
               DECLARE mycursor CURSOR FOR
               SELECT column_id, column_name, is_descending_key 
               FROM #clus_keys
               WHERE column_id NOT IN (SELECT column_id FROM #nonclus_keys)
               ORDER BY column_name
               OPEN mycursor ;
               FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending ;
               WHILE @@FETCH_STATUS = 0 
                     BEGIN
                           SELECT   @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)'
                                                                                         ELSE N''
                                                                                    END + N', ' ;
                           FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending ;
                     END
               CLOSE mycursor ;
               DEALLOCATE mycursor ;	
               SELECT   @ColsInLeaf = SUBSTRING(@colstr, 1, LEN(@colstr) - 1) ;
               SELECT   @colstr = ''
	
         END
	-- Cleanup
      DROP TABLE #clus_keys ;
      DROP TABLE #nonclus_keys ;
	
END ;
GO

EXEC sys.sp_MS_marksystemobject 
    'sp_ExposeColsInIndexLevels_INCLUDE_UNORDERED'
go




---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------


IF OBJECTPROPERTY(OBJECT_ID('sp_finddupes_helpindex'), 'IsProcedure') = 1 
   DROP PROCEDURE sp_finddupes_helpindex
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_finddupes_helpindex] @objname NVARCHAR(776)		-- the table to check for indexes
AS --November 2010: Added a column to show if an index is disabled.
--     May 2010: Added tree/leaf columns to the output - this requires the 
--               stored procedure: sp_ExposeColsInIndexLevels
--               (Better known as sp_helpindex8)
--   March 2010: Added index_id to the output (ordered by index_id as well)
--  August 2008: Fixed a bug (missing begin/end block) AND I found
--               a few other issues that people hadn't noticed (yikes!)!
--   April 2008: Updated to add included columns to the output. 


-- See my blog for updates and/or additional information
-- http://www.SQLskills.com/blogs/Kimberly (Kimberly L. Tripp)

SET nocount ON

DECLARE @objid INT,			-- the object id of the table
        @indid SMALLINT,	-- the index id of an index
        @groupid INT,  		-- the filegroup id of an index
        @indname SYSNAME,
        @groupname SYSNAME,
        @status INT,
        @keys NVARCHAR(2126),	--Length (16*max_identifierLength)+(15*2)+(16*3)
        @inc_columns NVARCHAR(MAX),
        @inc_Count SMALLINT,
        @loop_inc_Count SMALLINT,
        @dbname SYSNAME,
        @ignore_dup_key BIT,
        @is_unique BIT,
        @is_hypothetical BIT,
        @is_primary_key BIT,
        @is_unique_key BIT,
        @is_disabled BIT,
        @auto_created BIT,
        @no_recompute BIT,
        @filter_definition NVARCHAR(MAX),
        @ColsInTree NVARCHAR(2126),
        @ColsInLeaf NVARCHAR(MAX)

	-- Check to see that the object names are local to the current database.
SELECT  @dbname = PARSENAME(@objname, 3)
IF @dbname IS NULL 
   SELECT   @dbname = DB_NAME()
ELSE 
   IF @dbname <> DB_NAME() 
      BEGIN
            RAISERROR(15250,-1,-1)
            RETURN (1)
      END

	-- Check to see the the table exists and initialize @objid.
SELECT  @objid = OBJECT_ID(@objname)
IF @objid IS NULL 
   BEGIN
         RAISERROR(15009,-1,-1,@objname,@dbname)
         RETURN (1)
   END

	-- OPEN CURSOR OVER INDEXES (skip stats: bug shiloh_51196)
DECLARE ms_crs_ind CURSOR local static FOR
SELECT  i.index_id,
i.data_space_id,
QUOTENAME(i.name, N']') AS name,
i.ignore_dup_key,
i.is_unique,
i.is_hypothetical,
i.is_primary_key,
i.is_unique_constraint,
s.auto_created,
s.no_recompute,
'',--i.filter_definition,
i.is_disabled
FROM    sys.indexes AS i
JOIN    sys.stats AS s ON i.object_id = s.object_id
AND i.index_id = s.stats_id
WHERE   i.object_id = @objid


OPEN ms_crs_ind
FETCH ms_crs_ind INTO @indid, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,
			@is_primary_key, @is_unique_key, @auto_created, @no_recompute, @filter_definition, @is_disabled

	-- IF NO INDEX, QUIT
IF @@fetch_status < 0 
   BEGIN
         DEALLOCATE ms_crs_ind
		--raiserror(15472,-1,-1,@objname) -- Object does not have any indexes.
         RETURN (0)
   END

	-- create temp tables
CREATE TABLE #spindtab
(
 index_name SYSNAME COLLATE database_default
                    NOT NULL,
 index_id INT,
 ignore_dup_key BIT,
 is_unique BIT,
 is_hypothetical BIT,
 is_primary_key BIT,
 is_unique_key BIT,
 is_disabled BIT,
 auto_created BIT,
 no_recompute BIT,
 groupname SYSNAME COLLATE database_default
                   NULL,
 index_keys NVARCHAR(2126) COLLATE database_default
                           NOT NULL, -- see @keys above for length descr
 filter_definition NVARCHAR(MAX),
 inc_Count SMALLINT,
 inc_columns NVARCHAR(MAX),
 cols_in_tree NVARCHAR(2126),
 cols_in_leaf NVARCHAR(MAX)
)

CREATE TABLE #IncludedColumns
(
 RowNumber SMALLINT,
 [Name] NVARCHAR(128)
)

	-- Now check out each index, figure out its type and keys and
	--	save the info in a temporary table that we'll print out at the end.
WHILE @@fetch_status >= 0 
      BEGIN
		-- First we'll figure out what the keys are.
            DECLARE @i INT,
                    @thiskey NVARCHAR(131) -- 128+3

            SELECT  @keys = QUOTENAME(INDEX_COL(@objname, @indid, 1), N']'),
                    @i = 2
            IF (INDEXKEY_PROPERTY(@objid, @indid, 1, 'isdescending') = 1) 
               SELECT   @keys = @keys + '(-)'

            SELECT  @thiskey = QUOTENAME(INDEX_COL(@objname, @indid, @i), N']')
            IF (
                (@thiskey IS NOT NULL)
                AND (INDEXKEY_PROPERTY(@objid, @indid, @i, 'isdescending') = 1)
               ) 
               SELECT   @thiskey = @thiskey + '(-)'

            WHILE (@thiskey IS NOT NULL) 
                  BEGIN
                        SELECT  @keys = @keys + ', ' + @thiskey,
                                @i = @i + 1
                        SELECT  @thiskey = QUOTENAME(INDEX_COL(@objname, @indid, @i), N']')
                        IF (
                            (@thiskey IS NOT NULL)
                            AND (INDEXKEY_PROPERTY(@objid, @indid, @i, 'isdescending') = 1)
                           ) 
                           SELECT   @thiskey = @thiskey + '(-)'
                  END

		-- Second, we'll figure out what the included columns are.
            SELECT  @inc_columns = NULL
		
            SELECT  @inc_Count = COUNT(*)
            FROM    sys.tables AS tbl
            INNER JOIN sys.indexes AS si ON (
                                             si.index_id > 0
                                             AND si.is_hypothetical = 0
                                            )
                                            AND (si.object_id = tbl.object_id)
            INNER JOIN sys.index_columns AS ic ON (
                                                   ic.column_id > 0
                                                   AND (
                                                        ic.key_ordinal > 0
                                                        OR ic.partition_ordinal = 0
                                                        OR ic.is_included_column != 0
                                                       )
                                                  )
                                                  AND (
                                                       ic.index_id = CAST(si.index_id AS INT)
                                                       AND ic.object_id = si.object_id
                                                      )
            INNER JOIN sys.columns AS clmns ON clmns.object_id = ic.object_id
                                               AND clmns.column_id = ic.column_id
            WHERE   ic.is_included_column = 1
                    AND (si.index_id = @indid)
                    AND (tbl.object_id = @objid)

            IF @inc_Count > 0 
               BEGIN
                     DELETE FROM #IncludedColumns
                     INSERT #IncludedColumns
                            SELECT  ROW_NUMBER() OVER (ORDER BY clmns.column_id),
                                    clmns.name
                            FROM    sys.tables AS tbl
                            INNER JOIN sys.indexes AS si ON (
                                                             si.index_id > 0
                                                             AND si.is_hypothetical = 0
                                                            )
                                                            AND (si.object_id = tbl.object_id)
                            INNER JOIN sys.index_columns AS ic ON (
                                                                   ic.column_id > 0
                                                                   AND (
                                                                        ic.key_ordinal > 0
                                                                        OR ic.partition_ordinal = 0
                                                                        OR ic.is_included_column != 0
                                                                       )
                                                                  )
                                                                  AND (
                                                                       ic.index_id = CAST(si.index_id AS INT)
                                                                       AND ic.object_id = si.object_id
                                                                      )
                            INNER JOIN sys.columns AS clmns ON clmns.object_id = ic.object_id
                                                               AND clmns.column_id = ic.column_id
                            WHERE   ic.is_included_column = 1
                                    AND (si.index_id = @indid)
                                    AND (tbl.object_id = @objid)
			
                     SELECT @inc_columns = QUOTENAME([Name], N']')
                     FROM   #IncludedColumns
                     WHERE  RowNumber = 1

                     SET @loop_inc_Count = 1

                     WHILE @loop_inc_Count < @inc_Count 
                           BEGIN
                                 SELECT @inc_columns = @inc_columns + ', ' + QUOTENAME([Name], N']')
                                 FROM   #IncludedColumns
                                 WHERE  RowNumber = @loop_inc_Count + 1
                                 SET @loop_inc_Count = @loop_inc_Count + 1
                           END
               END
	
            SELECT  @groupname = NULL
            SELECT  @groupname = name
            FROM    sys.data_spaces
            WHERE   data_space_id = @groupid

		-- Get the column list for the tree and leaf level, for all nonclustered indexes IF the table has a clustered index
            IF @indid = 1
               AND (
                    SELECT  is_unique
                    FROM    sys.indexes
                    WHERE   index_id = 1
                            AND object_id = @objid
                   ) = 0 
               SELECT   @ColsInTree = @keys + N', UNIQUIFIER',
                        @ColsInLeaf = N'All columns "included" - the leaf level IS the data row, plus the UNIQUIFIER'
			
            IF @indid = 1
               AND (
                    SELECT  is_unique
                    FROM    sys.indexes
                    WHERE   index_id = 1
                            AND object_id = @objid
                   ) = 1 
               SELECT   @ColsInTree = @keys,
                        @ColsInLeaf = N'All columns "included" - the leaf level IS the data row.'
		
            IF @indid > 1
               AND (
                    SELECT  COUNT(*)
                    FROM    sys.indexes
                    WHERE   index_id = 1
                            AND object_id = @objid
                   ) = 1 
               EXEC sp_ExposeColsInIndexLevels_INCLUDE_UNORDERED 
                @objid,
                @indid,
                @ColsInTree OUTPUT,
                @ColsInLeaf OUTPUT
		
            IF @indid > 1
               AND @is_unique = 0
               AND (
                    SELECT  is_unique
                    FROM    sys.indexes
                    WHERE   index_id = 1
                            AND object_id = @objid
                   ) = 0 
               SELECT   @ColsInTree = @ColsInTree + N', UNIQUIFIER',
                        @ColsInLeaf = @ColsInLeaf + N', UNIQUIFIER'
		
            IF @indid > 1
               AND @is_unique = 1
               AND (
                    SELECT  is_unique
                    FROM    sys.indexes
                    WHERE   index_id = 1
                            AND object_id = @objid
                   ) = 0 
               SELECT   @ColsInLeaf = @ColsInLeaf + N', UNIQUIFIER'
		
            IF @indid > 1
               AND (
                    SELECT  COUNT(*)
                    FROM    sys.indexes
                    WHERE   index_id = 1
                            AND object_id = @objid
                   ) = 0 -- table is a HEAP
               BEGIN
                     IF (@is_unique_key = 0) 
                        SELECT  @ColsInTree = @keys + N', RID',
                                @ColsInLeaf = @keys + N', RID' + CASE WHEN @inc_columns IS NOT NULL THEN N', ' + @inc_columns
                                                                      ELSE N''
                                                                 END
		
                     IF (@is_unique_key = 1) 
                        SELECT  @ColsInTree = @keys,
                                @ColsInLeaf = @keys + N', RID' + CASE WHEN @inc_columns IS NOT NULL THEN N', ' + @inc_columns
                                                                      ELSE N''
                                                                 END
               END
			
		-- INSERT ROW FOR INDEX
		
            INSERT  INTO #spindtab
            VALUES  (@indname, @indid, @ignore_dup_key, @is_unique, @is_hypothetical, @is_primary_key, @is_unique_key, @is_disabled, @auto_created, @no_recompute, @groupname, @keys, @filter_definition, @inc_Count, @inc_columns, @ColsInTree, @ColsInLeaf)

		-- Next index
            FETCH ms_crs_ind INTO @indid, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,
			@is_primary_key, @is_unique_key, @auto_created, @no_recompute, @filter_definition, @is_disabled
      END
DEALLOCATE ms_crs_ind

	-- DISPLAY THE RESULTS
	
SELECT  'index_id' = index_id,
        'is_disabled' = is_disabled,
        'index_name' = index_name,
        'index_description' = CONVERT(VARCHAR(210), --bits 16 off, 1, 2, 16777216 on, located on group
        CASE WHEN index_id = 1 THEN 'clustered'
             ELSE 'nonclustered'
        END + CASE WHEN ignore_dup_key <> 0 THEN ', ignore duplicate keys'
                   ELSE ''
              END + CASE WHEN is_unique = 1 THEN ', unique'
                         ELSE ''
                    END + CASE WHEN is_hypothetical <> 0 THEN ', hypothetical'
                               ELSE ''
                          END + CASE WHEN is_primary_key <> 0 THEN ', primary key'
                                     ELSE ''
                                END + CASE WHEN is_unique_key <> 0 THEN ', unique key'
                                           ELSE ''
                                      END + CASE WHEN auto_created <> 0 THEN ', auto create'
                                                 ELSE ''
                                            END + CASE WHEN no_recompute <> 0 THEN ', stats no recompute'
                                                       ELSE ''
                                                  END + ' located on ' + groupname),
        'index_keys' = index_keys,
        'included_columns' = inc_columns,
        'filter_definition' = filter_definition,
        'columns_in_tree' = cols_in_tree,
        'columns_in_leaf' = cols_in_leaf
FROM    #spindtab
ORDER BY index_id

RETURN (0)
 -- sp_SQL2008_finddupes_helpindex
go

EXEC sys.sp_MS_marksystemobject 
    'sp_finddupes_helpindex'
go




---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------

IF OBJECTPROPERTY(OBJECT_ID('sp_finddupes'), 'IsProcedure') = 1 
   DROP PROCEDURE sp_finddupes
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_finddupes]
(
 @ObjName NVARCHAR(776) = NULL		-- the table to check for duplicates
                                        -- when NULL it will check ALL tables
)
AS --  Jul 2011: V1 to find duplicate indexes.

-- See my blog for updates and/or additional information
-- http://www.SQLskills.com/blogs/Kimberly (Kimberly L. Tripp)

SET NOCOUNT ON

DECLARE @ObjID INT,			-- the object id of the table
        @DBName SYSNAME,
        @SchemaName SYSNAME,
        @TableName SYSNAME,
        @ExecStr NVARCHAR(4000)

-- Check to see that the object names are local to the current database.
SELECT  @DBName = PARSENAME(@ObjName, 3)

IF @DBName IS NULL 
   SELECT   @DBName = DB_NAME()
ELSE 
   IF @DBName <> DB_NAME() 
      BEGIN
            RAISERROR(15250,-1,-1)
	    -- select * from sys.messages where message_id = 15250
            RETURN (1)
      END

IF @DBName = N'tempdb' 
   BEGIN
         RAISERROR('WARNING: This procedure cannot be run against tempdb. Skipping tempdb.', 10, 0)
         RETURN (1)
   END

-- Check to see the the table exists and initialize @ObjID.
SELECT  @SchemaName = PARSENAME(@ObjName, 2)

IF @SchemaName IS NULL 
   SELECT   @SchemaName = SCHEMA_NAME()

-- Check to see the the table exists and initialize @ObjID.
IF @ObjName IS NOT NULL 
   BEGIN
         SELECT @ObjID = OBJECT_ID(@ObjName)
	
         IF @ObjID IS NULL 
            BEGIN
                  RAISERROR(15009,-1,-1,@ObjName,@DBName)
        -- select * from sys.messages where message_id = 15009
                  RETURN (1)
            END
   END


CREATE TABLE #DropIndexes
(
 info NVARCHAR(255),
 DatabaseName SYSNAME,
 SchemaName SYSNAME,
 TableName SYSNAME,
 IndexName SYSNAME,
 DuplicateOfIndex SYSNAME,
 index_keys NVARCHAR(2126),
 included_columns NVARCHAR(MAX),
 DropStatement NVARCHAR(2000)
)

CREATE TABLE #SimiliarIndexes
(
 info NVARCHAR(255),
 DatabaseName SYSNAME,
 SchemaName SYSNAME,
 TableName SYSNAME,
 IndexName1 SYSNAME,
 IndexName2 SYSNAME,
 index_keys1 NVARCHAR(2126),
 index_keys2 NVARCHAR(2126),
 included_columns1 NVARCHAR(MAX),
 included_columns2 NVARCHAR(MAX),
 SQLStatementProposition NVARCHAR(max)
)


CREATE TABLE #FindDupes
(
 index_id INT,
 is_disabled BIT,
 index_name SYSNAME,
 index_description VARCHAR(210),
 index_keys NVARCHAR(2126),
 included_columns NVARCHAR(MAX),
 filter_definition NVARCHAR(MAX),
 columns_in_tree NVARCHAR(2126),
 columns_in_leaf NVARCHAR(MAX)
)

-- OPEN CURSOR OVER TABLE(S)
IF @ObjName IS NOT NULL 
   DECLARE TableCursor CURSOR LOCAL STATIC FOR
   SELECT @SchemaName, PARSENAME(@ObjName, 1)
ELSE 
   DECLARE TableCursor CURSOR LOCAL STATIC FOR 		    
   SELECT SCHEMA_NAME(uid), name 
   FROM sysobjects 
   WHERE type = 'U' --AND name
   ORDER BY SCHEMA_NAME(uid), name
	    
OPEN TableCursor 

FETCH TableCursor
    INTO @SchemaName, @TableName

-- For each table, list the add the duplicate indexes and save 
-- the info in a temporary table that we'll print out at the end.

WHILE @@fetch_status >= 0 
      BEGIN
            TRUNCATE TABLE #FindDupes
    
            SELECT  @ExecStr = 'EXEC sp_finddupes_helpindex ''' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N''''

    --SELECT @ExecStr

            INSERT  #FindDupes
                    EXEC (
                          @ExecStr
                         )	
    

	
            INSERT  #DropIndexes
                    SELECT DISTINCT
							'Duplicate indexes',
                            @DBName,
                            @SchemaName,
                            @TableName,
                            t1.index_name,
                            DuplicateOfIndex = t2.index_name,
                            t1.index_keys,
                            t1.included_columns,
                            N'DROP INDEX ' + QUOTENAME(@SchemaName, N']') + N'.' + QUOTENAME(@TableName, N']') + N'.' + t1.index_name
                    FROM    #FindDupes AS t1
                    JOIN    #FindDupes AS t2 ON t1.columns_in_tree = t2.columns_in_tree
                                                AND t1.columns_in_leaf = t2.columns_in_leaf
                                                AND ISNULL(t1.filter_definition, 1) = ISNULL(t2.filter_definition, 1)
                                                AND PATINDEX('%unique%', t1.index_description) = PATINDEX('%unique%', t2.index_description)
                                                AND t1.index_id > t2.index_id




			INSERT	#SimiliarIndexes
                    SELECT DISTINCT
							'Similiar indexes',
                            @DBName,
                            @SchemaName,
                            @TableName,
                            t1.index_name,
                            t2.index_name,
                            t1.index_keys,
                            t2.index_keys,
                            t1.INCLUDED_COLUMNS,
                            t2.INCLUDED_COLUMNS,
                            SQLStatementProposition = 
                            'CREATE ' 
                            + -- UNIQUE?
                            CASE WHEN t1.index_description LIKE '%UNIQUE%' OR t2.index_description LIKE '%UNIQUE%' THEN 'UNIQUE ' ELSE '' END
                            + -- CLUSTERED?
                            CASE WHEN t1.index_id = 1 OR t2.index_id = 1 THEN 'CLUSTERED ' ELSE '' END
                            +
							CASE 
								WHEN LEN(t1.index_keys) >= LEN(t2.index_keys)
								THEN 'INDEX ' + REPLACE(T1.index_name, '[', '[new_') + ' ON ' + QUOTENAME(@SchemaName, N']') + N'.' + QUOTENAME(@TableName, N']') + ' ('+T1.index_keys+')'
								WHEN LEN(t1.index_keys) < LEN(t2.index_keys)
								THEN 'INDEX ' + REPLACE(T2.index_name, '[', '[new_') + ' ON ' + QUOTENAME(@SchemaName, N']') + N'.' + QUOTENAME(@TableName, N']') + ' ('+T2.index_keys+')'				
							END
							+ -- INCLUDE -- ToDo
							CASE 
								WHEN LEN(ISNULL(t1.INCLUDED_COLUMNS, '')) > 0 AND LEN(ISNULL(t2.INCLUDED_COLUMNS, '')) = 0 
								THEN ' INCLUDE (' + t1.INCLUDED_COLUMNS+')'
								WHEN LEN(ISNULL(t1.INCLUDED_COLUMNS, '')) = 0 AND LEN(ISNULL(t2.INCLUDED_COLUMNS, '')) > 0 
								THEN ' INCLUDE (' + t2.INCLUDED_COLUMNS+')'
								WHEN LEN(ISNULL(t1.INCLUDED_COLUMNS, '')) > 0 AND LEN(ISNULL(t1.INCLUDED_COLUMNS, '')) > 0 
								THEN ' INCLUDE (' + t1.INCLUDED_COLUMNS+ ','+t2.INCLUDED_COLUMNS+')'
								ELSE ''
							END	
                    FROM    #FindDupes AS t1
                    JOIN    #FindDupes AS t2 ON 
												t1.index_keys = SUBSTRING(t2.index_keys, 1, LEN(t1.index_keys))
												AND t1.index_id <> t2.index_id                                            
												

            FETCH TableCursor
        INTO @SchemaName, @TableName
      END
	
DEALLOCATE TableCursor

-- DISPLAY THE RESULTS

IF (
    SELECT  COUNT(*)
    FROM    #DropIndexes
   ) = 0 
   RAISERROR('Database: %s has NO duplicate indexes.', 10, 0, @DBName)
ELSE 
   SELECT   *
   FROM     #DropIndexes
   ORDER BY SchemaName,
            TableName


IF (
    SELECT  COUNT(*)
    FROM    #SimiliarIndexes
   ) = 0 
   RAISERROR('Database: %s has NO similiar indexes.', 10, 0, @DBName)
ELSE 
   SELECT   *
   FROM     #SimiliarIndexes
   ORDER BY SchemaName,
            TableName


RETURN (0)
 -- sp_SQL2008_finddupes
go

EXEC sys.sp_MS_marksystemobject 
    'sp_finddupes'
go


