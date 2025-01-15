IF OBJECT_ID('dbo.PersonVectors', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.PersonVectors;
END
GO

IF OBJECT_ID('dbo.Person', 'U') IS NOT NULL

BEGIN
    DROP TABLE dbo.Person;
END
GO

CREATE TABLE dbo.Person (
    PersonID INT PRIMARY KEY IDENTITY(1,1), -- Auto-increment primary key
    FirstName NVARCHAR(100),
    MiddleName NVARCHAR(100) NULL,
    LastName NVARCHAR(100),
    Suffix NVARCHAR(50) NULL,
    PreferredName NVARCHAR(100) NULL,
    FullName NVARCHAR(255),
    BirthDate DATE
);
GO

CREATE TABLE dbo.PersonVectors (
    PersonID INT PRIMARY KEY,               -- Foreign key to Person table
    FullNameVector     VECTOR(384) NULL,    -- Combined vector for all attributes
    FirstNameVector    VECTOR(384) NULL,    -- Vector for FirstName
    MiddleNameVector   VECTOR(384) NULL,    -- Vector for MiddleName
    LastNameVector     VECTOR(384) NULL,    -- Vector for LastName
    SuffixVector       VECTOR(384) NULL,    -- Vector for Suffix
    PreferredNameVector VECTOR(384) NULL,   -- Vector for PreferredName
    BirthDateVector    VECTOR(384) NULL,    -- Vector for BirthDate
    CONSTRAINT FK_PersonVectors_Person 
        FOREIGN KEY (PersonID) REFERENCES dbo.Person(PersonID)
);
GO

PRINT 'Tables created successfully.';
GO
