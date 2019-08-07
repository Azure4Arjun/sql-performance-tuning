

IF OBJECT_ID ('t1') IS NOT NULL DROP TABLE t1;
GO

CREATE TABLE t1 (c1 INT, c2 VARCHAR (8000));
CREATE CLUSTERED INDEX t1c1 ON t1 (c1);
GO

SET NOCOUNT ON;
GO
DECLARE @count INT;
SET @count = 0;
WHILE (@count < 1000)
BEGIN
	INSERT INTO t1 VALUES (@count, REPLICATE ('a', 8000));
	SET @count = @count + 1;
END;


-- This won't do an physical IOs (as the index is in the buffer pool
-- and doesn't have any fragmentation) but it will spin the CPU while
-- it processes the index.
WHILE (1 = 1) ALTER INDEX t1c1 ON t1 REORGANIZE;