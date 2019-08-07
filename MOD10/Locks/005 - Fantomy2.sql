USE AdventureWorks2012;

BEGIN TRANSACTION;

INSERT INTO [Person].[BusinessEntity]
           ([rowguid]
           ,[ModifiedDate])
     VALUES
           (NEWID()
           ,CURRENT_TIMESTAMP);

DECLARE @Scope_Identity int;

SELECT @Scope_Identity = SCOPE_IDENTITY();

INSERT INTO [Person].[Person]
           ([BusinessEntityID]
           ,[PersonType]
           ,[NameStyle]
           ,[Title]
           ,[FirstName]
           ,[MiddleName]
           ,[LastName]
           ,[Suffix]
           ,[EmailPromotion]
           ,[AdditionalContactInfo]
           ,[Demographics]
           ,[rowguid]
           ,[ModifiedDate])
     VALUES
           (@Scope_Identity
           ,'EM'
           ,'0'
           ,'Mr.'
           ,'James'
           ,'Anthony'
           ,'A'
           ,Null
           ,0
           ,Null
           ,Null
           ,NEWID()
           ,CURRENT_TIMESTAMP
           );

EXEC SP_EXECUTESQL 
N'PRINT ''DELETE FROM Person.Person WHERE BusinessEntityID = '' +CAST(@Scope_Identity as varchar(8));
  PRINT ''DELETE FROM Person.BusinessEntity WHERE BusinessEntityID = '' +CAST(@Scope_Identity as varchar(8));'
  ,N'@Scope_Identity int',@Scope_Identity = @Scope_Identity

SELECT @Scope_Identity as BusinessEntityID

COMMIT TRANSACTION;
