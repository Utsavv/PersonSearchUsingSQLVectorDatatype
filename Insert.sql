
------------------------------------------------------------------------------
-- 1) Create a temp table #SampleNames
------------------------------------------------------------------------------

CREATE TABLE #SampleNames (
    FirstName NVARCHAR(100),
    LastName  NVARCHAR(100)
);

INSERT INTO #SampleNames (FirstName, LastName)
SELECT NameValue, NULL 
FROM 
(
    VALUES    
    ('John'),('Jane'),('Michael'),('Emily'),('Robert'),('Linda'),('William'),
    ('Elizabeth'),('James'),('Mary'),('David'),('Jennifer'),('Richard'),
    ('Patricia'),('Charles'),('Barbara'),('Joseph'),('Susan'),('Thomas'),
    ('Jessica'),('Christopher'),('Sarah'),('Daniel'),('Karen'),('Paul'),
    ('Nancy'),('Mark'),('Lisa'),('Donald'),('Betty'),
    ('Aarav'),('Aanya'),('Vihaan'),('Ishaan'),('Ananya'),('Arjun'),('Diya'),
    ('Aditya'),('Riya'),('Kavya'),('Rohan'),('Aryan'),('Saanvi'),('Meera'),
    ('Krishna'),('Nitya'),('Rahul'),('Sneha'),('Karan'),('Manav'),('Priya'),
    ('Arnav'),('Ira'),('Siddharth'),('Tara'),('Varun'),('Aditi'),('Neha'),
    ('Shiv'),('Radhika'),('Gaurav'),('Nikhil'),('Amrita'),('Rajesh'),('Komal'),
    ('Yash'),('Pooja'),('Harsh'),('Kiran'),('Akash'),('Sonia'),('Anil'),
    ('Swati'),('Abhishek'),('Mansi'),('Rakesh'),('Chitra'),('Suresh'),
    ('Shruti'),('Vikram'),('Geeta'),('Vivek'),('Seema'),('Kunal'),('Deepa'),
    ('Mohit'),('Bhavna'),('Jay'),('Sarita'),('Rohit'),('Ajay'),('Alok'),
    ('Payal'),('Sanjay'),
    ('Samantha'),('Alexander'),('Nicholas'),('Victoria'),('Olivia'),('Ethan'),
    ('Noah'),('Liam'),('Emma'),('Ava'),('Sophia'),('Mason'),('Isabella'),
    ('Amelia'),('Elijah'),('Logan'),('Mia'),('Charlotte'),('Zoe'),('Max'),
    ('Leo'),('Claire')
) AS t(NameValue);

-------------------------------------------------------------------------------
-- 2) Update #SampleNames with multiple last names
-------------------------------------------------------------------------------

UPDATE #SampleNames
SET LastName = LN.LastName
FROM #SampleNames
CROSS APPLY 
(
    VALUES     
    ('Smith'),('Johnson'),('Williams'),('Brown'),('Jones'),('Garcia'),
    ('Miller'),('Davis'),('Rodriguez'),('Martinez'),('Hernandez'),('Wilson'),
    ('Taylor'),('Anderson'),('Thomas'),('Moore'),('Jackson'),
    ('Sharma'),('Gupta'),('Kumar'),('Mehta'),('Reddy'),('Verma'),('Singh'),
    ('Patel'),('Choudhary'),('Malhotra'),('Kapoor'),('Iyer'),('Rao'),
    ('Banerjee'),('Saxena'),('Joshi'),('Nair'),('Ghosh'),('Agarwal'),
    ('Bose'),('Das'),('Pandey'),('Roy'),('Chatterjee'),('Sen'),('Menon'),
    ('Mukherjee'),('Tripathi'),('Sethi'),('Thakur'),('Desai'),('Bhatt'),
    ('Bhatnagar'),('Sinha'),('Mahajan'),('Kulkarni'),('Rastogi'),('Bajaj'),
    ('Chopra'),('Narayan'),('Pillai'),
    ('Adams'),('Baker'),('Clark'),('Evans'),('Collins'),('Carter'),('Morris'),
    ('Bell'),('Ward'),('Young'),('Robinson'),('Wright'),('King'),('Lopez'),
    ('Green'),('Hall'),('Lewis'),('Walker'),('Perez'),('Scott'),('White'),
    ('Harris'),('Turner'),('Parker')
) AS LN(LastName)
WHERE #SampleNames.LastName IS NULL;

-------------------------------------------------------------------------------
-- 3) Set NOCOUNT and gather the distinct first and last names
-------------------------------------------------------------------------------

SET NOCOUNT ON;

DECLARE @MaxFirst INT = (
    SELECT COUNT(DISTINCT FirstName) 
    FROM #SampleNames
);
DECLARE @MaxLast INT  = (
    SELECT COUNT(DISTINCT LastName)  
    FROM #SampleNames
);

-------------------------------------------------------------------------------
-- 4) Control how many records to insert using @NumberOfRecords
-------------------------------------------------------------------------------

DECLARE @NumberOfRecords INT = 1000;  -- <==== Change this to desired count

-------------------------------------------------------------------------------
-- 5) Build row numbers (up to 1M) in a CTE using digits approach
-------------------------------------------------------------------------------

WITH Digits AS (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL
    SELECT 3        UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
    SELECT 6        UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
    SELECT 9
),
Numbers AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS num
    FROM Digits  AS d1
    CROSS JOIN Digits AS d2
    CROSS JOIN Digits AS d3
    CROSS JOIN Digits AS d4
    CROSS JOIN Digits AS d5
    CROSS JOIN Digits AS d6
    -- This yields up to 1,000,000 rows (10^6)
)

-------------------------------------------------------------------------------
-- 6) Insert into Person using the calculated row numbers
-------------------------------------------------------------------------------

INSERT INTO Person
(
  FirstName,
  MiddleName,
  LastName,
  Suffix,
  PreferredName,
  FullName,
  BirthDate
)
SELECT
    -- Pick the FirstName based on (num mod @MaxFirst).
    FN.FirstName,
    
    -- MiddleName every 10th row
    CASE WHEN N.num % 10 = 0 
         THEN CONCAT('MiddleName_', N.num) 
         ELSE NULL 
    END AS MiddleName,

    -- Pick the LastName based on (num mod @MaxLast).
    LN.LastName,

    -- Suffix every 50th row
    CASE WHEN N.num % 50 = 0 
         THEN CONCAT('Suffix_', N.num) 
         ELSE NULL 
    END AS Suffix,

    CONCAT(FN.FirstName, '_Preferred') AS PreferredName,
    CONCAT(FN.FirstName, ' ', LN.LastName) AS FullName,

    -- Some variation of BirthDate, e.g. up to ~27 yrs
    DATEADD(DAY, -(N.num % 10000), GETDATE()) AS BirthDate
FROM Numbers AS N
CROSS JOIN 
(
    SELECT 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn,
        FirstName
    FROM #SampleNames
    GROUP BY FirstName
) AS FN
CROSS JOIN 
(
    SELECT 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn,
        LastName
    FROM #SampleNames
    GROUP BY LastName
) AS LN
WHERE N.num <= @NumberOfRecords
  AND FN.rn = (N.num % @MaxFirst) + 1
  AND LN.rn = (N.num % @MaxLast) + 1
OPTION (MAXDOP 1);  -- optional: helps avoid huge parallel plan overhead

-------------------------------------------------------------------------------
-- 7) Clean up and notify
-------------------------------------------------------------------------------

SET NOCOUNT OFF;

DROP TABLE #SampleNames;

PRINT CAST(@NumberOfRecords AS VARCHAR(20)) + ' records inserted into the Person table.';
GO
