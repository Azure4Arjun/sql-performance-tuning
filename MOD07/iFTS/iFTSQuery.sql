USE AdventureWorks2008R2
GO

/*

CONTAINS i FREETEXT
CREATE Catalog and iFTS Index on Person.AdditionalContactInfo
*/

SELECT FirstName, CAST(AdditionalContactInfo AS VARCHAR(MAX))
FROM Person.Person
WHERE CONTAINS(*,'"additional phone"'); 


SELECT FirstName,AdditionalContactInfo
FROM Person.Person
WHERE CONTAINS(*,'phone')
AND Title = 'Mr.'; 


SELECT FirstName 
FROM Person.Person
WHERE CONTAINS(*,'"family" AND "bicycles"');


SELECT FirstName 
FROM Person.Person
WHERE CONTAINS(*,'phone NEAR urgent');


SELECT FirstName 
FROM Person.Person
WHERE CONTAINS(*,'FORMSOF(INFLECTIONAL,bicycle)');


SELECT FirstName 
FROM Person.Person
WHERE FREETEXT(*,'"additional phone"'); 

/*
CONTAINSTABLE i FREETEXTTABLE
*/

SELECT * 
FROM CONTAINSTABLE(Person.Person,*,'"additional phone"')
ORDER BY RANK DESC; 


SELECT P.FirstName , CT.RANK
FROM CONTAINSTABLE(Person.Person,*,'"additional phone"') AS CT
JOIN Person.Person AS P ON CT.[KEY]=P.BusinessEntityID
WHERE CT.RANK >100; 


SELECT P.FirstName , CT.RANK
FROM CONTAINSTABLE(Person.Person,*,'ISABOUT (bicycles WEIGHT (.6), road WEIGHT (.2), Mountain WEIGHT (.2))') AS CT
JOIN Person.Person AS P ON CT.[KEY]=P.BusinessEntityID
ORDER BY CT.RANK DESC; 


SELECT special_term,display_term 
FROM sys.dm_fts_parser (' "I am an experienced and versatile" ', 1033, 0, 0);


SELECT special_term,display_term 
FROM sys.dm_fts_parser (' "I am an experienced and versatile" ', 1033, NULL, 0);


SELECT special_term,display_term 
FROM sys.dm_fts_parser (' "multi-million" ', 1033, 0, 0);


SELECT special_term,display_term
FROM sys.dm_fts_parser (' "multi-million" ', 1040, 0, 0);


