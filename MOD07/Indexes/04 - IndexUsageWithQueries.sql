USE Credit
GO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ChargeCL')
	DROP TABLE ChargeCL;
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ChargeHeap')
	DROP TABLE ChargeHeap;
GO

SELECT *
INTO ChargeCL
FROM Charge

CREATE CLUSTERED INDEX ChargeCL_CLInd 
ON ChargeCL (member_no, charge_no)

SELECT *
INTO ChargeHeap
FROM Charge
GO

CREATE INDEX ChargeHeap_NCInd 
ON ChargeHeap (Charge_no)
CREATE INDEX ChargeCL_NCInd 
ON ChargeCL (Charge_no)
GO

SELECT Charge_no 
FROM ChargeCL
WHERE Charge_no = 12345

SELECT Charge_no 
FROM ChargeHeap
WHERE Charge_no = 12345
GO

SELECT Charge_no 
FROM ChargeCL
WHERE Charge_no BETWEEN 100 and 500

SELECT Charge_no 
FROM ChargeHeap
WHERE Charge_no BETWEEN 100 and 500
GO


SELECT Charge_no 
FROM ChargeCL

SELECT Charge_no 
FROM ChargeHeap
GO

SELECT * 
FROM ChargeCL 
WHERE Charge_no = 12345

SELECT * 
FROM ChargeCL WITH(INDEX(1))
WHERE Charge_no = 12345
GO

SELECT * 
FROM ChargeCL
WHERE Charge_no < 1600

SELECT * 
FROM ChargeCL WITH(INDEX(1))
WHERE Charge_no < 1600
GO

SELECT * 
FROM ChargeCL
WHERE Charge_no < 2929

SELECT * 
FROM ChargeCL
WHERE Charge_no < 2930
GO

SELECT * 
FROM ChargeCL
WHERE Charge_no < 32000

SELECT * 
FROM ChargeCL WITH(INDEX(ChargeCL_NCInd))
WHERE Charge_no < 32000
