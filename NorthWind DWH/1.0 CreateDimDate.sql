
CREATE TABLE [dbo].[DimDate](
 [DateSK] [int] IDENTITY(1,1) NOT NULL--Use this line if you just want an autoincrementing counter AND COMMENT BELOW LINE
 --[DateSK] [int] NOT NULL--TO MAKE THE ID THE YYYYMMDD FORMAT USE THIS LINE AND COMMENT ABOVE LINE.
 , [Date] [Date] NOT NULL
 , [Day] [char](2) NOT NULL
 , [DaySuffix] [varchar](4) NOT NULL
 , [DayOfWeek] [varchar](9) NOT NULL
 , [DOWInMonth] [TINYINT] NOT NULL
 , [DayOfYear] [int] NOT NULL
 , [WeekOfYear] [tinyint] NOT NULL
 , [WeekOfMonth] [tinyint] NOT NULL
 , [Month] [char](2) NOT NULL
 , [MonthName] [varchar](9) NOT NULL
 , [Quarter] [tinyint] NOT NULL
 , [QuarterName] [varchar](6) NOT NULL
 , [Year] [char](4) NOT NULL
 , [StandardDate] [varchar](10) NULL
 , [HolidayText] [varchar](50) NULL
 CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED 
 (
 [DateSK] ASC
 )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
 ) ON [PRIMARY]

GO


--Populate Date dimension

TRUNCATE TABLE DimDate

--IF YOU ARE USING THE YYYYMMDD format for the primary key then you need to comment out this line.
--DBCC CHECKIDENT (DimDate, RESEED, 60000) --In case you need to add earlier dates later.

DECLARE @tmpDOW TABLE (DOW INT, Cntr INT)--Table for counting DOW occurance in a month
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(1,0)--Used in the loop below
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(2,0)
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(3,0)
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(4,0)
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(5,0)
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(6,0)
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(7,0)

DECLARE @StartDate datetime
 , @EndDate datetime
 , @Date datetime
 , @WDofMonth INT
 , @CurrentMonth INT
 
SELECT @StartDate = '1/7/1996'  -- Set The start and end date 
 , @EndDate = '1/1/2030'--Non inclusive. Stops on the day before this.
 , @CurrentMonth = 1 --Counter used in loop below.

SELECT @Date = @StartDate

WHILE @Date < @EndDate
 BEGIN
 
 IF DATEPART(MONTH,@Date) <> @CurrentMonth 
 BEGIN
 SELECT @CurrentMonth = DATEPART(MONTH,@Date)
 UPDATE @tmpDOW SET Cntr = 0
 END

 UPDATE @tmpDOW
 SET Cntr = Cntr + 1
 WHERE DOW = DATEPART(DW,@DATE)

 SELECT @WDofMonth = Cntr
 FROM @tmpDOW
 WHERE DOW = DATEPART(DW,@DATE) 

 INSERT INTO DimDate
 (
 [DateSK],--TO MAKE THE DateSK THE YYYYMMDD FORMAT UNCOMMENT THIS LINE... Comment for autoincrementing.
 [Date]
 , [Day]
 , [DaySuffix]
 , [DayOfWeek]
 , [DOWInMonth]
 , [DayOfYear]
 , [WeekOfYear]
 , [WeekOfMonth] 
 , [Month]
 , [MonthName]
 , [Quarter]
 , [QuarterName]
 , [Year]
 )
 SELECT CONVERT(VARCHAR,@Date,112), --TO MAKE THE DateSK THE YYYYMMDD FORMAT UNCOMMENT THIS LINE COMMENT FOR AUTOINCREMENT
 @Date [Date]
 , DATEPART(DAY,@DATE) [Day]
 , CASE 
 WHEN DATEPART(DAY,@DATE) IN (11,12,13) THEN CAST(DATEPART(DAY,@DATE) AS VARCHAR) + 'th'
 WHEN RIGHT(DATEPART(DAY,@DATE),1) = 1 THEN CAST(DATEPART(DAY,@DATE) AS VARCHAR) + 'st'
 WHEN RIGHT(DATEPART(DAY,@DATE),1) = 2 THEN CAST(DATEPART(DAY,@DATE) AS VARCHAR) + 'nd'
 WHEN RIGHT(DATEPART(DAY,@DATE),1) = 3 THEN CAST(DATEPART(DAY,@DATE) AS VARCHAR) + 'rd'
 ELSE CAST(DATEPART(DAY,@DATE) AS VARCHAR) + 'th' 
 END AS [DaySuffix]
 , CASE DATEPART(DW, @DATE)
 WHEN 1 THEN 'Sunday'
 WHEN 2 THEN 'Monday'
 WHEN 3 THEN 'Tuesday'
 WHEN 4 THEN 'Wednesday'
 WHEN 5 THEN 'Thursday'
 WHEN 6 THEN 'Friday'
 WHEN 7 THEN 'Saturday'
 END AS [DayOfWeek]
 , @WDofMonth [DOWInMonth]--Occurance of this day in this month. If Third Monday then 3 and DOW would be Monday.
 , DATEPART(dy,@Date) [DayOfYear]--Day of the year. 0 - 365/366
 , DATEPART(ww,@Date) [WeekOfYear]--0-52/53
 , DATEPART(ww,@Date) + 1 -
 DATEPART(ww,CAST(DATEPART(mm,@Date) AS VARCHAR) + '/1/' + CAST(DATEPART(yy,@Date) AS VARCHAR)) [WeekOfMonth]
 , DATEPART(MONTH,@DATE) [Month]--To be converted with leading zero later. 
 , DATENAME(MONTH,@DATE) [MonthName]
 , DATEPART(qq,@DATE) [Quarter]--Calendar quarter
 , CASE DATEPART(qq,@DATE) 
 WHEN 1 THEN 'First'
 WHEN 2 THEN 'Second'
 WHEN 3 THEN 'Third'
 WHEN 4 THEN 'Fourth'
 END AS [QuarterName]
 , DATEPART(YEAR,@Date) [Year]

 SELECT @Date = DATEADD(dd,1,@Date)
 END

--You can replace this code by editing the insert using my functions dbo.DBA_fnAddLeadingZeros
UPDATE dbo.DimDate
 SET [DAY] = '0' + [DAY]
 WHERE LEN([DAY]) = 1

UPDATE dbo.DimDate
 SET [MONTH] = '0' + [MONTH]
 WHERE LEN([MONTH]) = 1

UPDATE dbo.DimDate
 SET STANDARDDATE = [MONTH] + '/' + [DAY] + '/' + [YEAR]

--Add HOLIDAYS --------------------------------------------------------------------------------------------------------------
--THANKSGIVING --------------------------------------------------------------------------------------------------------------
--Fourth THURSDAY in November.
UPDATE DimDate
SET HolidayText = 'Thanksgiving Day'
WHERE [MONTH] = 11 
 AND [DAYOFWEEK] = 'Thursday' 
 AND [DOWInMonth] = 4
GO

--CHRISTMAS -------------------------------------------------------------------------------------------
UPDATE dbo.DimDate
SET HolidayText = 'Christmas Day'
WHERE [MONTH] = 12 AND [DAY] = 25

--4th of July ---------------------------------------------------------------------------------------------
UPDATE dbo.DimDate
SET HolidayText = 'Independance Day'
WHERE [MONTH] = 7 AND [DAY] = 4

-- New Years Day ---------------------------------------------------------------------------------------------
UPDATE dbo.DimDate
SET HolidayText = 'New Year''s Day'
WHERE [MONTH] = 1 AND [DAY] = 1

--Memorial Day ----------------------------------------------------------------------------------------
--Last Monday in May
UPDATE dbo.DimDate
SET HolidayText = 'Memorial Day'
FROM DimDate
WHERE DateSK IN 
 (
 SELECT MAX([DateSK])
 FROM dbo.DimDate
 WHERE [MonthName] = 'May'
 AND [DayOfWeek] = 'Monday'
 GROUP BY [YEAR], [MONTH]
 )
--Labor Day -------------------------------------------------------------------------------------------
--First Monday in September
UPDATE dbo.DimDate
SET HolidayText = 'Labor Day'
FROM DimDate
WHERE DateSK IN 
 (
 SELECT MIN([DateSK])
 FROM dbo.DimDate
 WHERE [MonthName] = 'September'
 AND [DayOfWeek] = 'Monday'
 GROUP BY [YEAR], [MONTH]
 )

-- Valentine's Day ---------------------------------------------------------------------------------------------
UPDATE dbo.DimDate
SET HolidayText = 'Valentine''s Day'
WHERE [MONTH] = 2 AND [DAY] = 14

-- Saint Patrick's Day -----------------------------------------------------------------------------------------
UPDATE dbo.DimDate
SET HolidayText = 'Saint Patrick''s Day'
WHERE [MONTH] = 3 AND [DAY] = 17
GO
--Martin Luthor King Day ---------------------------------------------------------------------------------------
--Third Monday in January starting in 1983
UPDATE DimDate
SET HolidayText = 'Martin Luthor King Jr Day'
WHERE [MONTH] = 1--January
 AND [Dayofweek] = 'Monday'
 AND [YEAR] >= 1983--When holiday was official
 AND [DOWInMonth] = 3--Third X day of current month.
GO
--President's Day ---------------------------------------------------------------------------------------
--Third Monday in February.
UPDATE DimDate
SET HolidayText = 'President''s Day'--select * from DimDate
WHERE [MONTH] = 2--February
 AND [Dayofweek] = 'Monday'
 AND [DOWInMonth] = 3--Third occurance of a monday in this month.
GO
--Mother's Day ---------------------------------------------------------------------------------------
--Second Sunday of May
UPDATE DimDate
SET HolidayText = 'Mother''s Day'--select * from DimDate
WHERE [MONTH] = 5--May
 AND [Dayofweek] = 'Sunday'
 AND [DOWInMonth] = 2--Second occurance of a monday in this month.
GO
--Father's Day ---------------------------------------------------------------------------------------
--Third Sunday of June
UPDATE DimDate
SET HolidayText = 'Father''s Day'--select * from DimDate
WHERE [MONTH] = 6--June
 AND [Dayofweek] = 'Sunday'
 AND [DOWInMonth] = 3--Third occurance of a monday in this month.
GO
--Halloween 10/31 ----------------------------------------------------------------------------------
UPDATE dbo.DimDate
SET HolidayText = 'Halloween'
WHERE [MONTH] = 10 AND [DAY] = 31
--Election Day--------------------------------------------------------------------------------------
--The first Tuesday after the first Monday in November.


CREATE TABLE #tmpHoliday(DateSK INT IDENTITY(1,1), DateID int, Week TINYINT, YEAR CHAR(4), DAY CHAR(2))

INSERT INTO #tmpHoliday(DateID, [YEAR],[DAY])
 SELECT [DateSK], [YEAR], [DAY]
 FROM dbo.DimDate
 WHERE [MONTH] = 11
 AND [Dayofweek] = 'Monday'
 ORDER BY YEAR, DAY

DECLARE @CNTR INT, @POS INT, @STARTYEAR INT, @ENDYEAR INT, @CURRENTYEAR INT, @MINDAY INT

SELECT @CURRENTYEAR = MIN([YEAR])
 , @STARTYEAR = MIN([YEAR])
 , @ENDYEAR = MAX([YEAR])
FROM #tmpHoliday

WHILE @CURRENTYEAR <= @ENDYEAR
 BEGIN
 SELECT @CNTR = COUNT([YEAR])
 FROM #tmpHoliday
 WHERE [YEAR] = @CURRENTYEAR

 SET @POS = 1

 WHILE @POS <= @CNTR
 BEGIN
 SELECT @MINDAY = MIN(DAY)
 FROM #tmpHoliday
 WHERE [YEAR] = @CURRENTYEAR
 AND [WEEK] IS NULL

 UPDATE #tmpHoliday
 SET [WEEK] = @POS
 WHERE [YEAR] = @CURRENTYEAR
 AND [DAY] = @MINDAY

 SELECT @POS = @POS + 1
 END

 SELECT @CURRENTYEAR = @CURRENTYEAR + 1
 END

UPDATE DT
SET HolidayText = 'Election Day'
FROM dbo.DimDate DT
JOIN #tmpHoliday HL
 ON (HL.DateID + 1) = DT.DateSk
WHERE [WEEK] = 1

DROP TABLE #tmpHoliday
GO
--------------------------------------------------------------------------------------------------------
PRINT CONVERT(VARCHAR,GETDATE(),113)--USED FOR CHECKING RUN TIME.

--DimDate indexes---------------------------------------------------------------------------------------------
CREATE UNIQUE NONCLUSTERED INDEX [IDX_DimDate_Date] ON [dbo].[DimDate] 
(
[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IDX_DimDate_Day] ON [dbo].[DimDate] 
(
[Day] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IDX_DimDate_DayOfWeek] ON [dbo].[DimDate] 
(
[DayOfWeek] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IDX_DimDate_DOWInMonth] ON [dbo].[DimDate] 
(
[DOWInMonth] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IDX_DimDate_DayOfYear] ON [dbo].[DimDate] 
(
[DayOfYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IDX_DimDate_WeekOfYear] ON [dbo].[DimDate] 
(
[WeekOfYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IDX_DimDate_WeekOfMonth] ON [dbo].[DimDate] 
(
[WeekOfMonth] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IDX_DimDate_Month] ON [dbo].[DimDate] 
(
[Month] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IDX_DimDate_MonthName] ON [dbo].[DimDate] 
(
[MonthName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IDX_DimDate_Quarter] ON [dbo].[DimDate] 
(
[Quarter] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IDX_DimDate_QuarterName] ON [dbo].[DimDate] 
(
[QuarterName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IDX_DimDate_Year] ON [dbo].[DimDate] 
(
[Year] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IDX_dim_Time_HolidayText] ON [dbo].[DimDate] 
(
[HolidayText] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]

PRINT convert(varchar,getdate(),113)--USED FOR CHECKING RUN TIME.



