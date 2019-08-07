EXEC sp_fulltext_service 'update_languages'
EXEC sp_fulltext_service 'load_os_resources',1
EXEC sp_fulltext_service 'restart_all_fdhosts'
GO
SELECT * FROM sys.fulltext_document_types
