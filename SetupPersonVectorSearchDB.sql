-------------------------------------------------------------------------------
-- Step 1: If the database PersonVectorSearch exists, drop it
-------------------------------------------------------------------------------
IF DB_ID('PersonVectorSearch') IS NOT NULL
BEGIN
    ALTER DATABASE PersonVectorSearch SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PersonVectorSearch;
END
GO

-------------------------------------------------------------------------------
-- Step 2: Create the database
-------------------------------------------------------------------------------
CREATE DATABASE PersonVectorSearch;
GO

-------------------------------------------------------------------------------
-- Step 3: Use the database
-------------------------------------------------------------------------------
USE PersonVectorSearch;
GO

-------------------------------------------------------------------------------
-- Step 4: If the Person table exists, drop it
-------------------------------------------------------------------------------
IF OBJECT_ID('dbo.Person', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Person;
END
GO

-------------------------------------------------------------------------------
-- Step 5: Create the Person table
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- Step 6: If the PersonVectors table exists, drop it
-------------------------------------------------------------------------------
IF OBJECT_ID('dbo.PersonVectors', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.PersonVectors;
END
GO

-------------------------------------------------------------------------------
-- Step 7: Create the PersonVectors table
-------------------------------------------------------------------------------
CREATE TABLE dbo.PersonVectors (
    PersonID INT PRIMARY KEY,               -- Foreign key to Person table
    FullNameVector     VECTOR(768) NULL,    -- Combined vector for all attributes
    FirstNameVector    VECTOR(128) NULL,    -- Vector for FirstName
    MiddleNameVector   VECTOR(128) NULL,    -- Vector for MiddleName
    LastNameVector     VECTOR(128) NULL,    -- Vector for LastName
    SuffixVector       VECTOR(128) NULL,    -- Vector for Suffix
    PreferredNameVector VECTOR(128) NULL,   -- Vector for PreferredName
    BirthDateVector    VECTOR(128) NULL,    -- Vector for BirthDate
    CONSTRAINT FK_PersonVectors_Person 
        FOREIGN KEY (PersonID) REFERENCES dbo.Person(PersonID)
);
GO

-------------------------------------------------------------------------------
-- Step 8: Drop vector indexes on PersonVectors if they already exist
-------------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_FullNameVector' 
      AND object_id = OBJECT_ID('dbo.PersonVectors')
)
BEGIN
    DROP INDEX IX_FullNameVector ON dbo.PersonVectors;
END
GO

IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_FirstNameVector' 
      AND object_id = OBJECT_ID('dbo.PersonVectors')
)
BEGIN
    DROP INDEX IX_FirstNameVector ON dbo.PersonVectors;
END
GO

IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_MiddleNameVector' 
      AND object_id = OBJECT_ID('dbo.PersonVectors')
)
BEGIN
    DROP INDEX IX_MiddleNameVector ON dbo.PersonVectors;
END
GO

IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_LastNameVector' 
      AND object_id = OBJECT_ID('dbo.PersonVectors')
)
BEGIN
    DROP INDEX IX_LastNameVector ON dbo.PersonVectors;
END
GO

IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_SuffixVector' 
      AND object_id = OBJECT_ID('dbo.PersonVectors')
)
BEGIN
    DROP INDEX IX_SuffixVector ON dbo.PersonVectors;
END
GO

IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_PreferredNameVector' 
      AND object_id = OBJECT_ID('dbo.PersonVectors')
)
BEGIN
    DROP INDEX IX_PreferredNameVector ON dbo.PersonVectors;
END
GO

IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_BirthDateVector' 
      AND object_id = OBJECT_ID('dbo.PersonVectors')
)
BEGIN
    DROP INDEX IX_BirthDateVector ON dbo.PersonVectors;
END
GO

-------------------------------------------------------------------------------
-- Step 9: Create vector indexes for each vector column
-------------------------------------------------------------------------------
CREATE INDEX IX_FullNameVector 
    ON dbo.PersonVectors (FullNameVector) 
    USING VECTOR;
GO

CREATE INDEX IX_FirstNameVector 
    ON dbo.PersonVectors (FirstNameVector) 
    USING VECTOR;
GO

CREATE INDEX IX_MiddleNameVector 
    ON dbo.PersonVectors (MiddleNameVector) 
    USING VECTOR;
GO

CREATE INDEX IX_LastNameVector 
    ON dbo.PersonVectors (LastNameVector) 
    USING VECTOR;
GO

CREATE INDEX IX_SuffixVector 
    ON dbo.PersonVectors (SuffixVector) 
    USING VECTOR;
GO

CREATE INDEX IX_PreferredNameVector 
    ON dbo.PersonVectors (PreferredNameVector) 
    USING VECTOR;
GO

CREATE INDEX IX_BirthDateVector 
    ON dbo.PersonVectors (BirthDateVector) 
    USING VECTOR;
GO

-------------------------------------------------------------------------------
-- Done
-------------------------------------------------------------------------------
PRINT 'Database, tables, and indexes (re)created successfully.';
GO
