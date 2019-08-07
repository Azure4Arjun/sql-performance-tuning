/*

	Training:	Optimizing and Troubleshooting
	Module:		06 - Database Configuration
	Verion:		1.0
	Trainer: Lukasz Grala
	Email:	 lukasz@sqlexpert.pl

	Copyright by SQLExpert.pl 

*/


CREATE DATABASE filetab_demo
ON PRIMARY 
  (name = filetab_demo_file, filename = N'C:\SQL\FileTab_Demo_File.mdf' ),
filegroup FSStorage contains filestream 
  ( name = filetab_demo_fs_file, filename = N'C:\SQL\FileTab_Demo_FS' )
with filestream ( 
    non_transacted_access = full,
    directory_name = N'FileTab_Demo' )
GO

-- create filetable
CREATE TABLE filetab_demo..Documents AS FileTable 
WITH (filetable_directory = N'Documents')
GO

USE filetab_demo
GO

SELECT * 
FROM Documents;

-- fails in directory has files in it
DELETE Documents 
WHERE name = 'SQL Server';

SELECT * 
FROM Documents;

-- works
DELETE Documents 
WHERE name = 'SomeText.txt.docx'

-- get existing database blobs into files
DECLARE @resume varbinary(max);
DECLARE @name varchar(40);

SELECT @resume = cast(Resume as varbinary(max))
      ,@name = 'JobCandidate' + cast(JobCandidateID as varchar(1)) + '.xml'
FROM AdventureWorks.HumanResources.JobCandidate
WHERE JobCandidateID = 1;

INSERT dbo.Documents(Name, file_stream) 
VALUES(@name, @resume)
GO
-- path_locator and parent_path_locator are hierarchyids
-- get the friendly names
SELECT 
  name,
  path_locator,
  file_stream.GetFileNamespacePath() as FilePath, -- equals GetFileNamespacePath(0)
  file_stream.GetFileNamespacePath(1) as FullFilePath,
  FileTableRootPath() as RootPath,
  FileTableRootPath('dbo.Documents') as [RootPath Of This Table],
  --FileTableRootPath('dbo.Documents',0),  -- NETBIOS name
  --FileTableRootPath('dbo.Documents',1),
  --FileTableRootPath('dbo.Documents',2),
  GetPathLocator(file_stream.GetFileNamespacePath(1)) as PathLocator,
  file_stream.PathName() as FileStreamPath  -- FileStream Path Name
  --file_stream.PathName(0, 0) -- NETBIOS name, retrieve VNN
  --file_stream.PathName(0, 1) -- NETBIOS name, retrieve computer name
FROM Documents;

DECLARE @fullpath nvarchar(260);
SELECT @fullpath = FileTableRootPath() + file_stream.GetFileNamespacePath()
FROM dbo.Documents
WHERE name = 'JobCandidate1.xml';
SELECT @fullpath
-- This gets a filetable pathlocator from a path name
SELECT GetPathLocator(@fullpath) as PathLocatorHierarchyid;
GO

SELECT path_locator
FROM dbo.Documents
WHERE name = 'JobCandidate1.xml';
GO

-- try it with a directory
DECLARE @fullpath nvarchar(260);
SELECT @fullpath = FileTableRootPath() + file_stream.GetFileNamespacePath()
FROM dbo.Documents
WHERE name = 'SQL Server';
SELECT @fullpath
-- This gets a filetable pathlocator from a path name
SELECT GetPathLocator(@fullpath) as PathLocatorHierarchyid;

SELECT path_locator
FROM dbo.Documents
WHERE name = 'SQL Server';
GO


-- use the path_locator and parent_path_locator as hierarchyid
-- Level Number
SELECT path_locator.GetLevel() as Level, 
	file_stream.GetFileNamespacePath() as NameSpacePath, 
	path_locator.ToString() as Path,
	name
FROM dbo.Documents p 
GO

-- Level Number of table is 0. Table PathLocator is root
SELECT FileTableRootPath('dbo.Documents') as RootPath,
       GetPathLocator(FileTableRootPath('dbo.Documents')) as Path, 
       GetPathLocator(FileTableRootPath('dbo.Documents')).GetLevel() as Level;

-- an interesting way to get all direct children of the top-level SQL Server node
SELECT p.name as ParentName, c.name as ChildName, c.is_directory,
	c.file_stream.GetFileNamespacePath() as ChildPath
FROM dbo.Documents p 
JOIN dbo.Documents c
ON p.name = 'SQL Server'
AND p.path_locator.GetLevel() = 1
AND c.path_locator.GetAncestor(1) = p.path_locator;

-- or 
SELECT p.name as ParentName, c.name as ChildName, c.is_directory,
	c.file_stream.GetFileNamespacePath() as ChildPath
FROM dbo.Documents p 
JOIN dbo.Documents c
ON p.name = 'SQL Server'
AND p.path_locator.GetLevel() = 1
AND c.parent_path_locator = p.path_locator;

-- child of the top-level SQL Server node, any 
SELECT p.name as ParentName, c.name as ChildName, c.is_directory,
	c.file_stream.GetFileNamespacePath() as ChildPath
FROM dbo.Documents p 
JOIN dbo.Documents c
ON p.name = 'SQL Server'
AND p.path_locator.GetLevel() = 1
AND c.path_locator.IsDescendantOf(p.path_locator) = 1

-- parents of a specific node
SELECT p.name as ParentName, c.name as ChildName, p.is_directory,
	p.file_stream.GetFileNamespacePath() as ParentPath
FROM dbo.Documents p 
JOIN dbo.Documents c
ON c.name = 'SQLSubdirSomeText.txt'
AND c.path_locator.IsDescendantOf(p.path_locator) = 1;

INSERT dbo.Documents(Name, file_stream) 
VALUES('SyntheticFile.txt', 0x);
GO

DECLARE @path hierarchyid;
DECLARE @pathstring nvarchar(max);
DECLARE @newpath nvarchar(max);

SELECT @pathstring = path_locator.ToString() 
FROM documents 
WHERE name = 'SQL Server' AND path_locator.GetLevel() = 1
SET @newpath = @pathstring +  convert(varchar(20), convert(bigint, substring(convert(binary(16), newid()), 1, 6))) + '.' 
                           +  convert(varchar(20), convert(bigint, substring(convert(binary(16), newid()), 7, 6))) + '.' 
						   +  convert(varchar(20), convert(bigint, substring(convert(binary(16), newid()), 13, 4))) + '/';

--insert dbo.Documents(Name, path_locator, file_stream) values('SubSyntheticFile.txt', @pathstring + '1/', 0x)
INSERT dbo.Documents(Name, path_locator, file_stream) 
VALUES('SubSyntheticFile2.txt', @newpath, 0x);
GO

-- not allowed
UPDATE dbo.Documents 
SET parent_path_locator = NULL
WHERE name = 'SubSyntheticFile2.txt'
go

-- new synthetic hierarchyid
DECLARE @pathstring nvarchar(max);
DECLARE @newpath nvarchar(max);
SELECT @pathstring = path_locator.ToString() 
FROM documents 
WHERE name = 'SQLServerSubdir' AND path_locator.GetLevel() = 2;
SET @newpath = @pathstring +  convert(varchar(20), convert(bigint, substring(convert(binary(16), newid()), 1, 6))) + '.' 
                           +  convert(varchar(20), convert(bigint, substring(convert(binary(16), newid()), 7, 6))) + '.' 
						   +  convert(varchar(20), convert(bigint, substring(convert(binary(16), newid()), 13, 4))) + '/';
UPDATE dbo.Documents 
SET path_locator = @newpath
WHERE name = 'SubSyntheticFile2.txt'
GO

-- OK, now use Reparent to move it back
DECLARE @oldpath hierarchyid, @newpath hierarchyid 
SELECT @oldpath = path_locator 
FROM documents 
WHERE name = 'SQLServerSubdir' AND path_locator.GetLevel() = 2;
SELECT @newpath = path_locator 
FROM documents 
WHERE name = 'SQL Server' AND path_locator.GetLevel() = 1;
UPDATE dbo.Documents 
SET path_locator = path_locator.GetReparentedValue(@oldpath, @newpath)
WHERE name = 'SubSyntheticFile2.txt';
GO

-- Here's the BOL proposed use for GetPathLocator():

-- you'd use path locator to hook up your additional metadata table
-- Add a path locator column to the PhotoMetadata table.
ALTER TABLE PhotoMetadata 
ADD pathlocator hierarchyid;

-- Get the root path of the Photo directory on the File Server.
DECLARE @UNCPathRoot varchar(100) = '\\RemoteShare\Photographs';

-- Get the root path of the FileTable.
DECLARE @FileTableRoot varchar(1000);
SELECT @FileTableRoot = FileTableRootPath('dbo.PhotoTable');

-- This is for moving documents from a UNC path to filetable
-- Where another table has a reference to the UNC path
-- Update the PhotoMetadata table.
-- Replace the File Server UNC path with the FileTable path.
UPDATE PhotoMetadata
    SET UNCPath = REPLACE(UNCPath, @UNCPathRoot, @FileTableRoot);

-- Update the pathlocator column to contain the pathlocator IDs from the FileTable.
UPDATE PhotoMetadata
    SET pathlocator = GetPathLocator(UNCPath);

-- Additional functions found by intellisence
select GENDBNAMEFROMPATH('Path') -- ?

-- can't use newid in a function
CREATE FUNCTION random_hierarchyid(@parent varchar(max))
RETURNS hierarchyid
AS
BEGIN
RETURN
(convert(hierarchyid, @parent +  convert(varchar(20), convert(bigint, substring(convert(binary(16), newid()), 1, 6))) + '.' +     convert(varchar(20), convert(bigint, substring(convert(binary(16), newid()), 7, 6))) + '.' +     convert(varchar(20), convert(bigint, substring(convert(binary(16), newid()), 13, 4))) + '/'))
END

USE master
GO

DROP DATABASE filetab_demo