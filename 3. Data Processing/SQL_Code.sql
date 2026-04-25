----------------------------------------------------
--Viewing the User Profile and Viewership Tables
----------------------------------------------------
SELECT *
FROM workspace.bright_tv_analysis.user_profiles;

SELECT *
FROM workspace.bright_tv_analysis.viewership;

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
      ,TO_DATE(RecordDate2) AS RecordDate
      ,date_format(`Duration 2`, 'HH:mm:ss') AS Duration
      ,YEAR(`RecordDate`) AS Record_Year
      ,date_format(`RecordDate2`, 'HH:mm:ss') AS Time_UTC
      ,date_format(from_utc_timestamp(`Time_UTC`, 'Africa/Johannesburg'), 'HH:mm:ss') AS Time_of_Day
      FROM workspace.bright_tv_analysis.viewership;

-----------------------------------------------------------------
--Converting new column for Duration from string to integer value
-----------------------------------------------------------------

ALTER TABLE workspace.bright_tv_analysis.viewership1
ADD COLUMN Duration_Minutes INT;

UPDATE workspace.bright_tv_analysis.viewership1
SET Duration_Minutes = CAST(
    ROUND(
        hour(to_timestamp(Duration, 'HH:mm:ss')) * 3600
      + minute(to_timestamp(Duration, 'HH:mm:ss')) * 60.0
      + second(to_timestamp(Duration, 'HH:mm:ss'))
    ) AS INT
);

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
      ,v.Duration_Minutes
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
        WHEN age BETWEEN 0 AND 6 THEN 'Early_Childhood'
        WHEN age BETWEEN 6 AND 12 THEN 'School_Age'
        WHEN age BETWEEN 13 AND 18 THEN 'Teenagers'
        WHEN age BETWEEN 19 AND 24 THEN 'Youth'
        WHEN age BETWEEN 25 AND 34 THEN 'Young Adults'
        WHEN age BETWEEN 35 AND 44 THEN 'Mid Adults'
        WHEN age BETWEEN 45 AND 54 THEN 'Mature Adults'
        WHEN age BETWEEN 55 AND 59 THEN 'Pre-Seniors'
        WHEN age BETWEEN 60 AND 74 THEN 'Young Seniors'
        WHEN age BETWEEN 75 AND 84 THEN 'Seniors'
        WHEN age BETWEEN 85 AND 99 THEN 'Elderly'
        WHEN age BETWEEN 100 AND 115 THEN 'Centenarians'
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

------------------------------------------------
--Checking the Date Range
-------------------------------------------------
---When was the start of data collection?
SELECT MIN(RecordDate) AS min_date 
FROM workspace.bright_tv_analysis.users_viewership;
-- Data was collected from this date 2016-01-01

---When was the last data collected?
SELECT MAX(RecordDate) AS latest_date 
FROM workspace.bright_tv_analysis.users_viewership;
-- Data was collected from this date 2016-03-31
--The duration of the data spans across 3 months

--------------------------------------------------
--How many registered viewers were in this survey?
--------------------------------------------------
SELECT COUNT(DISTINCT UserID)
      ,COUNT(DISTINCT Channel2)
FROM workspace.bright_tv_analysis.users_viewership;
-- 5375 TV viewers

---------------------------------------------------
--What are the top 5 most watched channels?
---------------------------------------------------
SELECT DISTINCT Channel2
      ,COUNT(DISTINCT UserID) AS Total_Viewers
FROM workspace.bright_tv_analysis.users_viewership
WHERE Channel2 IS NOT NULL
AND Channel2 != 'Break in transmission'
GROUP BY Channel2
ORDER BY Total_Viewers DESC
LIMIT 5;
--Most watched channels are Supersport Live Events,ICC Cricket World Cup 2011
--Channel O,SuperSport Blitz and Trace TV

---------------------------------------------------
--What are the 5 least watched channels?
---------------------------------------------------
SELECT DISTINCT Channel2
      ,COUNT(DISTINCT UserID) AS Total_Viewers
FROM workspace.bright_tv_analysis.users_viewership
WHERE Channel2 IS NOT NULL
AND Channel2 != 'Break in transmission'
GROUP BY Channel2
ORDER BY Total_Viewers ASC
LIMIT 5;
--Least watched channels are Live on SuperSport, Wimbledon
-- Sawsee, SuperSport Live Events and MK

--Updating the entry SuperSport Live Events to Supersport Live Events

UPDATE workspace.bright_tv_analysis.viewership1
SET `Channel2` = REPLACE (`Channel2`,'SuperSport Live Events','Supersport Live Events')
WHERE `Channel2` = 'SuperSport Live Events';

---------------------------------------------------
--What are the 5 least watched channels?
---------------------------------------------------
SELECT DISTINCT Channel2
      ,COUNT(DISTINCT UserID) AS Total_Viewers
FROM workspace.bright_tv_analysis.users_viewership
WHERE Channel2 IS NOT NULL
AND Channel2 != 'Break in transmission'
GROUP BY Channel2
ORDER BY Total_Viewers ASC
LIMIT 5;

SELECT DISTINCT Channel2
      ,COUNT(DISTINCT UserID) AS Total_Viewers
FROM workspace.bright_tv_analysis.users_viewership
WHERE Channel2 IS NOT NULL
AND Channel2 != 'Break in transmission'
GROUP BY Channel2
ORDER BY Total_Viewers ASC
LIMIT 5;
--Least watched channels are therefore Live on SuperSport, Wimbledon
-- Sawsee, MK and kykNET

------------------------------------------------------------
--Identifying number of transmission breakdowns per province
------------------------------------------------------------
SELECT PROVINCE,
       COUNT(Channel2) AS Transmission_Breakdowns
FROM workspace.bright_tv_analysis.users_viewership
WHERE Channel2 LIKE '%Break%'
GROUP BY PROVINCE
ORDER BY Transmission_Breakdowns DESC;
--Gauteng and Western Cape recorded the highest breaks in transmission

------------------------------------------------------------
--Which periods experience most transmission breakdowns in 
--Gauteng and Western Cape?
------------------------------------------------------------
SELECT Province
      ,COUNT(Channel2)
       ,
        CASE
          WHEN Dayname(RecordDate) IN ('Sun', 'Sat') THEN 'Weekend'
          ELSE 'Weekday'
      END AS Day_Classification 
FROM workspace.bright_tv_analysis.users_viewership
WHERE Channel2 LIKE '%Break%' AND Province IN ('Gauteng','Western Cape')
GROUP BY Province
        ,Day_Classification;
--Most transmission breakdowns happen during Weekdays

------------------------------------------------------------
--Identifying number of transmission breakdowns per province
------------------------------------------------------------
SELECT PROVINCE,
       COUNT(Channel2)
FROM workspace.bright_tv_analysis.users_viewership
WHERE Channel2 LIKE '%Break%'
GROUP BY PROVINCE;
--Gauteng and Western Cape experience the highest transmission breakdowns

------------------------------------------------------------
-- Which race watches TV the most?
------------------------------------------------------------
SELECT Race
      ,COUNT(Race) AS Number_of_People
FROM workspace.bright_tv_analysis.users_viewership
WHERE Race != 'Unknown'
GROUP BY Race
ORDER BY Number_of_People DESC;
--The race with the highest Bright TV viewership is Black people.

----------------------------------------------------------------------
--Which channels have viewers watching them for longer hours?
---------------------------------------------------------------------

SELECT Channel2
      ,ROUND(SUM(unix_timestamp(to_timestamp(Duration, 'HH:mm:ss'))/3600)) AS Total_Duration_Hours
      ,ROUND(MAX(unix_timestamp(to_timestamp(Duration, 'HH:mm:ss'))/60)) AS Max_Duration_Minutes
      ,ROUND(AVG(unix_timestamp(to_timestamp(Duration, 'HH:mm:ss'))/60)) AS Mean_Duration_Minutes
FROM workspace.bright_tv_analysis.users_viewership
GROUP BY Channel2
ORDER BY Max_Duration_Minutes DESC;
---Sports and Music channels are watched for longer time durations. ICC World Cup 2011 boosted viewership


SELECT *
FROM workspace.bright_tv_analysis.viewership1





