use master
go
if db_id(N'SQLServerArticles') is not null
begin
	alter database SQLServerArticles set single_user with rollback immediate
    drop database SQLServerArticles
end
go

--Check Whether Semantic Search Is Installed
SELECT SERVERPROPERTY('IsFullTextInstalled')
GO
--Check Whether the Semantic Language Statistics Database Is Installed
SELECT * 
FROM sys.fulltext_semantic_language_statistics_database
GO

-- Install SemanticLanguageDatabase.msi 

--Attach the semantic language statistics database
CREATE DATABASE semanticsdb
              ON ( FILENAME = 'C:\Program Files\Microsoft Semantic Language Database\semanticsdb.mdf' )
              LOG ON ( FILENAME = 'C:\Program Files\Microsoft Semantic Language Database\semanticsdb_log.ldf' )
              FOR ATTACH
GO


-- REGISTER SEMANTICS LANGUAGES DATABSE (ONE TIME ONLY)
EXEC sp_fulltext_semantic_register_language_statistics_db 'semanticsdb';
GO

/* Verify the registration is succeeded */
SELECT * 
FROM sys.fulltext_semantic_language_statistics_database;
GO

/* Check available languages for statistical semantic extraction */
SELECT * 
FROM sys.fulltext_semantic_languages;
GO

CREATE DATABASE SQLServerArticles
ON PRIMARY (name = SQLServerArticles_File, filename = N'C:\SQL\SQLServerArticles_File.mdf' ),
FILEGROUP SQLStorage contains filestream ( name = SQLServerArticles_FS_File, filename = N'C:\SQL\SQLServerArticles_FS' )
WITH FILESTREAM ( 
    non_transacted_access = full,
    directory_name = N'SQLServer Articles' )
GO

-- CREATE A FILETABLE(s)
CREATE TABLE SQLServerArticles..Documents 
AS FILETABLE WITH (filetable_directory = N'Document Library')
go

SELECT * 
FROM SQLServerArticles..Documents

--Copy folder to the share

-- Create FullText Index on Documents Table
USE SQLServerArticles
GO

CREATE FULLTEXT CATALOG ft AS DEFAULT
GO

CREATE UNIQUE INDEX DocumentsFt ON SQLServerArticles..Documents(stream_id)
GO

-- in general, find Windows Search Properties here: http://msdn.microsoft.com/en-us/library/dd561977(v=VS.85).aspx
-- or here http://msdn.microsoft.com/en-us/library/dd368864(VS.85).aspx#generic
CREATE SEARCH PROPERTY LIST DocumentProperties;
GO
ALTER SEARCH PROPERTY LIST DocumentProperties
   ADD 'Title'
   WITH ( PROPERTY_SET_GUID = 'F29F85E0-4FF9-1068-AB91-08002B27B3D9', PROPERTY_INT_ID = 2, 
      PROPERTY_DESCRIPTION = 'System.Title - Title of the item.' );
GO
ALTER SEARCH PROPERTY LIST DocumentProperties
    ADD 'Author'
   WITH ( PROPERTY_SET_GUID = 'F29F85E0-4FF9-1068-AB91-08002B27B3D9', PROPERTY_INT_ID = 4, 
      PROPERTY_DESCRIPTION = 'System.Author - Author or authors of the item.' );
GO
ALTER SEARCH PROPERTY LIST DocumentProperties 
    ADD 'Tags'
   WITH ( PROPERTY_SET_GUID = 'F29F85E0-4FF9-1068-AB91-08002B27B3D9', PROPERTY_INT_ID = 5, 
      PROPERTY_DESCRIPTION = 'System.Keywords - Keywords (Tags) of the item.' );
GO

-- Add a full text index, indexing the file_stream column and using the file_type computed column as the type
-- Specify statistical semantics for key phrase and similarity extractions along with fulltext keywords
-- Specify DocumentProperties Property List for properties extraction
CREATE FULLTEXT INDEX ON SQLServerArticles..Documents
	(file_stream TYPE COLUMN file_type LANGUAGE 1033 statistical_semantics)
	KEY INDEX DocumentsFt ON ft
	WITH SEARCH PROPERTY LIST = DocumentProperties
GO
-- Transfer Files

-- Show Files in FileTable using T-SQL
SELECT FileTableRootPath() AS 'FileTable Root Path'
GO

SELECT stream_id, name, file_type, file_stream.GetFileNamespacePath() FilePath,
	creation_Time, last_write_time, last_access_time, is_directory, is_offline,
	is_hidden, is_readonly, is_archive, is_system, is_temporary
	FROM SQLServerArticles..Documents
	ORDER BY name ASC
GO

-----------------------------------------------------------------------------
--
-- CHECK INDEX POPULATION STATUS
--
-----------------------------------------------------------------------------
/* Check Population Progress */
SELECT fulltextcatalogproperty('ft', 'populatestatus')
GO

SELECT FULLTEXTCATALOGPROPERTY ('ft','MergeStatus')
GO

SELECT DB_NAME(database_id) AS 'DB Name', OBJECT_NAME(table_id) AS 'Table Name',
	population_type, status, status_description, worker_count, start_time, *
	FROM sys.dm_fts_index_population

SELECT DB_NAME(database_id) AS 'DB Name', OBJECT_NAME(table_id) AS 'Table Name',
	status, status_description, worker_count, start_time, *
	FROM sys.dm_fts_semantic_similarity_population

/* check Population size */
SELECT OBJECT_NAME(object_id), fulltext_index_page_count,
	keyphrase_index_page_count, similarity_index_page_count
	FROM sys.dm_db_fts_index_physical_stats
GO

-- USAGE OF PROPERTY Scoped search within CONTAINS
SELECT name DocumentName, file_stream.GetFileNamespacePath() Path FROM Documents
	WHERE CONTAINS(PROPERTY(file_stream, 'Title'), 'data OR SQL');
GO

-- Keywords by document
SELECT * 
FROM sys.dm_fts_index_keywords_by_document( 
  DB_ID('SQLServerArticles'), OBJECT_ID('Documents'))
ORDER BY occurrence_count DESC

----- CONTAINS ------

-- single term, all columns
SELECT name 
FROM Documents
WHERE CONTAINS(*, 'data')

-- ORs
SELECT name 
FROM Documents
WHERE CONTAINS(*, '"data" OR "SQL" OR "record"')

-- term prefix
SELECT name 
FROM Documents
WHERE CONTAINS(*, 'record*')

-- inflectional search
SELECT name 
FROM Documents
WHERE CONTAINS(*, 'FORMSOF(INFLECTIONAL, "record")')

-- thesaurus search
SELECT name 
FROM Documents
WHERE CONTAINS(*, 'FORMSOF(THESAURUS, record)')

-- property search, single term
SELECT name 
FROM Documents
WHERE CONTAINS(PROPERTY(file_stream, 'Title'), 'Replication')

-- property search, multiple terms
SELECT name 
FROM Documents
WHERE CONTAINS(PROPERTY(file_stream, 'Title'), 'Replication OR SQL')

-- NEAR, order senstive
SELECT name 
FROM Documents
WHERE CONTAINS(file_stream, 'NEAR(("data", "SQL"), 5, TRUE)');

-- NEAR, not order senstive
SELECT name 
FROM Documents
WHERE CONTAINS(file_stream, 'NEAR(("data", "SQL"), 5, FALSE)');

------ CONTAINSTABLE ------

-- single term, all columns
SELECT * 
FROM CONTAINSTABLE(documents, *, 'data')

-- single term, top 10 by rank
SELECT * 
FROM CONTAINSTABLE(documents, *, 'data', 10)

-- weighted
SELECT * 
FROM CONTAINSTABLE(documents, *, 'ISABOUT (performance weight (.8), data weight (.4), record weight (.2) )' );

-- Plan: FTS-1
-- weighted, top 5
SELECT * 
FROM CONTAINSTABLE(documents, *, 'ISABOUT (performance weight (.8), data weight (.4), record weight (.2) )',5);

------ FREETEXT -------

-- 3 terms
SELECT name 
FROM Documents
WHERE FREETEXT(*, 'SQL data record')

-- 5 terms
SELECT name 
FROM Documents
WHERE FREETEXT(*, 'SQL data record performance microsoft')

-- rank of zero in FREETEXTTABLE
SELECT name 
FROM Documents
WHERE FREETEXT(*, 'data backup')

------ FREETEXTTABLE -------

-- looks like these terms have to occur together to get a rank
SELECT * 
FROM FREETEXTTABLE(documents, *, 'Microsoft SQL Server')

SELECT * 
FROM FREETEXTTABLE(documents, *, 'Microsoft SQL Server', 10)

-- all have rank of zero
SELECT * 
FROM FREETEXTTABLE(documents, *, 'data backup')
SELECT * 
FROM FREETEXTTABLE(documents, *, 'backup data')

-- one term works fine, lots of non-zero high rankings
SELECT * 
FROM FREETEXTTABLE(documents, *, 'data')
-- one term works fine, lots of non-zero high rankings
SELECT * 
FROM FREETEXTTABLE(documents, *, 'backup')
-- all have rank of zero
SELECT * 
FROM FREETEXTTABLE(documents, *, 'data backup')
SELECT * 
FROM FREETEXTTABLE(documents, *, 'backup data')

-- SEMANTICKEYPHRASETABLE function

/* Get top key phrases in the entire corpus */
SELECT name, document_key, keyphrase, score
	FROM semantickeyphrasetable(Documents, *)
	INNER JOIN Documents ON stream_id = document_key
	ORDER BY name, score DESC
GO

/* Get key phrases for ResourceGov Paper */
USE SQLServerArticles
DECLARE @Title as NVARCHAR(1000)
DECLARE @DocID as UNIQUEIDENTIFIER

SET	@Title = 'ResourceGov.docx'
--SET	@Title = 'TShootPerfProbs2008.docx'

SELECT @DocID = stream_id 
	FROM Documents 
	WHERE name = @Title

SELECT name, document_key, keyphrase, score
	FROM semantickeyphrasetable(Documents, *, @DocID)
	INNER JOIN Documents ON stream_id = document_key
	ORDER BY name, score DESC
GO

-- SEMANTICSIMILARITYTABLE rowset function

/* Get similar documents for ResourceGov Paper */
USE SQLServerArticles
DECLARE @Title as NVARCHAR(1000)
DECLARE @DocID as UNIQUEIDENTIFIER

SET	@Title = 'ResourceGov.docx'
--SET	@Title = 'TShootPerfProbs2008.docx'

SELECT @DocID = stream_id 
	FROM Documents 
	WHERE name = @Title

SELECT @Title AS SourceTitle, name AS MatchedTitle, stream_id, score
	FROM semanticsimilaritytable(Documents, *, @DocID)
	INNER JOIN Documents ON stream_id = matched_document_key
	ORDER BY score DESC
GO

-- USAGE OF SEMANTICSIMILARITYDETAILSTABLE

/* Get Similarity Details for one of the matched Document */
USE SQLServerArticles
DECLARE @SourceTitle as NVARCHAR(1000)
DECLARE @MatchedTitle as NVARCHAR(1000)
DECLARE @SourceDocID as UNIQUEIDENTIFIER
DECLARE @MatchedDocID as UNIQUEIDENTIFIER

SET	@SourceTitle = 'ResourceGov.docx'
SET @MatchedTitle = 'TShootPerfProbs2008.docx'


SELECT @SourceDocID = stream_id FROM Documents WHERE name = @SourceTitle
SELECT @MatchedDocID = stream_id FROM Documents WHERE name = @MatchedTitle

SELECT @SourceTitle AS SourceTitle, @MatchedTitle AS MatchedTitle, keyphrase, score
	FROM semanticsimilaritydetailstable(Documents, file_stream, @SourceDocID, file_stream, @MatchedDocID)
	ORDER BY score DESC
GO

-- internals
select * from sys.internal_tables

select * from sys.fulltext_index_docidmap_245575913

select * from sys.indexes

select * from sys.columns
where object_id = 245575913


use master
go
if db_id(N'SQLServerArticles') is not null
begin
	alter database SQLServerArticles set single_user with rollback immediate
    drop database SQLServerArticles
end
go






