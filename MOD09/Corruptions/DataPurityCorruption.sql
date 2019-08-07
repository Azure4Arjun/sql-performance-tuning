-- Run a CHECKDB
DBCC CHECKDB (DemoDataPurity)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO














-- Data purity corruption. Error only gives the page
-- and slot. Let's take a look.

-- Enable DBCC PAGE output to the console
DBCC TRACEON (3604)
GO

DBCC PAGE (DemoDataPurity, 1, 24473, 3); -- slot 91
GO





















-- It's definitely corrupt. Let's see if we can
-- just delete the record. Maybe not a good idea...
USE DemoDataPurity;
GO

sp_helpindex 'Products';
GO

DELETE FROM Products WHERE ProductID = -;
GO



















-- Hmm - ok - we'll need to update it to something
-- for now.
UPDATE Products SET Price = 0.01
WHERE ProductID = 243;
GO

-- Hopefully that fixed it...
DBCC CHECKDB (DemoDataPurity)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO


-- Success. Steps: look at the page to get the
-- index keys. Update the row and set the column
-- to a valid value. Make sure the value makes
-- sense for the application.