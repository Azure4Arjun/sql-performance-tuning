USE AdventureWorksDW2012;
GO
--IF OBJECT_ID('dbo.FactInternetSalesBig', 'U') IS NOT NULL
--  DROP TABLE dbo.FactInternetSalesBig;
--GO

SELECT TOP 0 
  SalesOrderNumber,
  SalesOrderLineNumber,
  ProductKey, 
  OrderDateKey, 
  CustomerKey, 
  PromotionKey, 
  CurrencyKey, 
  SalesTerritoryKey, 
  OrderQuantity, 
  UnitPrice, 
  SalesAmount, 
  TaxAmt, 
  Freight
INTO dbo.FactInternetSalesBig
FROM dbo.FactInternetSales;
GO

INSERT INTO dbo.FactInternetSalesBig (
  SalesOrderNumber,
  SalesOrderLineNumber,
  ProductKey, 
  OrderDateKey, 
  CustomerKey, 
  PromotionKey, 
  CurrencyKey, 
  SalesTerritoryKey, 
  OrderQuantity, 
  UnitPrice, 
  SalesAmount, 
  TaxAmt, 
  Freight
)
SELECT 
  'SO' + RIGHT('000000000000' + CONVERT(varchar(12), DENSE_RANK() OVER (ORDER BY SalesOrderNumber)+43430), 12) AS SalesOrderNumber,
  SalesOrderLineNumber, ProductKey, OrderDateKey, CustomerKey, PromotionKey, CurrencyKey, SalesTerritoryKey, OrderQuantity, UnitPrice, SalesAmount, TaxAmt, Freight
FROM dbo.FactInternetSales;
GO

INSERT INTO dbo.FactInternetSalesBig (
  SalesOrderNumber,
  SalesOrderLineNumber,
  ProductKey, 
  OrderDateKey, 
  CustomerKey, 
  PromotionKey, 
  CurrencyKey, 
  SalesTerritoryKey, 
  OrderQuantity, 
  UnitPrice, 
  SalesAmount, 
  TaxAmt, 
  Freight
)
SELECT TOP 50000
  'SO' + RIGHT('00000000' + CONVERT(varchar(12), DENSE_RANK() OVER (ORDER BY SalesOrderNumber)+(SELECT MAX(CONVERT(int, RIGHT(SalesOrderNumber, 12))) FROM dbo.FactInternetSalesBig)), 12),
  ROW_NUMBER() OVER (PARTITION BY SalesOrderNumber ORDER BY SalesOrderLineNumber), 
  ProductKey, OrderDateKey, CustomerKey, PromotionKey, CurrencyKey, SalesTerritoryKey, OrderQuantity, UnitPrice, SalesAmount, TaxAmt, Freight
FROM FactInternetSales
ORDER BY NEWID();
CHECKPOINT;
GO 1000

SELECT COUNT(*) FROM dbo.FactInternetSalesBig;
GO

CREATE PARTITION FUNCTION PF_FactInternetSalesBig_OrderDate (int)
AS RANGE RIGHT FOR VALUES (
  20050101, 20050401, 20050701, 20051001,
  20060101, 20060401, 20060701, 20061001,
  20070101, 20070401, 20070701, 20071001,
  20080101, 20080401, 20080701, 20081001
);
GO
CREATE PARTITION SCHEME PS_FactInternetSalesBig_OrderDate
AS 
PARTITION PF_FactInternetSalesBig_OrderDate
ALL TO ([PRIMARY]);
GO

ALTER TABLE dbo.FactInternetSalesBig
ADD CONSTRAINT PK_FactInternetSalesBig_SalesOrderNumber_SalesOrderLineNumber
PRIMARY KEY CLUSTERED (OrderDateKey, SalesOrderNumber, SalesOrderLineNumber)
ON PS_FactInternetSalesBig_OrderDate(OrderDateKey);
GO


CREATE NONCLUSTERED INDEX IX_FactInternetSalesBig_CurrencyKey 
ON dbo.FactInternetSalesBig (CurrencyKey);
GO
CREATE NONCLUSTERED INDEX IX_FactInternetSalesBig_CustomerKey 
ON dbo.FactInternetSalesBig (CustomerKey);
GO
CREATE NONCLUSTERED INDEX IX_FactInternetSalesBig_ProductKey 
ON dbo.FactInternetSalesBig (ProductKey);
GO
CREATE NONCLUSTERED INDEX IX_FactInternetSalesBig_PromotionKey 
ON dbo.FactInternetSalesBig (PromotionKey);
GO

ALTER TABLE dbo.FactInternetSalesBig  
WITH CHECK 
ADD CONSTRAINT FK_FactInternetSalesBig_DimCurrency 
FOREIGN KEY(CurrencyKey)
REFERENCES dbo.DimCurrency (CurrencyKey);
GO
ALTER TABLE dbo.FactInternetSalesBig  
WITH CHECK 
ADD CONSTRAINT FK_FactInternetSalesBig_DimCustomer 
FOREIGN KEY(CustomerKey)
REFERENCES dbo.DimCustomer (CustomerKey);
GO
ALTER TABLE dbo.FactInternetSalesBig  
WITH CHECK 
ADD CONSTRAINT FK_FactInternetSalesBig_DimDate 
FOREIGN KEY(OrderDateKey)
REFERENCES dbo.DimDate (DateKey);
GO
ALTER TABLE dbo.FactInternetSalesBig  
WITH CHECK 
ADD CONSTRAINT FK_FactInternetSalesBig_DimProduct 
FOREIGN KEY(ProductKey)
REFERENCES dbo.DimProduct (ProductKey);
GO
ALTER TABLE dbo.FactInternetSalesBig  
WITH CHECK 
ADD CONSTRAINT FK_FactInternetSalesBig_DimPromotion 
FOREIGN KEY(PromotionKey)
REFERENCES dbo.DimPromotion (PromotionKey);
GO
ALTER TABLE dbo.FactInternetSalesBig  
WITH CHECK 
ADD CONSTRAINT FK_FactInternetSalesBig_DimSalesTerritory 
FOREIGN KEY(SalesTerritoryKey)
REFERENCES dbo.DimSalesTerritory (SalesTerritoryKey);
GO

DROP INDEX IX_CS_FactInternetSalesBig_AllColumns 
ON dbo.FactInternetSalesBig;
GO
CREATE NONCLUSTERED COLUMNSTORE INDEX IX_CS_FactInternetSalesBig_AllColumns
ON dbo.FactInternetSalesBig (
  SalesOrderNumber,
  SalesOrderLineNumber,
  ProductKey, 
  OrderDateKey, 
  CustomerKey, 
  PromotionKey, 
  CurrencyKey, 
  SalesTerritoryKey, 
  OrderQuantity, 
  UnitPrice, 
  SalesAmount, 
  TaxAmt, 
  Freight
);
GO

DROP INDEX IX_FactInternetSalesBig_AllColumns 
ON dbo.FactInternetSalesBig;
GO
CREATE NONCLUSTERED INDEX IX_FactInternetSalesBig_AllColumns
ON dbo.FactInternetSalesBig (
  OrderDateKey,
  SalesOrderNumber,
  SalesOrderLineNumber,
  ProductKey, 
  CustomerKey, 
  PromotionKey, 
  CurrencyKey, 
  SalesTerritoryKey, 
  OrderQuantity, 
  UnitPrice, 
  SalesAmount, 
  TaxAmt, 
  Freight
);
