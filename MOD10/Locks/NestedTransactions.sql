USE tempdb;
GO

CREATE TABLE tbl
(ID int IDENTITY(1,1) PRIMARY KEY,
 Name char(3));
GO

PRINT @@trancount
	BEGIN TRAN
	PRINT @@trancount
	INSERT INTO tbl (Name) VALUES ('aaa');
		BEGIN TRAN
		PRINT @@trancount
		INSERT INTO tbl (Name) VALUES ('bbb');
		SELECT * FROM tbl;
			BEGIN TRAN
			PRINT @@trancount
			UPDATE tbl SET Name = 'ccc' WHERE ID = 1;
		COMMIT TRAN
		PRINT @@trancount
		SELECT * FROM tbl;
	ROLLBACK
PRINT @@trancount
SELECT * FROM tbl;
GO



SELECT request_owner_id, resource_type, request_mode, request_status
FROM sys.dm_tran_locks;



SELECT * FROM dbo.tbl;
GO


CREATE TABLE NewTable 
(Id INT PRIMARY KEY,
Info CHAR(3));
GO

INSERT INTO NewTable VALUES (1, 'aaa');
INSERT INTO NewTable VALUES (2, 'bbb');
INSERT INTO NewTable VALUSE (3, 'ccc'); -- Syntax error.
GO
SELECT * FROM NewTable; -- Returns no rows.
GO

INSERT INTO NewTable VALUES (1, 'aaa');
INSERT INTO NewTable VALUES (2, 'bbb');
INSERT INTO NewTable VALUES (2, 'ccc'); -- PK violations.
GO
SELECT * FROM NewTable; -- Returns no rows.
GO

BEGIN TRAN
INSERT INTO NewTable VALUES (11, 'aaa');
INSERT INTO NewTable VALUES (12, 'bbb');
INSERT INTO NewTable VALUES (12, 'ccc'); -- PK violations.
COMMIT TRAN
GO
SELECT * FROM NewTable; -- Returns no rows.
GO

SET XACT_ABORT ON
GO
BEGIN TRAN
INSERT INTO NewTable VALUES (21, 'aaa');
INSERT INTO NewTable VALUES (22, 'bbb');
INSERT INTO NewTable VALUES (22, 'ccc'); -- PK violations.
COMMIT TRAN
GO
SELECT * FROM NewTable; -- Returns no rows.
GO
SET XACT_ABORT OFF
