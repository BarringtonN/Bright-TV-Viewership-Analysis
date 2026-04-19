----------------------------------------------------
--Viewing the User Profile and Viewership Tables
----------------------------------------------------
SELECT *
FROM workspace.bright_tv_analysis.user_profiles AS up;

SELECT *
FROM workspace.bright_tv_analysis.viewership AS v
LEFT JOIN workspace.bright_tv_analysis.user_profiles AS up
ON v.UserID0 = up.UserID;

-------------------------------------------------
                 --DATA CLEANING
-------------------------------------------------
--1. Checking for Duplicates

SELECT UserID,
       COUNT(UserID) AS NumberID
FROM workspace.bright_tv_analysis.user_profiles
GROUP BY UserID
HAVING (NumberID > 1);
--No duplicates found 


SELECT UserID0,
       COUNT(DISTINCT UserID0) AS NumberID0
       FROM workspace.bright_tv_analysis.viewership
GROUP BY UserID0 
HAVING (NumberID0 > 1);
--No duplicates found 

----------------------------------------------
--Converting UTC time to South African time
----------------------------------------------

SELECT *
      ,from_utc_timestamp(`RecordDate2`, 'Africa/Johannesburg') AS SA_Time
 FROM workspace.bright_tv_analysis.viewership;

-------------------------------
--2. Checking for NULL values
-------------------------------
SELECT *
FROM workspace.bright_tv_analysis.user_profiles
WHERE UserID IS NULL OR
      Name IS NULL OR
      Surname IS NULL OR
      Email IS NULL OR
      Gender IS NULL OR
      Race IS NULL OR
      Age IS NULL OR
      Province IS NULL OR
      "Social Media Handle" IS NULL;
--No NULL values found

SELECT *
FROM workspace.bright_tv_analysis.viewership
WHERE UserID0 IS NULL OR
      Channel2 IS NULL OR
      RecordDate2 IS NULL OR
      "Duration 2" IS NULL OR
      userid4 IS NULL;
--No NULL values found

--Checking for Empty values
SELECT UserID,
       COUNT(DISTINCT UserID)
FROM workspace.bright_tv_analysis.user_profiles
WHERE Name = ' ' OR
      Surname = ' ' OR
      Email = ' ' OR
      Gender = ' ' OR
      Race = ' ' OR
      Province = ' ' OR
      "Social Media Handle" = ' '
GROUP BY UserID;
-- 231 users have empty values

--4. Renaming None and Empty entries

UPDATE workspace.bright_tv_analysis.user_profiles
SET Gender = REPLACE (Gender,'None','Not_Given')
WHERE Gender = 'None';

UPDATE workspace.bright_tv_analysis.user_profiles
SET Gender = REPLACE (Gender,' ','Not_Given')
WHERE Gender = ' ';

UPDATE workspace.bright_tv_analysis.user_profiles
SET Name = REPLACE (Name,'None','No_Name')
WHERE Name = 'None';

UPDATE workspace.bright_tv_analysis.user_profiles
SET Surname = REPLACE (Surname,'None','No_Surname')
WHERE Surname = 'None';

UPDATE workspace.bright_tv_analysis.user_profiles
SET Email = REPLACE (Email,'None','Not_Provided')
WHERE Email = 'None';

UPDATE workspace.bright_tv_analysis.user_profiles
SET Race = REPLACE (Race,'None','Unknown')
WHERE Race = 'None';

UPDATE workspace.bright_tv_analysis.user_profiles
SET Race = REPLACE (Race,' ','Unknown')
WHERE Race = ' ';

UPDATE workspace.bright_tv_analysis.user_profiles
SET Province = REPLACE (Province,'None','Not_Stated')
WHERE Province = 'None';

UPDATE workspace.bright_tv_analysis.user_profiles
SET Province = REPLACE (Province,' ','Not_Stated')
WHERE Province = ' ';

UPDATE workspace.bright_tv_analysis.user_profiles
SET `Social Media Handle` = REPLACE (`Social Media Handle`,'None','No_Handle')
WHERE `Social Media Handle` = 'None';

SELECT *
FROM workspace.bright_tv_analysis.user_profiles;

--Removing unwanted spacing
SELECT TRIM(Name) AS Name,
       TRIM(Surname) AS Surname,
       TRIM(Email) AS Email,
       TRIM(Gender) AS Gender,
       TRIM(Race) AS Race,
       TRIM(Province) AS Province,
       TRIM(`Social Media Handle`) AS Social_Media_Handle
FROM workspace.bright_tv_analysis.user_profiles;

---------------------------------------------------------------
--Extracting the Record Date,Duration and Year from a Timestamp
---------------------------------------------------------------
SELECT *
,TO_DATE(RecordDate2) AS RecordDate
,date_format(`Duration 2`, 'HH:mm:ss') AS Duration
,YEAR(`RecordDate`) AS Record_Year
,from_utc_timestamp(`RecordDate2`, 'Africa/Johannesburg') AS SA_Time
,date_format(`SA_Time`, 'HH:mm:ss') AS Time_of_Day
FROM workspace.bright_tv_analysis.viewership;

--------------------------------------------------------------------------------------
--Creating a new table from the User_Profile and Viewership tables using the Left Join 
--------------------------------------------------------------------------------------

CREATE TABLE viewership1
SELECT `UserID0`
      ,`Channel2`
      ,`userid4`
      ,TO_DATE(RecordDate2) AS RecordDate
      ,date_format(`Duration 2`, 'HH:mm:ss') AS Duration
      ,YEAR(`RecordDate`) AS Record_Year
      ,date_format(`RecordDate2`, 'HH:mm:ss') AS Time_UTC
      ,date_format(from_utc_timestamp(`Time_UTC`, 'Africa/Johannesburg'), 'HH:mm:ss') AS Time_of_Day
      FROM workspace.bright_tv_analysis.viewership;

SELECT *
FROM workspace.bright_tv_analysis.viewership1;

-------------------------------------
--Creating a VIEW from the new table
-------------------------------------
CREATE VIEW users_viewership AS
SELECT u.UserID
      ,u.Surname
      ,u.Gender
      ,u.Race
      ,u.Age
      ,u.Province
      ,v.Channel2
      ,v.RecordDate
      ,v.Duration
      ,v.Record_Year
      ,v.Time_of_Day
FROM workspace.bright_tv_analysis.user_profiles u
LEFT JOIN workspace.bright_tv_analysis.viewership1 v
ON u.UserID = v.UserID0;

-------------------------------------------------------
--Identifying ages of youngest viewer and oldest viewer
-------------------------------------------------------

SELECT min(Age) AS Youngest_Viewer
      ,max(Age) AS Oldest_Viewer
FROM workspace.bright_tv_analysis.users_viewership;
--Age of viewers ranges from 0 to 114 years old

--------------------------------
--Creating viewers' age buckets
--------------------------------
SELECT * , 
      
    CASE
        WHEN age BETWEEN 0 AND 6 THEN 'Early_Childhood (0–6)'
        WHEN age BETWEEN 6 AND 12 THEN 'School_Age (6–12)'
        WHEN age BETWEEN 13 AND 18 THEN 'Teenagers (13–17)'
        WHEN age BETWEEN 19 AND 24 THEN 'Youth (18–24)'
        WHEN age BETWEEN 25 AND 34 THEN 'Young Adults (25–34)'
        WHEN age BETWEEN 35 AND 44 THEN 'Mid Adults (35–44)'
        WHEN age BETWEEN 45 AND 54 THEN 'Mature Adults (45–54)'
        WHEN age BETWEEN 55 AND 59 THEN 'Pre-Seniors (55–64)'
        WHEN age BETWEEN 60 AND 74 THEN 'Young Seniors (65–74)'
        WHEN age BETWEEN 75 AND 84 THEN 'Seniors (75–84)'
        WHEN age BETWEEN 85 AND 99 THEN 'Elderly (85–99)'
        WHEN age BETWEEN 100 AND 115 THEN 'Centenarians (100–115)'
        ELSE 'Unknown'
    END AS Age_Category
    ,

    -----------------------------------
    --Creating viewership time buckets
    -----------------------------------
    CASE
        WHEN date_format(Time_of_Day, 'HH:mm:ss') BETWEEN '00:00:00' AND '04:59:59' THEN 'Overnight'
        WHEN date_format(Time_of_Day, 'HH:mm:ss') BETWEEN '05:00:00' AND '08:59:59' THEN 'Early Morning'
        WHEN date_format(Time_of_Day, 'HH:mm:ss') BETWEEN '09:00:00' AND '12:59:59' THEN 'Late Morning'
        WHEN date_format(Time_of_Day, 'HH:mm:ss') BETWEEN '13:00:00' AND '16:59:59' THEN 'Afternoon'
        WHEN date_format(Time_of_Day, 'HH:mm:ss') BETWEEN '17:00:00' AND '18:59:59' THEN 'Early Evening'
        WHEN date_format(Time_of_Day, 'HH:mm:ss') BETWEEN '19:00:00' AND '21:59:59' THEN 'Prime Time'
        WHEN date_format(Time_of_Day, 'HH:mm:ss') BETWEEN '22:00:00' AND '23:59:59' THEN 'Late Night'       
        ELSE 'Unknown'
    END AS Time_Period,
  
    CASE
          WHEN Dayname(RecordDate) IN ('Sun', 'Sat') THEN 'Weekend'
          ELSE 'Weekday'
      END AS Day_Classification    
FROM workspace.bright_tv_analysis.users_viewership;





