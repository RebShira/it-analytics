USE [ITAnalytics]
GO

/****** Object:  StoredProcedure [dbo].[sp_rptBudgetActual]    Script Date: 8/14/2023 6:04:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/*
STORED PROC:	[ITAnalytics].[dbo].[sp_rptBudgetActual]
PURPOSE:		Nightly refresh of data for Budget vs. Actual report.

TO RUN:			EXEC [ITAnalytics].[dbo].[sp_rptBudgetActual]

ABJ 3/1/2023 - Removed residual, undesired records for RAD actuals that should not be in report, i.e. glAccounts that don't 
begin with "855X"
*/

CREATE PROCEDURE	[dbo].[sp_rptBudgetActual]
AS

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@ BUDGET @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

-- rptBudgetActual, formerly budgetfle20XX

IF OBJECT_ID(N'[EliteLive].[dbo].[rptBudgetActual]', N'U') IS NOT NULL  
   DROP TABLE [EliteLive].[dbo].[rptBudgetActual]

CREATE TABLE [EliteLive].[dbo].[rptBudgetActual](
	[AMP] [varchar](6) NULL,
	[AMPNAME] [varchar](75) NULL,
	[MGRNAME] [varchar](75) NULL,
	[DIRNAME] [varchar](75) NULL,
	[CHIEFNAME] [varchar](75) NULL,
	[TOTBUDAMT] [float] NULL,
	[MBUDAMT] [float] NULL,
	[YBUDAMT] [float] NULL,
	[GLACCT] [char](21) NULL,
	[ACCT] [char](6) NULL,
	[DESCRIPT] [varchar](150) NULL,
	[MAMTA] [float] NULL,
	[MVARIANCE] [float] NULL,
	[MPER] [float] NULL,
	[YAMTA] [float] NULL,
	[YVARIANCE] [float] NULL,
	[YPER] [float] NULL,
	[AVAILABLE] [float] NULL,
	[PEREXP] [float] NULL,
	[SEG] [CHAR](2) NULL,
	[NOBUDGET] BIT NULL,
	[IS_AGGREGATE] BIT NULL,
	[ETLDATE] VARCHAR(40) NULL
)

INSERT INTO [EliteLive].[dbo].[rptBudgetActual]
(AMP, AMPNAME, GLACCT, ACCT, DESCRIPT, TOTBUDAMT, MBUDAMT, YBUDAMT, SEG, NOBUDGET, IS_AGGREGATE)
SELECT case
       when glAccount_3.AccountSegment = '3001' then '3001LG'
       when glAccount_4.AccountSegment = '5003' then '5003'
       when glAccount_1.AccountSegment < '4000' and glAccount_1.AccountSegment > '0000' 
           or glAccount_1.AccountSegment > '5000' then glAccount_1.AccountSegment 
       else glAccount_3.AccountSegment end AS AMP,  
       (case
	   when glAccount_1.AccountSegment = '2006' then 'STEPHEN CRANE VILLAGE'
	   when glAccount_1.AccountSegment = '2025' then 'JAMES C WHITE MANOR'
	   when glAccount_1.AccountSegment = '3010' then 'WYNONA LIPMAN'
	   when glAccount_1.AccountSegment = '3011' then 'RIVERSIDE VILLA'
	   else RTRIM(LTRIM(UPPER(glAccount_3.Description)))
	   end) AS AMPNAME,
       glAccount_4.AccountSegment + '-' + glAccount_2.AccountSegment + '-' +
       glAccount_1.AccountSegment + '-' + glAccount_3.AccountSegment AS GLACCT,  
       glAccount_2.AccountSegment AS ACCT, 
	   LTRIM(glAccount_2.[Description]) AS DESCRIPT,
	   (ROUND([EliteLive].[dbo].[glBudgetDetail].TotalBudgetAmount, 2)) AS TOTAMT,
	   (ROUND([EliteLive].[dbo].[glBudgetDetail].TotalBudgetAmount/12, 2)) AS MBUDAMT,
	   ((ROUND([EliteLive].[dbo].[glBudgetDetail].TotalBudgetAmount/12, 2)) * MONTH(GETDATE())) AS YBUDAMT,
	   '' AS SEG, 
	   0 AS NOBUDGET,
	   0 AS IS_AGGREGATE      
FROM   [EliteLive].[dbo].[glAccount] AS glAccount_3 RIGHT OUTER JOIN
       [EliteLive].[dbo].[glAccount] AS glAccount_2 RIGHT OUTER JOIN
       [EliteLive].[dbo].[glBudgetDetail] INNER JOIN

       [EliteLive].[dbo].[glAccount] AS glAccount_4 
	   ON [EliteLive].[dbo].glBudgetDetail.fkglAccount1 = glAccount_4.PK INNER JOIN

       [EliteLive].[dbo].[glBudgetHeader] 
	   ON [EliteLive].[dbo].[glBudgetDetail].fkglBudgetHeader = [EliteLive].[dbo].[glBudgetHeader].PK LEFT OUTER JOIN

       [EliteLive].[dbo].[glAccount] 
	   ON [EliteLive].[dbo].[glBudgetDetail].fkglAccount5 = [EliteLive].[dbo].[glAccount].PK 
	   ON glAccount_2.PK = [EliteLive].[dbo].glBudgetDetail.fkglAccount2 LEFT OUTER JOIN

       [EliteLive].[dbo].[glAccount] AS glAccount_1 
	   ON [EliteLive].[dbo].[glBudgetDetail].fkglAccount3 = glAccount_1.PK 
	   ON glAccount_3.PK = [EliteLive].[dbo].[glBudgetDetail].fkglAccount4

WHERE  ([EliteLive].[dbo].[glBudgetHeader].[Revision] LIKE '%' + CAST(YEAR(GETDATE()) AS CHAR(4)) + '%')
AND  ([EliteLive].[dbo].[glBudgetHeader].[Revision] NOT LIKE '%Capital%' )               
ORDER BY AMP, glAccount_3.AccountSegment, GLACCT

-- Weed out invalid AMPS.
DELETE FROM [EliteLive].[dbo].[rptBudgetActual]
WHERE (AMP < '1100') OR (AMP = '0015')

-- Weed out any undesirable artifacts that might come through to RAD. Just in case...
DELETE FROM [EliteLive].[dbo].[rptBudgetActual]
WHERE AMP IN ('2006', '2025', '3010', '3011')
AND AMP = LEFT(GLACCT, 4)

-- Weed out AMP 2009 and any "UNASSIGNED" AMPs
DELETE FROM [EliteLive].[dbo].[rptBudgetActual]
WHERE (
(AMP = '2009')
OR (AMPNAME = 'UNASSIGNED')
)


UPDATE  [EliteLive].[dbo].[rptBudgetActual] SET AMP = '4331' WHERE GLACCT = '4000-919024-4000-4331' 
UPDATE  [EliteLive].[dbo].[rptBudgetActual] SET AMP = '4331' WHERE GLACCT = '4000-919018-4000-4331' 
UPDATE  [EliteLive].[dbo].[rptBudgetActual] SET AMP = '4331' WHERE GLACCT = '4000-943020-4000-4331' 
UPDATE  [EliteLive].[dbo].[rptBudgetActual] SET AMP = '4331' WHERE GLACCT = '4000-962010-4000-4331' 

UPDATE  [EliteLive].[dbo].[rptBudgetActual] SET DESCRIPT = 'SUNDRY - FURN/FIXTURES NONCAP' WHERE GLACCT = '4000-919024-4000-4331' 
UPDATE  [EliteLive].[dbo].[rptBudgetActual] SET DESCRIPT = 'SUNDRY - MEETING COSTS' WHERE GLACCT = '4000-919018-4000-4331' 
UPDATE  [EliteLive].[dbo].[rptBudgetActual] SET DESCRIPT = 'CONTRACT COSTS - GLASS'  WHERE GLACCT = '4000-943020-4000-4331' 
UPDATE  [EliteLive].[dbo].[rptBudgetActual] SET DESCRIPT = 'COMPENSATED ABSENCES'  WHERE GLACCT = '4000-962010-4000-4331' 

DELETE FROM [EliteLive].[dbo].[rptBudgetActual] WHERE AMP = '3004' AND SUBSTRING(GLACCT,18,4) = '0035'
DELETE FROM [EliteLive].[dbo].[rptBudgetActual] WHERE AMP = '3006' AND SUBSTRING(GLACCT,18,4) = '0053'
DELETE FROM [EliteLive].[dbo].[rptBudgetActual] WHERE AMP = '3003' AND SUBSTRING(GLACCT,18,4) = '0041'
DELETE FROM [EliteLive].[dbo].[rptBudgetActual] WHERE AMP = '3002' AND SUBSTRING(GLACCT,18,4) = '0029'
UPDATE [EliteLive].[dbo].[rptBudgetActual] SET GLACCT = '3002-943007-3002-0027' WHERE GLACCT = '3002-943007-3002-0009'
UPDATE [EliteLive].[dbo].[rptBudgetActual] SET GLACCT = '3002-943010-3002-0027' WHERE GLACCT = '3002-943010-3002-0028'
UPDATE [EliteLive].[dbo].[rptBudgetActual] SET GLACCT = '3002-961030-3002-0027' WHERE GLACCT = '3002-961030-3002-0000'
DELETE FROM [EliteLive].[dbo].[rptBudgetActual] WHERE AMP = '3001' AND SUBSTRING(GLACCT,18,4) = '0026'

DELETE FROM [EliteLive].[dbo].[rptBudgetActual] 
WHERE SUBSTRING(GLACCT,13,4) = '3006' 
AND SUBSTRING(GLACCT,18,4) <> '0037'

DELETE FROM [EliteLive].[dbo].[rptBudgetActual] 
WHERE SUBSTRING(GLACCT,1,4) = '9000'


-- Fill in managers, chiefs etc. Set NULLs and unknowns to blank strings.

UPDATE			b
SET				b.MGRNAME = CONCAT(s.Manager_fname, ' ', s.Manager_lname)
				, b.DIRNAME = CONCAT(s.Director_fname, ' ', s.Director_lname)
				, b.CHIEFNAME = CONCAT(s.Chief_fname, ' ', s.Chief_lname)
FROM			[EliteLive].[dbo].[rptBudgetActual] b
INNER JOIN		[ITAnalytics].[dbo].[vw_site_personnel] s
ON				b.AMP = s.site_no

UPDATE			[EliteLive].[dbo].[rptBudgetActual]
SET				MGRNAME = ''
WHERE			(MGRNAME IS NULL OR MGRNAME LIKE 'unknown%')

UPDATE			[EliteLive].[dbo].[rptBudgetActual]
SET				DIRNAME = ''
WHERE			(DIRNAME IS NULL OR DIRNAME LIKE 'unknown%')

UPDATE			[EliteLive].[dbo].[rptBudgetActual]
SET				CHIEFNAME = ''
WHERE			(CHIEFNAME IS NULL OR MGRNAME LIKE 'CHIEFNAME%')


/*
@@@@@@@@@@@@@@@@@@@@@@@@@@ ACTUAL @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

-- rptActualDetail, formerly tapdyemphsys20XX, 
-- to be rolled up as rptActualAggregate, formerly some variant of ACTEXPDY(xx)



IF OBJECT_ID(N'[EliteLive].[dbo].[rptActualDetail]', N'U') IS NOT NULL  
   DROP TABLE [EliteLive].[dbo].[rptActualDetail]  


CREATE TABLE [EliteLive].[dbo].[rptActualDetail] (GLACCT CHAR(21)
								, DESCRIPT VARCHAR(50)
								, FUND CHAR(4)
								, ACCT CHAR(6)
								, AMP VARCHAR(6)
								, DEPT CHAR(4)
								, DTRS CHAR(10)
								, NAMOUNT FLOAT);

WITH data1 AS
(
SELECT		T2.Combination AS GLACCT
			, T5.[Description] AS DESCRIPT
			, SUBSTRING(T2.combination,1,4) AS SEG1
			, SUBSTRING(T2.combination,6,6) AS SEG2
			, SUBSTRING(T2.combination,13,4) AS SEG3
			, SUBSTRING(T2.combination,18,4) AS SEG4
			, CONVERT(VARCHAR(10), T1.PostToDate, 101) AS DTRS
			, T1.DistAmount AS NAMOUNT
FROM		[EliteLive].[dbo].[glPost] AS T1
INNER JOIN	[EliteLive].[dbo].[glvalid] AS T2 ON T1.fkGLValid = T2.PK
INNER JOIN	[EliteLive].[dbo].[glAccountingPeriod] AS T3 ON T1.fkglAccountingPeriod = T3.PK
INNER JOIN	[EliteLive].[dbo].[glFiscalYear] AS T4 ON T3.fkglFiscalYear = T4.PK
INNER JOIN	[EliteLive].[dbo].[glAccount] AS T5 ON SUBSTRING(T2.combination,6,6) = T5.AccountSegment
WHERE		YEAR(T4.PeriodStart) = YEAR(GETDATE())
AND			T3.PeriodNumber between 0 and 12
AND			((SUBSTRING(T2.combination,6,1) in ('7', '9') 
			OR SUBSTRING(T2.Combination,6,6) in 
			('100100','211802','211805', '211807', '211813')))
AND			fkMLSosCodeEntryType = '2202'
),
data2 AS
(
SELECT		GLACCT
			, DESCRIPT
			, SEG1 AS FUND
			, SEG2 AS ACCT
			, (CASE
			WHEN SEG3 = '4000' THEN
				CASE
				WHEN SEG4 = '3001' THEN '3001LG'
				ELSE SEG4
				END
			ELSE SEG3
			END
			) AS AMP
			, (CASE 
			WHEN SEG3 = '4000' THEN SEG1
			ELSE SEG4
			END
			) AS DEPT
			, DTRS
			, NAMOUNT
FROM		data1
)
INSERT INTO	[EliteLive].[dbo].[rptActualDetail] 
			(GLACCT, DESCRIPT, FUND, ACCT, AMP, DEPT, DTRS, NAMOUNT)
SELECT		GLACCT
			, DESCRIPT
			, FUND
			, ACCT
			, AMP
			, DEPT
			, DTRS
			, NAMOUNT 
FROM		data2

-- ABJ 3/1/2023
DELETE FROM		[EliteLive].[dbo].[rptActualDetail]
WHERE			AMP in ('2006', '2025', '3010', '3011')
AND				FUND = AMP

DELETE FROM		[EliteLive].[dbo].[rptActualDetail]
WHERE			AMP IN ('0015', '2009')

PRINT 'BEGINNING ROGUE UPDATES...'
UPDATE [EliteLive].[dbo].[rptActualDetail] set namount = namount * -1 where substring(GLACCT, 1, 1) = '7'
UPDATE [EliteLive].[dbo].[rptActualDetail] set namount = namount * -1 where substring(GLACCT, 1, 6) = '100100'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-703000-2002-0002'  WHERE GLACCT = '2002-703000-2002-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-703000-2009-0009'  WHERE GLACCT = '2009-703000-2009-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-943001-2009-0009'  WHERE GLACCT = '2009-943001-2009-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-703000-2014-0010'  WHERE GLACCT = '2014-703000-2014-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-704004-2014-0010'  WHERE GLACCT = '2014-704004-2014-0010'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '4000-917000-4000-4999'  WHERE GLACCT = '4000-917000-2019-4999'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2021-703000-2021-0019'  WHERE GLACCT = '2021-703000-2021-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2021-945000-2021-0019'  WHERE GLACCT = '2021-945000-2021-0046'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-703000-2022-0020'  WHERE GLACCT = '2022-703000-2022-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2023-919016-2023-0021'  WHERE GLACCT = '2023-919016-2023-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-703000-3001-0022'  WHERE GLACCT = '3001-703000-3001-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-703000-3001-0022'  WHERE GLACCT = '3001-703000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-703000-3001-0022'  WHERE GLACCT = '3001-703000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-703000-3001-0022'  WHERE GLACCT = '3001-703000-3001-0025'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-703000-3001-0022'  WHERE GLACCT = '3001-703000-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-704001-3001-0022'  WHERE GLACCT = '3001-704001-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-704004-3001-0022'  WHERE GLACCT = '3001-704004-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-704004-3001-0022'  WHERE GLACCT = '3001-704004-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-704004-3001-0022'  WHERE GLACCT = '3001-704004-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-704004-3001-0022'  WHERE GLACCT = '3001-704004-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-915000-3001-0022'  WHERE GLACCT = '3001-915000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-915000-3001-0022'  WHERE GLACCT = '3001-915000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-915000-3001-0022'  WHERE GLACCT = '3001-915000-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-916000-3001-0022'  WHERE GLACCT = '3001-916000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-917000-3001-0022'  WHERE GLACCT = '3001-917000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-917000-3001-0022'  WHERE GLACCT = '3001-917000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-917000-3001-0022'  WHERE GLACCT = '3001-917000-3001-0025'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-917000-3001-0022'  WHERE GLACCT = '3001-917000-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-919026-3001-0022'  WHERE GLACCT = '3001-919026-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-942004-3001-0022'  WHERE GLACCT = '3001-942004-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-942008-3001-0022'  WHERE GLACCT = '3001-942008-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943000-3001-0022'  WHERE GLACCT = '3001-943000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943000-3001-0022'  WHERE GLACCT = '3001-943000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943001-3001-0022'  WHERE GLACCT = '3001-943001-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943007-3001-0022'  WHERE GLACCT = '3001-943007-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943033-3001-0022'  WHERE GLACCT = '3001-943033-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-967011-3001-0022'  WHERE GLACCT = '3001-967011-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-967011-3001-0022'  WHERE GLACCT = '3001-967011-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-967011-3001-0022'  WHERE GLACCT = '3001-967011-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-981000-3001-0022'  WHERE GLACCT = '3001-981000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-981000-3001-0022'  WHERE GLACCT = '3001-981000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-981000-3001-0022'  WHERE GLACCT = '3001-981000-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-981001-3001-0022'  WHERE GLACCT = '3001-981001-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-981001-3001-0022'  WHERE GLACCT = '3001-981001-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-981001-3001-0022'  WHERE GLACCT = '3001-981001-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-981002-3001-0022'  WHERE GLACCT = '3001-981002-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-981002-3001-0022'  WHERE GLACCT = '3001-981002-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-981002-3001-0022'  WHERE GLACCT = '3001-981002-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-982000-3001-0022'  WHERE GLACCT = '3001-982000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-982000-3001-0022'  WHERE GLACCT = '3001-982000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-982000-3001-0022'  WHERE GLACCT = '3001-982000-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-982001-3001-0022'  WHERE GLACCT = '3001-982001-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-982001-3001-0022'  WHERE GLACCT = '3001-982001-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-982001-3001-0022'  WHERE GLACCT = '3001-982001-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-982002-3001-0022'  WHERE GLACCT = '3001-982002-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-982002-3001-0022'  WHERE GLACCT = '3001-982002-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-982002-3001-0022'  WHERE GLACCT = '3001-982002-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-984000-3001-0022'  WHERE GLACCT = '3001-984000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-984000-3001-0022'  WHERE GLACCT = '3001-984000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-985000-3001-0022'  WHERE GLACCT = '3001-985000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-985000-3001-0022'  WHERE GLACCT = '3001-985000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-985000-3001-0022'  WHERE GLACCT = '3001-985000-3001-0025'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-985000-3001-0022'  WHERE GLACCT = '3001-985000-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-703000-3002-0027'  WHERE GLACCT = '3002-703000-3002-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-703000-3002-0027'  WHERE GLACCT = '3002-703000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-704000-3002-0027'  WHERE GLACCT = '3002-704000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-704001-3002-0027'  WHERE GLACCT = '3002-704001-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-704004-3002-0027'  WHERE GLACCT = '3002-704004-3002-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-704004-3002-0027'  WHERE GLACCT = '3002-704004-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-704004-3002-0027'  WHERE GLACCT = '3002-704004-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-915000-3002-0027'  WHERE GLACCT = '3002-915000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-917000-3002-0027'  WHERE GLACCT = '3002-917000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-942003-3002-0027'  WHERE GLACCT = '3002-942003-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-942004-3002-0027'  WHERE GLACCT = '3002-942004-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-943000-3002-0027'  WHERE GLACCT = '3002-943000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-943001-3002-0027'  WHERE GLACCT = '3002-943001-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-943007-3002-0027'  WHERE GLACCT = '3002-943007-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-945000-3002-0027'  WHERE GLACCT = '3002-945000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-961030-3002-0027'  WHERE GLACCT = '3002-961030-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-961030-3002-0027'  WHERE GLACCT = '3002-961030-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-964000-3002-0027'  WHERE GLACCT = '3002-964000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-967011-3002-0027'  WHERE GLACCT = '3002-967011-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-967011-3002-0027'  WHERE GLACCT = '3002-967011-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-981000-3002-0027'  WHERE GLACCT = '3002-981000-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-981000-3002-0027'  WHERE GLACCT = '3002-981000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-981001-3002-0027'  WHERE GLACCT = '3002-981001-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-981001-3002-0027'  WHERE GLACCT = '3002-981001-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-981002-3002-0027'  WHERE GLACCT = '3002-981002-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-981002-3002-0027'  WHERE GLACCT = '3002-981002-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-982000-3002-0027'  WHERE GLACCT = '3002-982000-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-982000-3002-0027'  WHERE GLACCT = '3002-982000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-982001-3002-0027'  WHERE GLACCT = '3002-982001-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-982001-3002-0027'  WHERE GLACCT = '3002-982001-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-982002-3002-0027'  WHERE GLACCT = '3002-982002-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-982002-3002-0027'  WHERE GLACCT = '3002-982002-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-984000-3002-0027'  WHERE GLACCT = '3002-984000-3002-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-984000-3002-0027'  WHERE GLACCT = '3002-984000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-985000-3002-0027'  WHERE GLACCT = '3002-985000-3002-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-985000-3002-0027'  WHERE GLACCT = '3002-985000-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-985000-3002-0027'  WHERE GLACCT = '3002-985000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-986000-3002-0027'  WHERE GLACCT = '3002-986000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-986002-3002-0027'  WHERE GLACCT = '3002-986002-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-986003-3002-0027'  WHERE GLACCT = '3002-986003-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-986024-3002-0027'  WHERE GLACCT = '3002-986024-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-986026-3002-0027'  WHERE GLACCT = '3002-986026-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-986033-3002-0027'  WHERE GLACCT = '3002-986033-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-703000-3003-0030'  WHERE GLACCT = '3003-703000-3003-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-703000-3003-0030'  WHERE GLACCT = '3003-703000-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-703000-3003-0030'  WHERE GLACCT = '3003-703000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-703000-3003-0030'  WHERE GLACCT = '3003-703000-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-704004-3003-0030'  WHERE GLACCT = '3003-704004-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-704004-3003-0030'  WHERE GLACCT = '3003-704004-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-704004-3003-0030'  WHERE GLACCT = '3003-704004-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-704004-3003-0030'  WHERE GLACCT = '3003-704004-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-914001-3003-0030'  WHERE GLACCT = '3003-914001-3003-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-915000-3003-0030'  WHERE GLACCT = '3003-915000-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-915000-3003-0030'  WHERE GLACCT = '3003-915000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-915000-3003-0030'  WHERE GLACCT = '3003-915000-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-917000-3003-0030'  WHERE GLACCT = '3003-917000-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-917000-3003-0030'  WHERE GLACCT = '3003-917000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-917000-3003-0030'  WHERE GLACCT = '3003-917000-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-918001-3003-0030'  WHERE GLACCT = '3003-918001-3003-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-924000-3003-0030'  WHERE GLACCT = '3003-924000-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942004-3003-0030'  WHERE GLACCT = '3003-942004-3003-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942005-3003-0030'  WHERE GLACCT = '3003-942005-3003-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942020-3003-0030'  WHERE GLACCT = '3003-942020-3003-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942020-3003-0030'  WHERE GLACCT = '3003-942020-3003-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942023-3003-0030'  WHERE GLACCT = '3003-942023-3003-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942025-3003-0030'  WHERE GLACCT = '3003-942025-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943000-3003-0030'  WHERE GLACCT = '3003-943000-3003-0031'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943007-3003-0030'  WHERE GLACCT = '3003-943007-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-945000-3003-0030'  WHERE GLACCT = '3003-945000-3003-0034'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-964000-3003-0030'  WHERE GLACCT = '3003-964000-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-967011-3003-0030'  WHERE GLACCT = '3003-967011-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-981000-3003-0030'  WHERE GLACCT = '3003-981000-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-981000-3003-0030'  WHERE GLACCT = '3003-981000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-981000-3003-0030'  WHERE GLACCT = '3003-981000-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-981001-3003-0030'  WHERE GLACCT = '3003-981001-3003-0031'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-981001-3003-0030'  WHERE GLACCT = '3003-981001-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-981001-3003-0030'  WHERE GLACCT = '3003-981001-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-981001-3003-0030'  WHERE GLACCT = '3003-981001-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-981002-3003-0030'  WHERE GLACCT = '3003-981002-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-981002-3003-0030'  WHERE GLACCT = '3003-981002-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-981002-3003-0030'  WHERE GLACCT = '3003-981002-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-982000-3003-0030'  WHERE GLACCT = '3003-982000-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-982000-3003-0030'  WHERE GLACCT = '3003-982000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-982000-3003-0030'  WHERE GLACCT = '3003-982000-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-982001-3003-0030'  WHERE GLACCT = '3003-982001-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-982001-3003-0030'  WHERE GLACCT = '3003-982001-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-982001-3003-0030'  WHERE GLACCT = '3003-982001-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-982002-3003-0030'  WHERE GLACCT = '3003-982002-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-982002-3003-0030'  WHERE GLACCT = '3003-982002-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-982002-3003-0030'  WHERE GLACCT = '3003-982002-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-984000-3003-0030'  WHERE GLACCT = '3003-984000-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-984000-3003-0030'  WHERE GLACCT = '3003-984000-3003-0031'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-984000-3003-0030'  WHERE GLACCT = '3003-984000-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-985000-3003-0030'  WHERE GLACCT = '3003-985000-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-985000-3003-0030'  WHERE GLACCT = '3003-985000-3003-0031'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-985000-3003-0030'  WHERE GLACCT = '3003-985000-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-985000-3003-0030'  WHERE GLACCT = '3003-985000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-985000-3003-0030'  WHERE GLACCT = '3003-985000-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-986033-3003-0030'  WHERE GLACCT = '3003-986033-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-986060-3003-0030'  WHERE GLACCT = '3003-986060-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-703000-3004-0034'  WHERE GLACCT = '3004-703000-3004-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-703000-3004-0034'  WHERE GLACCT = '3004-703000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-704001-3004-0034'  WHERE GLACCT = '3004-704001-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-704004-3004-0034'  WHERE GLACCT = '3004-704004-3004-0034'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-704004-3004-0034'  WHERE GLACCT = '3004-704004-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-915000-3004-0034'  WHERE GLACCT = '3004-915000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-917000-3004-0034'  WHERE GLACCT = '3004-917000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-919023-3004-0034'  WHERE GLACCT = '3004-919023-3004-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-919023-3004-0034'  WHERE GLACCT = '3004-919023-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-924000-3004-0034'  WHERE GLACCT = '3004-924000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-932000-3004-0034'  WHERE GLACCT = '3004-932000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-933000-3004-0034'  WHERE GLACCT = '3004-933000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-943000-3004-0034'  WHERE GLACCT = '3004-943000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-943001-3004-0034'  WHERE GLACCT = '3004-943001-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-943007-3004-0034'  WHERE GLACCT = '3004-943007-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-952000-3004-0034'  WHERE GLACCT = '3004-952000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-967011-3004-0034'  WHERE GLACCT = '3004-967011-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-981000-3004-0034'  WHERE GLACCT = '3004-981000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-981001-3004-0034'  WHERE GLACCT = '3004-981001-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-981002-3004-0034'  WHERE GLACCT = '3004-981002-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-982000-3004-0034'  WHERE GLACCT = '3004-982000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-982001-3004-0034'  WHERE GLACCT = '3004-982001-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-982002-3004-0034'  WHERE GLACCT = '3004-982002-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-984000-3004-0034'  WHERE GLACCT = '3004-984000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-985000-3004-0034'  WHERE GLACCT = '3004-985000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986000-3004-0034'  WHERE GLACCT = '3004-986000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986002-3004-0034'  WHERE GLACCT = '3004-986002-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986003-3004-0034'  WHERE GLACCT = '3004-986003-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986024-3004-0034'  WHERE GLACCT = '3004-986024-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986026-3004-0034'  WHERE GLACCT = '3004-986026-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986033-3004-0034'  WHERE GLACCT = '3004-986033-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986060-3004-0034'  WHERE GLACCT = '3004-986060-3004-0034'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986060-3004-0034'  WHERE GLACCT = '3004-986060-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-703000-3006-0037'  WHERE GLACCT = '3006-703000-3006-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-703000-3006-0037'  WHERE GLACCT = '3006-703000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-703000-3006-0037'  WHERE GLACCT = '3006-703000-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-703000-3006-0037'  WHERE GLACCT = '3006-703000-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-703000-3006-0037'  WHERE GLACCT = '3006-703000-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-703000-3006-0037'  WHERE GLACCT = '3006-703000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704001-3006-0037'  WHERE GLACCT = '3006-704001-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704001-3006-0037'  WHERE GLACCT = '3006-704001-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704001-3006-0037'  WHERE GLACCT = '3006-704001-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704001-3006-0037'  WHERE GLACCT = '3006-704001-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704001-3006-0037'  WHERE GLACCT = '3006-704001-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704004-3006-0037'  WHERE GLACCT = '3006-704004-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704004-3006-0037'  WHERE GLACCT = '3006-704004-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704004-3006-0037'  WHERE GLACCT = '3006-704004-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704004-3006-0037'  WHERE GLACCT = '3006-704004-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704004-3006-0037'  WHERE GLACCT = '3006-704004-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704004-3006-0037'  WHERE GLACCT = '3006-704004-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-915000-3006-0037'  WHERE GLACCT = '3006-915000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-915000-3006-0037'  WHERE GLACCT = '3006-915000-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-915000-3006-0037'  WHERE GLACCT = '3006-915000-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-915000-3006-0037'  WHERE GLACCT = '3006-915000-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-915000-3006-0037'  WHERE GLACCT = '3006-915000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-917000-3006-0037'  WHERE GLACCT = '3006-917000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-917000-3006-0037'  WHERE GLACCT = '3006-917000-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-917000-3006-0037'  WHERE GLACCT = '3006-917000-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-917000-3006-0037'  WHERE GLACCT = '3006-917000-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-917000-3006-0037'  WHERE GLACCT = '3006-917000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-932000-3006-0037'  WHERE GLACCT = '3006-932000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-942003-3006-0037'  WHERE GLACCT = '3006-942003-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-942003-3006-0037'  WHERE GLACCT = '3006-942003-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-945000-3006-0037'  WHERE GLACCT = '3006-945000-3006-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-964000-3006-0037'  WHERE GLACCT = '3006-964000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-964000-3006-0037'  WHERE GLACCT = '3006-964000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981000-3006-0037'  WHERE GLACCT = '3006-981000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981000-3006-0037'  WHERE GLACCT = '3006-981000-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981000-3006-0037'  WHERE GLACCT = '3006-981000-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981000-3006-0037'  WHERE GLACCT = '3006-981000-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981000-3006-0037'  WHERE GLACCT = '3006-981000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981001-3006-0037'  WHERE GLACCT = '3006-981001-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981001-3006-0037'  WHERE GLACCT = '3006-981001-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981001-3006-0037'  WHERE GLACCT = '3006-981001-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981001-3006-0037'  WHERE GLACCT = '3006-981001-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981001-3006-0037'  WHERE GLACCT = '3006-981001-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981002-3006-0037'  WHERE GLACCT = '3006-981002-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981002-3006-0037'  WHERE GLACCT = '3006-981002-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981002-3006-0037'  WHERE GLACCT = '3006-981002-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981002-3006-0037'  WHERE GLACCT = '3006-981002-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-981002-3006-0037'  WHERE GLACCT = '3006-981002-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982000-3006-0037'  WHERE GLACCT = '3006-982000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982000-3006-0037'  WHERE GLACCT = '3006-982000-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982000-3006-0037'  WHERE GLACCT = '3006-982000-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982000-3006-0037'  WHERE GLACCT = '3006-982000-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982000-3006-0037'  WHERE GLACCT = '3006-982000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982001-3006-0037'  WHERE GLACCT = '3006-982001-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982001-3006-0037'  WHERE GLACCT = '3006-982001-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982001-3006-0037'  WHERE GLACCT = '3006-982001-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982001-3006-0037'  WHERE GLACCT = '3006-982001-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982001-3006-0037'  WHERE GLACCT = '3006-982001-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982002-3006-0037'  WHERE GLACCT = '3006-982002-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982002-3006-0037'  WHERE GLACCT = '3006-982002-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982002-3006-0037'  WHERE GLACCT = '3006-982002-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982002-3006-0037'  WHERE GLACCT = '3006-982002-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-982002-3006-0037'  WHERE GLACCT = '3006-982002-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-984000-3006-0037'  WHERE GLACCT = '3006-984000-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-984000-3006-0037'  WHERE GLACCT = '3006-984000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-985000-3006-0037'  WHERE GLACCT = '3006-985000-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-985000-3006-0037'  WHERE GLACCT = '3006-985000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-985000-3006-0037'  WHERE GLACCT = '3006-985000-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-985000-3006-0037'  WHERE GLACCT = '3006-985000-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-985000-3006-0037'  WHERE GLACCT = '3006-985000-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-985000-3006-0037'  WHERE GLACCT = '3006-985000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-986060-3006-0037'  WHERE GLACCT = '3006-986060-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-703000-3007-0040'  WHERE GLACCT = '3007-703000-3007-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-703000-3007-0040'  WHERE GLACCT = '3007-703000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-703000-3007-0040'  WHERE GLACCT = '3007-703000-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-703000-3007-0040'  WHERE GLACCT = '3007-703000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-704004-3007-0040'  WHERE GLACCT = '3007-704004-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-704004-3007-0040'  WHERE GLACCT = '3007-704004-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-704004-3007-0040'  WHERE GLACCT = '3007-704004-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-704004-3007-0040'  WHERE GLACCT = '3007-704004-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-915000-3007-0040'  WHERE GLACCT = '3007-915000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-915000-3007-0040'  WHERE GLACCT = '3007-915000-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-915000-3007-0040'  WHERE GLACCT = '3007-915000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-917000-3007-0040'  WHERE GLACCT = '3007-917000-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-917000-3007-0040'  WHERE GLACCT = '3007-917000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-917000-3007-0040'  WHERE GLACCT = '3007-917000-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-917000-3007-0040'  WHERE GLACCT = '3007-917000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-943019-3007-0040'  WHERE GLACCT = '3007-943019-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-981000-3007-0040'  WHERE GLACCT = '3007-981000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-981000-3007-0040'  WHERE GLACCT = '3007-981000-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-981000-3007-0040'  WHERE GLACCT = '3007-981000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-981001-3007-0040'  WHERE GLACCT = '3007-981001-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-981001-3007-0040'  WHERE GLACCT = '3007-981001-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-981001-3007-0040'  WHERE GLACCT = '3007-981001-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-981002-3007-0040'  WHERE GLACCT = '3007-981002-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-981002-3007-0040'  WHERE GLACCT = '3007-981002-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-981002-3007-0040'  WHERE GLACCT = '3007-981002-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-982000-3007-0040'  WHERE GLACCT = '3007-982000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-982000-3007-0040'  WHERE GLACCT = '3007-982000-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-982000-3007-0040'  WHERE GLACCT = '3007-982000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-982001-3007-0040'  WHERE GLACCT = '3007-982001-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-982001-3007-0040'  WHERE GLACCT = '3007-982001-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-982001-3007-0040'  WHERE GLACCT = '3007-982001-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-982002-3007-0040'  WHERE GLACCT = '3007-982002-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-982002-3007-0040'  WHERE GLACCT = '3007-982002-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-982002-3007-0040'  WHERE GLACCT = '3007-982002-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-984000-3007-0040'  WHERE GLACCT = '3007-984000-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-984000-3007-0040'  WHERE GLACCT = '3007-984000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-985000-3007-0040'  WHERE GLACCT = '3007-985000-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-985000-3007-0040'  WHERE GLACCT = '3007-985000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-985000-3007-0040'  WHERE GLACCT = '3007-985000-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-985000-3007-0040'  WHERE GLACCT = '3007-985000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-703000-3009-0045'  WHERE GLACCT = '3009-703000-3009-0000'
PRINT 'ROGUE UPDATE LINE 559....'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-703000-3009-0045'  WHERE GLACCT = '3009-703000-3009-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-942025-3009-0045'  WHERE GLACCT = '3009-942025-3009-0045'
/*
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-703000-3010-0046'  WHERE GLACCT = '8551-703000-3010-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-945000-3010-0046'  WHERE GLACCT = '8551-945000-3010-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-703000-3011-0047'  WHERE GLACCT = '8551-703000-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-703000-3011-0047'  WHERE GLACCT = '8551-703000-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-704000-3011-0047'  WHERE GLACCT = '8551-704000-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-704001-3011-0047'  WHERE GLACCT = '8551-704001-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-704001-3011-0047'  WHERE GLACCT = '8551-704001-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-704004-3011-0047'  WHERE GLACCT = '8551-704004-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-704004-3011-0047'  WHERE GLACCT = '8551-704004-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-915000-3011-0047'  WHERE GLACCT = '8551-915000-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-915000-3011-0047'  WHERE GLACCT = '8551-915000-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-917000-3011-0047'  WHERE GLACCT = '8551-917000-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-917000-3011-0047'  WHERE GLACCT = '8551-917000-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-943000-3011-0047'  WHERE GLACCT = '8551-943000-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-943008-3011-0047'  WHERE GLACCT = '8551-943008-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-943008-3011-0047'  WHERE GLACCT = '8551-943008-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-981000-3011-0047'  WHERE GLACCT = '8551-981000-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-981000-3011-0047'  WHERE GLACCT = '8551-981000-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-981001-3011-0047'  WHERE GLACCT = '8551-981001-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-981001-3011-0047'  WHERE GLACCT = '8551-981001-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-981002-3011-0047'  WHERE GLACCT = '8551-981002-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-981002-3011-0047'  WHERE GLACCT = '8551-981002-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-982000-3011-0047'  WHERE GLACCT = '8551-982000-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-982000-3011-0047'  WHERE GLACCT = '8551-982000-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-982001-3011-0047'  WHERE GLACCT = '8551-982001-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-982001-3011-0047'  WHERE GLACCT = '8551-982001-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-982002-3011-0047'  WHERE GLACCT = '8551-982002-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-982002-3011-0047'  WHERE GLACCT = '8551-982002-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-985000-3011-0047'  WHERE GLACCT = '8551-985000-3011-0048'
*/
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3011-985000-3011-0047'  WHERE GLACCT = '8551-985000-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-703000-3012-0050'  WHERE GLACCT = '3012-703000-3012-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-703000-3012-0050'  WHERE GLACCT = '3012-703000-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-703000-3012-0050'  WHERE GLACCT = '3012-703000-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-703000-3012-0050'  WHERE GLACCT = '3012-703000-3012-0044'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-703000-3012-0050'  WHERE GLACCT = '3012-703000-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-703000-3012-0050'  WHERE GLACCT = '3012-703000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-704004-3012-0050'  WHERE GLACCT = '3012-704004-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-704004-3012-0050'  WHERE GLACCT = '3012-704004-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-704004-3012-0050'  WHERE GLACCT = '3012-704004-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-706000-3012-0050'  WHERE GLACCT = '3012-706000-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-915000-3012-0050'  WHERE GLACCT = '3012-915000-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-915000-3012-0050'  WHERE GLACCT = '3012-915000-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-915000-3012-0050'  WHERE GLACCT = '3012-915000-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-915000-3012-0050'  WHERE GLACCT = '3012-915000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-917000-3012-0050'  WHERE GLACCT = '3012-917000-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-917000-3012-0050'  WHERE GLACCT = '3012-917000-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-917000-3012-0050'  WHERE GLACCT = '3012-917000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-924000-3012-0050'  WHERE GLACCT = '3012-924000-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-942003-3012-0050'  WHERE GLACCT = '3012-942003-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-943001-3012-0050'  WHERE GLACCT = '3012-943001-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-943006-3012-0050'  WHERE GLACCT = '3012-943006-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-943007-3012-0050'  WHERE GLACCT = '3012-943007-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-943019-3012-0050'  WHERE GLACCT = '3012-943019-3012-0050'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-967011-3012-0050'  WHERE GLACCT = '3012-967011-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-967011-3012-0050'  WHERE GLACCT = '3012-967011-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-981000-3012-0050'  WHERE GLACCT = '3012-981000-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-981000-3012-0050'  WHERE GLACCT = '3012-981000-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-981000-3012-0050'  WHERE GLACCT = '3012-981000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-981001-3012-0050'  WHERE GLACCT = '3012-981001-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-981001-3012-0050'  WHERE GLACCT = '3012-981001-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-981001-3012-0050'  WHERE GLACCT = '3012-981001-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-981002-3012-0050'  WHERE GLACCT = '3012-981002-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-981002-3012-0050'  WHERE GLACCT = '3012-981002-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-981002-3012-0050'  WHERE GLACCT = '3012-981002-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-982000-3012-0050'  WHERE GLACCT = '3012-982000-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-982000-3012-0050'  WHERE GLACCT = '3012-982000-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-982000-3012-0050'  WHERE GLACCT = '3012-982000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-982001-3012-0050'  WHERE GLACCT = '3012-982001-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-982001-3012-0050'  WHERE GLACCT = '3012-982001-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-982001-3012-0050'  WHERE GLACCT = '3012-982001-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-982002-3012-0050'  WHERE GLACCT = '3012-982002-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-982002-3012-0050'  WHERE GLACCT = '3012-982002-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-982002-3012-0050'  WHERE GLACCT = '3012-982002-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-984000-3012-0050'  WHERE GLACCT = '3012-984000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-985000-3012-0050'  WHERE GLACCT = '3012-985000-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-985000-3012-0050'  WHERE GLACCT = '3012-985000-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-985000-3012-0050'  WHERE GLACCT = '3012-985000-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-985000-3012-0050'  WHERE GLACCT = '3012-985000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-986000-3012-0050'  WHERE GLACCT = '3012-986000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-986002-3012-0050'  WHERE GLACCT = '3012-986002-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-986024-3012-0050'  WHERE GLACCT = '3012-986024-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-986026-3012-0050'  WHERE GLACCT = '3012-986026-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-986033-3012-0050'  WHERE GLACCT = '3012-986033-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '4000-704004-4000-4299'  WHERE GLACCT = '4000-704004-4000-4299'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '4000-915000-4000-4294'  WHERE GLACCT = '4000-915000-4000-4294'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8003-915000-4000-4298'  WHERE GLACCT = '4000-915000-4000-4298'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8003-916000-4000-4298'  WHERE GLACCT = '4000-916000-4000-4298'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8003-919008-4000-4298'  WHERE GLACCT = '4000-919008-4000-4298'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8003-919011-4000-4298'  WHERE GLACCT = '4000-919011-4000-4298'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8003-919013-4000-4299'  WHERE GLACCT = '4000-919013-4000-4299'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '5000-919026-0000-4296'  WHERE GLACCT = '4000-919026-4000-4296'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8003-919026-4000-4298'  WHERE GLACCT = '4000-919026-4000-4298'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8003-919028-4000-4298'  WHERE GLACCT = '4000-919028-4000-4298'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '4000-942020-4000-4339'  WHERE GLACCT = '4000-942020-4000-4339'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '4000-942023-4000-4339'  WHERE GLACCT = '4000-942023-4000-4339'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8003-943012-4000-4298'  WHERE GLACCT = '4000-943012-4000-4298'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '4000-952000-4000-5164'  WHERE GLACCT = '4000-952000-4000-5164'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8003-975600-4000-4298'  WHERE GLACCT = '4000-975600-4000-4298'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '5000-973000-0000-4296'  WHERE GLACCT = '5000-973000-5000-4296'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-703000-2002-0002' WHERE GLACCT = '2002-703000-2002-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-211805-2002-0002' WHERE GLACCT = '2002-211805-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-211807-2002-0002' WHERE GLACCT = '2002-211807-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-211813-2002-0002' WHERE GLACCT = '2002-211813-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-706100-2002-0002' WHERE GLACCT = '2002-706100-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-706101-2002-0002' WHERE GLACCT = '2002-706101-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '4000-942008-2002-0002' WHERE GLACCT = '4000-942008-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-942010-2002-0002' WHERE GLACCT = '2002-942010-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-942022-2002-0002' WHERE GLACCT = '2002-942022-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-943010-2002-0002' WHERE GLACCT = '2002-943010-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-943032-2002-0002' WHERE GLACCT = '2002-943032-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-943034-2002-0002' WHERE GLACCT = '2002-943034-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-952001-2002-0002' WHERE GLACCT = '2002-952001-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-986006-2002-0002' WHERE GLACCT = '2002-986006-2002-0002'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2002-919011-2002-0002' WHERE GLACCT = '2002-919011-2002-0003'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2006-924000-2002-0002' WHERE GLACCT = '2006-924000-2002-0004'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2007-924000-2002-0002' WHERE GLACCT = '2007-924000-2002-0005'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-924000-2002-0002' WHERE GLACCT = '2009-924000-2002-0009'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-924000-2002-0002' WHERE GLACCT = '2014-924000-2002-0010'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2025-924000-2002-0002' WHERE GLACCT = '2025-924000-2002-0013'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-924000-2002-0002' WHERE GLACCT = '2221-924000-2002-0014'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-924000-2002-0002' WHERE GLACCT = '2016-924000-2002-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2018-924000-2002-0002' WHERE GLACCT = '2018-924000-2002-0016'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-924000-2002-0002' WHERE GLACCT = '2020-924000-2002-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2017-924000-2002-0002' WHERE GLACCT = '2017-924000-2002-0018'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2021-924000-2002-0002' WHERE GLACCT = '2021-924000-2002-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-915000-2002-0002' WHERE GLACCT = '2022-915000-2002-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-924000-2002-0002' WHERE GLACCT = '2022-924000-2002-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2023-924000-2002-0002' WHERE GLACCT = '2023-924000-2002-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-924000-2002-0002' WHERE GLACCT = '3001-924000-2002-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-924000-2002-0002' WHERE GLACCT = '3002-924000-2002-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-924000-2002-0002' WHERE GLACCT = '3003-924000-2002-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-924000-2002-0002' WHERE GLACCT = '3004-924000-2002-0034'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-924000-2002-0002' WHERE GLACCT = '3006-924000-2002-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-924000-2002-0002' WHERE GLACCT = '3007-924000-2002-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-924000-2002-0002' WHERE GLACCT = '3009-924000-2002-0045'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3010-924000-2002-0002' WHERE GLACCT = '3010-924000-2002-0046'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3011-924000-2002-0002' WHERE GLACCT = '3011-924000-2002-0047'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-924000-2002-0002' WHERE GLACCT = '3012-924000-2002-0050'
/*
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8553-703000-2006-0004' WHERE GLACCT = '8553-703000-2006-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8553-211805-2006-0004' WHERE GLACCT = '8553-211805-2006-0004'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8553-211807-2006-0004' WHERE GLACCT = '8553-211807-2006-0004'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8553-706100-2006-0004' WHERE GLACCT = '8553-706100-2006-0004'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8553-706101-2006-0004' WHERE GLACCT = '8553-706101-2006-0004'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8553-919020-2006-0004' WHERE GLACCT = '8553-919020-2006-0004'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8553-943010-2006-0004' WHERE GLACCT = '8553-943010-2006-0004'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8553-943032-2006-0004' WHERE GLACCT = '8553-943032-2006-0004'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8553-943034-2006-0004' WHERE GLACCT = '8553-943034-2006-0004'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8553-952001-2006-0004' WHERE GLACCT = '8553-952001-2006-0004'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8553-975601-2006-0004' WHERE GLACCT = '8553-975601-2006-0004'
*/
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2007-211807-2007-0005' WHERE GLACCT = '2007-211807-2007-0005'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2007-706100-2007-0005' WHERE GLACCT = '2007-706100-2007-0005'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2007-706101-2007-0005' WHERE GLACCT = '2007-706101-2007-0005'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2007-918002-2007-0005' WHERE GLACCT = '2007-918002-2007-0005'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2007-942005-2007-0005' WHERE GLACCT = '2007-942005-2007-0005'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2007-943010-2007-0005' WHERE GLACCT = '2007-943010-2007-0005'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2007-943017-2007-0005' WHERE GLACCT = '2007-943017-2007-0005'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2007-943032-2007-0005' WHERE GLACCT = '2007-943032-2007-0005'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2007-943034-2007-0005' WHERE GLACCT = '2007-943034-2007-0005'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2007-952001-2007-0005' WHERE GLACCT = '2007-952001-2007-0005'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-703000-2009-0009' WHERE GLACCT = '2009-703000-2009-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-211805-2009-0009' WHERE GLACCT = '2009-211805-2009-0009'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-211807-2009-0009' WHERE GLACCT = '2009-211807-2009-0009'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-706100-2009-0009' WHERE GLACCT = '2009-706100-2009-0009'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-706101-2009-0009' WHERE GLACCT = '2009-706101-2009-0009'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-919020-2009-0009' WHERE GLACCT = '2009-919020-2009-0009'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-942005-2009-0009' WHERE GLACCT = '2009-942005-2009-0009'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-942009-2009-0009' WHERE GLACCT = '2009-942009-2009-0009'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-942010-2009-0009' WHERE GLACCT = '2009-942010-2009-0009'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-943032-2009-0009' WHERE GLACCT = '2009-943032-2009-0009'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-952001-2009-0009' WHERE GLACCT = '2009-952001-2009-0009'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-703000-2014-0010' WHERE GLACCT = '2014-703000-2014-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-211805-2014-0010' WHERE GLACCT = '2014-211805-2014-0010'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-211807-2014-0010' WHERE GLACCT = '2014-211807-2014-0010'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-706100-2014-0010' WHERE GLACCT = '2014-706100-2014-0010'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-706101-2014-0010' WHERE GLACCT = '2014-706101-2014-0010'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-942005-2014-0010' WHERE GLACCT = '2014-942005-2014-0010'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-943010-2014-0010' WHERE GLACCT = '2014-943010-2014-0010'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-943032-2014-0010' WHERE GLACCT = '2014-943032-2014-0010'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-943034-2014-0010' WHERE GLACCT = '2014-943034-2014-0010'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-952001-2014-0010' WHERE GLACCT = '2014-952001-2014-0010'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-986024-2014-0010' WHERE GLACCT = '2014-986024-2014-0010'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-919020-2014-0010' WHERE GLACCT = '2014-919020-2014-0011'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-919028-2014-0010' WHERE GLACCT = '2014-919028-2014-0011'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-943000-2014-0010' WHERE GLACCT = '2014-943000-2014-0011'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-943019-2014-0010' WHERE GLACCT = '2014-943019-2014-0011'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2014-985000-2014-0010' WHERE GLACCT = '2014-985000-2014-0011'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-211805-2016-0015' WHERE GLACCT = '2016-211805-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-211807-2016-0015' WHERE GLACCT = '2016-211807-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-706100-2016-0015' WHERE GLACCT = '2016-706100-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-706101-2016-0015' WHERE GLACCT = '2016-706101-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-919020-2016-0015' WHERE GLACCT = '2016-919020-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-942010-2016-0015' WHERE GLACCT = '2016-942010-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-942022-2016-0015' WHERE GLACCT = '2016-942022-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-943004-2016-0015' WHERE GLACCT = '2016-943004-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-943007-2016-0015' WHERE GLACCT = '2016-943007-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-943017-2016-0015' WHERE GLACCT = '2016-943017-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-943032-2016-0015' WHERE GLACCT = '2016-943032-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-943034-2016-0015' WHERE GLACCT = '2016-943034-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-952001-2016-0015' WHERE GLACCT = '2016-952001-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-986003-2016-0015' WHERE GLACCT = '2016-986003-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-986006-2016-0015' WHERE GLACCT = '2016-986006-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-986009-2016-0015' WHERE GLACCT = '2016-986009-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-986012-2016-0015' WHERE GLACCT = '2016-986012-2016-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2016-945000-2016-0015' WHERE GLACCT = '2016-945000-2016-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2017-945000-2017-0018' WHERE GLACCT = '2017-945000-2017-0011'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2017-211805-2017-0018' WHERE GLACCT = '2017-211805-2017-0018'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2017-211807-2017-0018' WHERE GLACCT = '2017-211807-2017-0018'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2017-706100-2017-0018' WHERE GLACCT = '2017-706100-2017-0018'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2017-706101-2017-0018' WHERE GLACCT = '2017-706101-2017-0018'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2017-922000-2017-0018' WHERE GLACCT = '2017-922000-2017-0018'
PRINT 'ROGUE UPDATE LINE 772...'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2017-942022-2017-0018' WHERE GLACCT = '2017-942022-2017-0018'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2017-943032-2017-0018' WHERE GLACCT = '2017-943032-2017-0018'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2017-943034-2017-0018' WHERE GLACCT = '2017-943034-2017-0018'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2017-952001-2017-0018' WHERE GLACCT = '2017-952001-2017-0018'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2017-986012-2017-0018' WHERE GLACCT = '2017-986012-2017-0018'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '4000-915000-2017-0018' WHERE GLACCT = '4000-915000-2017-1502'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-924000-2018-0016' WHERE GLACCT = '2221-924000-2018-0014'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2018-211805-2018-0016' WHERE GLACCT = '2018-211805-2018-0016'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2018-211807-2018-0016' WHERE GLACCT = '2018-211807-2018-0016'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2018-706100-2018-0016' WHERE GLACCT = '2018-706100-2018-0016'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2018-706101-2018-0016' WHERE GLACCT = '2018-706101-2018-0016'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2018-943032-2018-0016' WHERE GLACCT = '2018-943032-2018-0016'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2018-943034-2018-0016' WHERE GLACCT = '2018-943034-2018-0016'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2018-952001-2018-0016' WHERE GLACCT = '2018-952001-2018-0016'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2018-915000-2018-0016' WHERE GLACCT = '2018-915000-2018-0045'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-211805-2020-0017' WHERE GLACCT = '2020-211805-2020-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-211807-2020-0017' WHERE GLACCT = '2020-211807-2020-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-706100-2020-0017' WHERE GLACCT = '2020-706100-2020-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-706101-2020-0017' WHERE GLACCT = '2020-706101-2020-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-942005-2020-0017' WHERE GLACCT = '2020-942005-2020-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-942010-2020-0017' WHERE GLACCT = '2020-942010-2020-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-942022-2020-0017' WHERE GLACCT = '2020-942022-2020-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-943032-2020-0017' WHERE GLACCT = '2020-943032-2020-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-952001-2020-0017' WHERE GLACCT = '2020-952001-2020-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-986006-2020-0017' WHERE GLACCT = '2020-986006-2020-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-986012-2020-0017' WHERE GLACCT = '2020-986012-2020-0017'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-919008-2020-0017' WHERE GLACCT = '2020-919008-2020-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-942004-2020-0017' WHERE GLACCT = '2020-942004-2020-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-942003-2020-0017' WHERE GLACCT = '2020-942003-2020-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2021-703000-2021-0019' WHERE GLACCT = '2021-703000-2021-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2021-211805-2021-0019' WHERE GLACCT = '2021-211805-2021-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2021-211807-2021-0019' WHERE GLACCT = '2021-211807-2021-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2021-706100-2021-0019' WHERE GLACCT = '2021-706100-2021-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2021-706101-2021-0019' WHERE GLACCT = '2021-706101-2021-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-942005-2021-0019' WHERE GLACCT = '2221-942005-2021-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2021-943032-2021-0019' WHERE GLACCT = '2021-943032-2021-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2021-943034-2021-0019' WHERE GLACCT = '2021-943034-2021-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2021-952001-2021-0019' WHERE GLACCT = '2021-952001-2021-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2021-942001-2021-0019' WHERE GLACCT = '2021-942001-2021-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-703000-2022-0020' WHERE GLACCT = '2022-703000-2022-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-211805-2022-0020' WHERE GLACCT = '2022-211805-2022-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-211807-2022-0020' WHERE GLACCT = '2022-211807-2022-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-211813-2022-0020' WHERE GLACCT = '2022-211813-2022-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-706100-2022-0020' WHERE GLACCT = '2022-706100-2022-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-706101-2022-0020' WHERE GLACCT = '2022-706101-2022-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2020-919023-2022-0020' WHERE GLACCT = '2020-919023-2022-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-942010-2022-0020' WHERE GLACCT = '2022-942010-2022-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-943032-2022-0020' WHERE GLACCT = '2022-943032-2022-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-943034-2022-0020' WHERE GLACCT = '2022-943034-2022-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-952001-2022-0020' WHERE GLACCT = '2022-952001-2022-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2022-986012-2022-0020' WHERE GLACCT = '2022-986012-2022-0020'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2023-211805-2023-0021' WHERE GLACCT = '2023-211805-2023-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2023-211807-2023-0021' WHERE GLACCT = '2023-211807-2023-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2023-706100-2023-0021' WHERE GLACCT = '2023-706100-2023-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2023-706101-2023-0021' WHERE GLACCT = '2023-706101-2023-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2023-918002-2023-0021' WHERE GLACCT = '2023-918002-2023-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2023-942005-2023-0021' WHERE GLACCT = '2023-942005-2023-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2023-943032-2023-0021' WHERE GLACCT = '2023-943032-2023-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2023-943034-2023-0021' WHERE GLACCT = '2023-943034-2023-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2023-952001-2023-0021' WHERE GLACCT = '2023-952001-2023-0021'
/*
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8552-211807-2025-0013' WHERE GLACCT = '8552-211807-2025-0013'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8552-706100-2025-0013' WHERE GLACCT = '8552-706100-2025-0013'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8552-706101-2025-0013' WHERE GLACCT = '8552-706101-2025-0013'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8552-919020-2025-0013' WHERE GLACCT = '8552-919020-2025-0013'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8552-942005-2025-0013' WHERE GLACCT = '8552-942005-2025-0013'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8552-942022-2025-0013' WHERE GLACCT = '8552-942022-2025-0013'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8552-943032-2025-0013' WHERE GLACCT = '8552-943032-2025-0013'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8552-943034-2025-0013' WHERE GLACCT = '8552-943034-2025-0013'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8552-952001-2025-0013' WHERE GLACCT = '8552-952001-2025-0013'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8552-975601-2025-0013' WHERE GLACCT = '8552-975601-2025-0013'
*/
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-211805-2221-0014' WHERE GLACCT = '2221-211805-2221-0014'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-211807-2221-0014' WHERE GLACCT = '2221-211807-2221-0014'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-706100-2221-0014' WHERE GLACCT = '2221-706100-2221-0014'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-706101-2221-0014' WHERE GLACCT = '2221-706101-2221-0014'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-942010-2221-0014' WHERE GLACCT = '2221-942010-2221-0014'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-942011-2221-0014' WHERE GLACCT = '2221-942011-2221-0014'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-942022-2221-0014' WHERE GLACCT = '2221-942022-2221-0014'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-943032-2221-0014' WHERE GLACCT = '2221-943032-2221-0014'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-943034-2221-0014' WHERE GLACCT = '2221-943034-2221-0014'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2221-952001-2221-0014' WHERE GLACCT = '2221-952001-2221-0014'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-703000-3001-0022' WHERE GLACCT = '3001-703000-3001-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-917000-3001-0022' WHERE GLACCT = '3001-917000-3001-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-211805-3001-0022' WHERE GLACCT = '3001-211805-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-706100-3001-0022' WHERE GLACCT = '3001-706100-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-706101-3001-0022' WHERE GLACCT = '3001-706101-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-720002-3001-0022' WHERE GLACCT = '3001-720002-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-919020-3001-0022' WHERE GLACCT = '3001-919020-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-922000-3001-0022' WHERE GLACCT = '3001-922000-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943003-3001-0022' WHERE GLACCT = '3001-943003-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943032-3001-0022' WHERE GLACCT = '3001-943032-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943034-3001-0022' WHERE GLACCT = '3001-943034-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-952001-3001-0022' WHERE GLACCT = '3001-952001-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-962200-3001-0022' WHERE GLACCT = '3001-962200-3001-0022'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-211807-3001-0022' WHERE GLACCT = '3001-211807-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-703000-3001-0022' WHERE GLACCT = '3001-703000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-704001-3001-0022' WHERE GLACCT = '3001-704001-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-704004-3001-0022' WHERE GLACCT = '3001-704004-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-917000-3001-0022' WHERE GLACCT = '3001-917000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-919020-3001-0022' WHERE GLACCT = '3001-919020-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-924000-3001-0022' WHERE GLACCT = '3001-924000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-942004-3001-0022' WHERE GLACCT = '3001-942004-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943000-3001-0022' WHERE GLACCT = '3001-943000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943007-3001-0022' WHERE GLACCT = '3001-943007-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-961010-3001-0022' WHERE GLACCT = '3001-961010-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-961020-3001-0022' WHERE GLACCT = '3001-961020-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-964000-3001-0022' WHERE GLACCT = '3001-964000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-967011-3001-0022' WHERE GLACCT = '3001-967011-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-984000-3001-0022' WHERE GLACCT = '3001-984000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-985000-3001-0022' WHERE GLACCT = '3001-985000-3001-0023'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-703000-3001-0022' WHERE GLACCT = '3001-703000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-704001-3001-0022' WHERE GLACCT = '3001-704001-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-915000-3001-0022' WHERE GLACCT = '3001-915000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-917000-3001-0022' WHERE GLACCT = '3001-917000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-919020-3001-0022' WHERE GLACCT = '3001-919020-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-924000-3001-0022' WHERE GLACCT = '3001-924000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-942003-3001-0022' WHERE GLACCT = '3001-942003-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943000-3001-0022' WHERE GLACCT = '3001-943000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943007-3001-0022' WHERE GLACCT = '3001-943007-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943019-3001-0022' WHERE GLACCT = '3001-943019-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-964000-3001-0022' WHERE GLACCT = '3001-964000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-984000-3001-0022' WHERE GLACCT = '3001-984000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-985000-3001-0022' WHERE GLACCT = '3001-985000-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-986060-3001-0022' WHERE GLACCT = '3001-986060-3001-0024'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-924000-3001-0022' WHERE GLACCT = '3001-924000-3001-0025'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-942002-3001-0022' WHERE GLACCT = '3001-942002-3001-0025'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-943007-3001-0022' WHERE GLACCT = '3001-943007-3001-0025'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-985000-3001-0022' WHERE GLACCT = '3001-985000-3001-0025'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-703000-3001-0022' WHERE GLACCT = '3001-703000-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-704001-3001-0022' WHERE GLACCT = '3001-704001-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-917000-3001-0022' WHERE GLACCT = '3001-917000-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-919020-3001-0022' WHERE GLACCT = '3001-919020-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-924000-3001-0022' WHERE GLACCT = '3001-924000-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-942002-3001-0022' WHERE GLACCT = '3001-942002-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3001-942004-3001-0022' WHERE GLACCT = '3001-942004-3001-0026'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-703000-3002-0027' WHERE GLACCT = '3002-703000-3002-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-917000-3002-0027' WHERE GLACCT = '3002-917000-3002-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-211805-3002-0027' WHERE GLACCT = '3002-211805-3002-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-706100-3002-0027' WHERE GLACCT = '3002-706100-3002-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-706101-3002-0027' WHERE GLACCT = '3002-706101-3002-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-942010-3002-0027' WHERE GLACCT = '3002-942010-3002-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-943014-3002-0027' WHERE GLACCT = '3002-943014-3002-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-943032-3002-0027' WHERE GLACCT = '3002-943032-3002-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-943034-3002-0027' WHERE GLACCT = '3002-943034-3002-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-952001-3002-0027' WHERE GLACCT = '3002-952001-3002-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-919020-3002-0027' WHERE GLACCT = '3002-919020-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-924000-3002-0027' WHERE GLACCT = '3002-924000-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-985000-3002-0027' WHERE GLACCT = '3002-985000-3002-0028'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-211807-3002-0027' WHERE GLACCT = '3002-211807-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-703000-3002-0027' WHERE GLACCT = '3002-703000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-704001-3002-0027' WHERE GLACCT = '3002-704001-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-704004-3002-0027' WHERE GLACCT = '3002-704004-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-917000-3002-0027' WHERE GLACCT = '3002-917000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-919020-3002-0027' WHERE GLACCT = '3002-919020-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-924000-3002-0027' WHERE GLACCT = '3002-924000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-942003-3002-0027' WHERE GLACCT = '3002-942003-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-942004-3002-0027' WHERE GLACCT = '3002-942004-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-942005-3002-0027' WHERE GLACCT = '3002-942005-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-943000-3002-0027' WHERE GLACCT = '3002-943000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-943007-3002-0027' WHERE GLACCT = '3002-943007-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-943022-3002-0027' WHERE GLACCT = '3002-943022-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-943033-3002-0027' WHERE GLACCT = '3002-943033-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-961030-3002-0027' WHERE GLACCT = '3002-961030-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-967011-3002-0027' WHERE GLACCT = '3002-967011-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-985000-3002-0027' WHERE GLACCT = '3002-985000-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-986003-3002-0027' WHERE GLACCT = '3002-986003-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-986024-3002-0027' WHERE GLACCT = '3002-986024-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-986033-3002-0027' WHERE GLACCT = '3002-986033-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-986060-3002-0027' WHERE GLACCT = '3002-986060-3002-0029'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3002-917000-3002-0027' WHERE GLACCT = '3002-917000-3002-0094'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-703000-3003-0030' WHERE GLACCT = '3003-703000-3003-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-916000-3003-0030' WHERE GLACCT = '3003-916000-3003-0003'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942004-3003-0030' WHERE GLACCT = '3003-942004-3003-0003'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-211805-3003-0030' WHERE GLACCT = '3003-211805-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-706100-3003-0030' WHERE GLACCT = '3003-706100-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-706101-3003-0030' WHERE GLACCT = '3003-706101-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-720002-3003-0030' WHERE GLACCT = '3003-720002-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943003-3003-0030' WHERE GLACCT = '3003-943003-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943010-3003-0030' WHERE GLACCT = '3003-943010-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943032-3003-0030' WHERE GLACCT = '3003-943032-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943034-3003-0030' WHERE GLACCT = '3003-943034-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-952001-3003-0030' WHERE GLACCT = '3003-952001-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-975401-3003-0030' WHERE GLACCT = '3003-975401-3003-0030'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-917000-3003-0030' WHERE GLACCT = '3003-917000-3003-0031'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-919020-3003-0030' WHERE GLACCT = '3003-919020-3003-0031'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-924000-3003-0030' WHERE GLACCT = '3003-924000-3003-0031'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942004-3003-0030' WHERE GLACCT = '3003-942004-3003-0031'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-703000-3003-0030' WHERE GLACCT = '3003-703000-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-704001-3003-0030' WHERE GLACCT = '3003-704001-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-917000-3003-0030' WHERE GLACCT = '3003-917000-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-919020-3003-0030' WHERE GLACCT = '3003-919020-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-924000-3003-0030' WHERE GLACCT = '3003-924000-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942004-3003-0030' WHERE GLACCT = '3003-942004-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943000-3003-0030' WHERE GLACCT = '3003-943000-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943006-3003-0030' WHERE GLACCT = '3003-943006-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943007-3003-0030' WHERE GLACCT = '3003-943007-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943018-3003-0030' WHERE GLACCT = '3003-943018-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943019-3003-0030' WHERE GLACCT = '3003-943019-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-985000-3003-0030' WHERE GLACCT = '3003-985000-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-986033-3003-0030' WHERE GLACCT = '3003-986033-3003-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-211807-3003-0030' WHERE GLACCT = '3003-211807-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-703000-3003-0030' WHERE GLACCT = '3003-703000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-704001-3003-0030' WHERE GLACCT = '3003-704001-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-916000-3003-0030' WHERE GLACCT = '3003-916000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-917000-3003-0030' WHERE GLACCT = '3003-917000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-919020-3003-0030' WHERE GLACCT = '3003-919020-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-919026-3003-0030' WHERE GLACCT = '3003-919026-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-924000-3003-0030' WHERE GLACCT = '3003-924000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942001-3003-0030' WHERE GLACCT = '3003-942001-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942002-3003-0030' WHERE GLACCT = '3003-942002-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942003-3003-0030' WHERE GLACCT = '3003-942003-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942004-3003-0030' WHERE GLACCT = '3003-942004-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942005-3003-0030' WHERE GLACCT = '3003-942005-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942020-3003-0030' WHERE GLACCT = '3003-942020-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-942023-3003-0030' WHERE GLACCT = '3003-942023-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943000-3003-0030' WHERE GLACCT = '3003-943000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943007-3003-0030' WHERE GLACCT = '3003-943007-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-943019-3003-0030' WHERE GLACCT = '3003-943019-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-964000-3003-0030' WHERE GLACCT = '3003-964000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-967011-3003-0030' WHERE GLACCT = '3003-967011-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-985000-3003-0030' WHERE GLACCT = '3003-985000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-986000-3003-0030' WHERE GLACCT = '3003-986000-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-986002-3003-0030' WHERE GLACCT = '3003-986002-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-986033-3003-0030' WHERE GLACCT = '3003-986033-3003-0033'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-703000-3003-0030' WHERE GLACCT = '3003-703000-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-917000-3003-0030' WHERE GLACCT = '3003-917000-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-919020-3003-0030' WHERE GLACCT = '3003-919020-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-924000-3003-0030' WHERE GLACCT = '3003-924000-3003-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3003-985000-3003-0030' WHERE GLACCT = '3003-985000-3003-0041'
PRINT 'ROGUE UPDATE LINE 1000...'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-703000-3004-0034' WHERE GLACCT = '3004-703000-3004-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-919023-3004-0034' WHERE GLACCT = '3004-919023-3004-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-942000-3004-0034' WHERE GLACCT = '3004-942000-3004-0027'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986003-3004-0034' WHERE GLACCT = '3004-986003-3004-0032'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-211805-3004-0034' WHERE GLACCT = '3004-211805-3004-0034'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-706100-3004-0034' WHERE GLACCT = '3004-706100-3004-0034'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-706101-3004-0034' WHERE GLACCT = '3004-706101-3004-0034'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-943010-3004-0034' WHERE GLACCT = '3004-943010-3004-0034'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-943032-3004-0034' WHERE GLACCT = '3004-943032-3004-0034'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-943034-3004-0034' WHERE GLACCT = '3004-943034-3004-0034'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-952001-3004-0034' WHERE GLACCT = '3004-952001-3004-0034'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-962200-3004-0034' WHERE GLACCT = '3004-962200-3004-0034'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-211807-3004-0034' WHERE GLACCT = '3004-211807-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-703000-3004-0034' WHERE GLACCT = '3004-703000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-917000-3004-0034' WHERE GLACCT = '3004-917000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-919020-3004-0034' WHERE GLACCT = '3004-919020-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-924000-3004-0034' WHERE GLACCT = '3004-924000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-932000-3004-0034' WHERE GLACCT = '3004-932000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-933000-3004-0034' WHERE GLACCT = '3004-933000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-942003-3004-0034' WHERE GLACCT = '3004-942003-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-942004-3004-0034' WHERE GLACCT = '3004-942004-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-943000-3004-0034' WHERE GLACCT = '3004-943000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-943007-3004-0034' WHERE GLACCT = '3004-943007-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-962200-3004-0034' WHERE GLACCT = '3004-962200-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-967011-3004-0034' WHERE GLACCT = '3004-967011-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-984000-3004-0034' WHERE GLACCT = '3004-984000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-985000-3004-0034' WHERE GLACCT = '3004-985000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986000-3004-0034' WHERE GLACCT = '3004-986000-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986002-3004-0034' WHERE GLACCT = '3004-986002-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986033-3004-0034' WHERE GLACCT = '3004-986033-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3004-986060-3004-0034' WHERE GLACCT = '3004-986060-3004-0035'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-703000-3006-0037' WHERE GLACCT = '3006-703000-3006-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-917000-3006-0037' WHERE GLACCT = '3006-917000-3006-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-211805-3006-0037' WHERE GLACCT = '3006-211805-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-706100-3006-0037' WHERE GLACCT = '3006-706100-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-706101-3006-0037' WHERE GLACCT = '3006-706101-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-720002-3006-0037' WHERE GLACCT = '3006-720002-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-943010-3006-0037' WHERE GLACCT = '3006-943010-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-943032-3006-0037' WHERE GLACCT = '3006-943032-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-943033-3006-0037' WHERE GLACCT = '3006-943033-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-952001-3006-0037' WHERE GLACCT = '3006-952001-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-986006-3006-0037' WHERE GLACCT = '3006-986006-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-986012-3006-0037' WHERE GLACCT = '3006-986012-3006-0037'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-703000-3006-0037' WHERE GLACCT = '3006-703000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704000-3006-0037' WHERE GLACCT = '3006-704000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704001-3006-0037' WHERE GLACCT = '3006-704001-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-917000-3006-0037' WHERE GLACCT = '3006-917000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-919020-3006-0037' WHERE GLACCT = '3006-919020-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-924000-3006-0037' WHERE GLACCT = '3006-924000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-931000-3006-0037' WHERE GLACCT = '3006-931000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-938000-3006-0037' WHERE GLACCT = '3006-938000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-942002-3006-0037' WHERE GLACCT = '3006-942002-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-942004-3006-0037' WHERE GLACCT = '3006-942004-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-943007-3006-0037' WHERE GLACCT = '3006-943007-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-984000-3006-0037' WHERE GLACCT = '3006-984000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-985000-3006-0037' WHERE GLACCT = '3006-985000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-986000-3006-0037' WHERE GLACCT = '3006-986000-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-986002-3006-0037' WHERE GLACCT = '3006-986002-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-986024-3006-0037' WHERE GLACCT = '3006-986024-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-986060-3006-0037' WHERE GLACCT = '3006-986060-3006-0038'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-703000-3006-0037' WHERE GLACCT = '3006-703000-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704001-3006-0037' WHERE GLACCT = '3006-704001-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-917000-3006-0037' WHERE GLACCT = '3006-917000-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-919020-3006-0037' WHERE GLACCT = '3006-919020-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-924000-3006-0037' WHERE GLACCT = '3006-924000-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-942004-3006-0037' WHERE GLACCT = '3006-942004-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-943000-3006-0037' WHERE GLACCT = '3006-943000-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-943008-3006-0037' WHERE GLACCT = '3006-943008-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-943019-3006-0037' WHERE GLACCT = '3006-943019-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-985000-3006-0037' WHERE GLACCT = '3006-985000-3006-0039'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-703000-3006-0037' WHERE GLACCT = '3006-703000-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704001-3006-0037' WHERE GLACCT = '3006-704001-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704004-3006-0037' WHERE GLACCT = '3006-704004-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-924000-3006-0037' WHERE GLACCT = '3006-924000-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-943007-3006-0037' WHERE GLACCT = '3006-943007-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-943019-3006-0037' WHERE GLACCT = '3006-943019-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-985000-3006-0037' WHERE GLACCT = '3006-985000-3006-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-703000-3006-0037' WHERE GLACCT = '3006-703000-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-720002-3006-0037' WHERE GLACCT = '3006-720002-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-917000-3006-0037' WHERE GLACCT = '3006-917000-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-919020-3006-0037' WHERE GLACCT = '3006-919020-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-924000-3006-0037' WHERE GLACCT = '3006-924000-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-942004-3006-0037' WHERE GLACCT = '3006-942004-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-985000-3006-0037' WHERE GLACCT = '3006-985000-3006-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-703000-3006-0037' WHERE GLACCT = '3006-703000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-704001-3006-0037' WHERE GLACCT = '3006-704001-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-917000-3006-0037' WHERE GLACCT = '3006-917000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-924000-3006-0037' WHERE GLACCT = '3006-924000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-932000-3006-0037' WHERE GLACCT = '3006-932000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-943033-3006-0037' WHERE GLACCT = '3006-943033-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3006-985000-3006-0037' WHERE GLACCT = '3006-985000-3006-0053'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-703000-3007-0040' WHERE GLACCT = '3007-703000-3007-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-211805-3007-0040' WHERE GLACCT = '3007-211805-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-706100-3007-0040' WHERE GLACCT = '3007-706100-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-706101-3007-0040' WHERE GLACCT = '3007-706101-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-720002-3007-0040' WHERE GLACCT = '3007-720002-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-943010-3007-0040' WHERE GLACCT = '3007-943010-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-943022-3007-0040' WHERE GLACCT = '3007-943022-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-943032-3007-0040' WHERE GLACCT = '3007-943032-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-943034-3007-0040' WHERE GLACCT = '3007-943034-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-952001-3007-0040' WHERE GLACCT = '3007-952001-3007-0040'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-211807-3007-0040' WHERE GLACCT = '3007-211807-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-703000-3007-0040' WHERE GLACCT = '3007-703000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-704000-3007-0040' WHERE GLACCT = '3007-704000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-917000-3007-0040' WHERE GLACCT = '3007-917000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-919020-3007-0040' WHERE GLACCT = '3007-919020-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-942003-3007-0040' WHERE GLACCT = '3007-942003-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-942004-3007-0040' WHERE GLACCT = '3007-942004-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-943004-3007-0040' WHERE GLACCT = '3007-943004-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-943007-3007-0040' WHERE GLACCT = '3007-943007-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-943010-3007-0040' WHERE GLACCT = '3007-943010-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2007-943019-3007-0040' WHERE GLACCT = '2007-943019-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-943019-3007-0040' WHERE GLACCT = '3007-943019-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-967011-3007-0040' WHERE GLACCT = '3007-967011-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-984000-3007-0040' WHERE GLACCT = '3007-984000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-985000-3007-0040' WHERE GLACCT = '3007-985000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-986000-3007-0040' WHERE GLACCT = '3007-986000-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-986002-3007-0040' WHERE GLACCT = '3007-986002-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-986026-3007-0040' WHERE GLACCT = '3007-986026-3007-0041'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-703000-3007-0040' WHERE GLACCT = '3007-703000-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-919020-3007-0040' WHERE GLACCT = '3007-919020-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-932000-3007-0040' WHERE GLACCT = '3007-932000-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-943019-3007-0040' WHERE GLACCT = '3007-943019-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-985000-3007-0040' WHERE GLACCT = '3007-985000-3007-0042'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-703000-3007-0040' WHERE GLACCT = '3007-703000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-704001-3007-0040' WHERE GLACCT = '3007-704001-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-915000-3007-0040' WHERE GLACCT = '3007-915000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-917000-3007-0040' WHERE GLACCT = '3007-917000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-919020-3007-0040' WHERE GLACCT = '3007-919020-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-942002-3007-0040' WHERE GLACCT = '3007-942002-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-942004-3007-0040' WHERE GLACCT = '3007-942004-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-942008-3007-0040' WHERE GLACCT = '3007-942008-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-942019-3007-0040' WHERE GLACCT = '3007-942019-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-943000-3007-0040' WHERE GLACCT = '3007-943000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-943008-3007-0040' WHERE GLACCT = '3007-943008-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-945000-3007-0040' WHERE GLACCT = '3007-945000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-961010-3007-0040' WHERE GLACCT = '3007-961010-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-961030-3007-0040' WHERE GLACCT = '3007-961030-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-964000-3007-0040' WHERE GLACCT = '3007-964000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-984000-3007-0040' WHERE GLACCT = '3007-984000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-985000-3007-0040' WHERE GLACCT = '3007-985000-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-986060-3007-0040' WHERE GLACCT = '3007-986060-3007-0043'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-703000-3007-0040' WHERE GLACCT = '3007-703000-3007-0044'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3007-985000-3007-0040' WHERE GLACCT = '3007-985000-3007-0044'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '2009-919028-3009-0045' WHERE GLACCT = '2009-919028-3009-0015'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-703000-3009-0045' WHERE GLACCT = '3009-703000-3009-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-964000-3009-0045' WHERE GLACCT = '3009-964000-3009-0019'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-917000-3009-0045' WHERE GLACCT = '3009-917000-3009-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-211805-3009-0045' WHERE GLACCT = '3009-211805-3009-0045'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-706100-3009-0045' WHERE GLACCT = '3009-706100-3009-0045'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-706101-3009-0045' WHERE GLACCT = '3009-706101-3009-0045'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-943010-3009-0045' WHERE GLACCT = '3009-943010-3009-0045'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-943032-3009-0045' WHERE GLACCT = '3009-943032-3009-0045'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3009-952001-3009-0045' WHERE GLACCT = '3009-952001-3009-0045'
/*
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-703000-3010-0046' WHERE GLACCT = '8551-703000-3010-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-917000-3010-0046' WHERE GLACCT = '8551-917000-3010-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-211805-3010-0046' WHERE GLACCT = '8551-211805-3010-0046'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-211807-3010-0046' WHERE GLACCT = '8551-211807-3010-0046'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-706100-3010-0046' WHERE GLACCT = '8551-706100-3010-0046'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-706101-3010-0046' WHERE GLACCT = '8551-706101-3010-0046'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-943032-3010-0046' WHERE GLACCT = '8551-943032-3010-0046'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-943034-3010-0046' WHERE GLACCT = '8551-943034-3010-0046'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-952001-3010-0046' WHERE GLACCT = '8551-952001-3010-0046'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-975601-3010-0046' WHERE GLACCT = '8551-975601-3010-0046'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-703000-3011-0047' WHERE GLACCT = '8551-703000-3011-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-211805-3011-0047' WHERE GLACCT = '8551-211805-3011-0047'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-706100-3011-0047' WHERE GLACCT = '8551-706100-3011-0047'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-706101-3011-0047' WHERE GLACCT = '8551-706101-3011-0047'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-943010-3011-0047' WHERE GLACCT = '8551-943010-3011-0047'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-943032-3011-0047' WHERE GLACCT = '8551-943032-3011-0047'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-943034-3011-0047' WHERE GLACCT = '8551-943034-3011-0047'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-952001-3011-0047' WHERE GLACCT = '8551-952001-3011-0047'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-975601-3011-0047' WHERE GLACCT = '8551-975601-3011-0047'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-703000-3011-0047' WHERE GLACCT = '8551-703000-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-704001-3011-0047' WHERE GLACCT = '8551-704001-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-917000-3011-0047' WHERE GLACCT = '8551-917000-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-919020-3011-0047' WHERE GLACCT = '8551-919020-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-924000-3011-0047' WHERE GLACCT = '8551-924000-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-942004-3011-0047' WHERE GLACCT = '8551-942004-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-943008-3011-0047' WHERE GLACCT = '8551-943008-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-943019-3011-0047' WHERE GLACCT = '8551-943019-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-952000-3011-0047' WHERE GLACCT = '8551-952000-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-952001-3011-0047' WHERE GLACCT = '8551-952001-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-985000-3011-0047' WHERE GLACCT = '8551-985000-3011-0048'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-703000-3011-0047' WHERE GLACCT = '8551-703000-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-704001-3011-0047' WHERE GLACCT = '8551-704001-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-917000-3011-0047' WHERE GLACCT = '8551-917000-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-919020-3011-0047' WHERE GLACCT = '8551-919020-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-924000-3011-0047' WHERE GLACCT = '8551-924000-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-943000-3011-0047' WHERE GLACCT = '8551-943000-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-943008-3011-0047' WHERE GLACCT = '8551-943008-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-964000-3011-0047' WHERE GLACCT = '8551-964000-3011-0049'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '8551-985000-3011-0047' WHERE GLACCT = '8551-985000-3011-0049'
*/
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-703000-3012-0050' WHERE GLACCT = '3012-703000-3012-0000'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-952000-3012-0050' WHERE GLACCT = '3012-952000-3012-0006'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-952001-3012-0050' WHERE GLACCT = '3012-952001-3012-0006'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-704004-3012-0050' WHERE GLACCT = '3012-704004-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-706000-3012-0050' WHERE GLACCT = '3012-706000-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-915000-3012-0050' WHERE GLACCT = '3012-915000-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-942002-3012-0050' WHERE GLACCT = '3012-942002-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-942004-3012-0050' WHERE GLACCT = '3012-942004-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-981000-3012-0050' WHERE GLACCT = '3012-981000-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-981001-3012-0050' WHERE GLACCT = '3012-981001-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-981002-3012-0050' WHERE GLACCT = '3012-981002-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-982000-3012-0050' WHERE GLACCT = '3012-982000-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-982001-3012-0050' WHERE GLACCT = '3012-982001-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-982002-3012-0050' WHERE GLACCT = '3012-982002-3012-0007'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-703000-3012-0050' WHERE GLACCT = '3012-703000-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-917000-3012-0050' WHERE GLACCT = '3012-917000-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-919020-3012-0050' WHERE GLACCT = '3012-919020-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-924000-3012-0050' WHERE GLACCT = '3012-924000-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-985000-3012-0050' WHERE GLACCT = '3012-985000-3012-0008'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-917000-3012-0050' WHERE GLACCT = '3012-917000-3012-0021'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-703000-3012-0050' WHERE GLACCT = '3012-703000-3012-0044'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-211805-3012-0050' WHERE GLACCT = '3012-211805-3012-0050'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-211807-3012-0050' WHERE GLACCT = '3012-211807-3012-0050'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-706100-3012-0050' WHERE GLACCT = '3012-706100-3012-0050'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-706101-3012-0050' WHERE GLACCT = '3012-706101-3012-0050'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-942010-3012-0050' WHERE GLACCT = '3012-942010-3012-0050'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-943010-3012-0050' WHERE GLACCT = '3012-943010-3012-0050'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-943032-3012-0050' WHERE GLACCT = '3012-943032-3012-0050'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-917000-3012-0050' WHERE GLACCT = '3012-917000-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-919020-3012-0050' WHERE GLACCT = '3012-919020-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-924000-3012-0050' WHERE GLACCT = '3012-924000-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-942004-3012-0050' WHERE GLACCT = '3012-942004-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-943019-3012-0050' WHERE GLACCT = '3012-943019-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-985000-3012-0050' WHERE GLACCT = '3012-985000-3012-0051'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-703000-3012-0050' WHERE GLACCT = '3012-703000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-704001-3012-0050' WHERE GLACCT = '3012-704001-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-704004-3012-0050' WHERE GLACCT = '3012-704004-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-917000-3012-0050' WHERE GLACCT = '3012-917000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-919020-3012-0050' WHERE GLACCT = '3012-919020-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-924000-3012-0050' WHERE GLACCT = '3012-924000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-932000-3012-0050' WHERE GLACCT = '3012-932000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-933000-3012-0050' WHERE GLACCT = '3012-933000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-942003-3012-0050' WHERE GLACCT = '3012-942003-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-942004-3012-0050' WHERE GLACCT = '3012-942004-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-943007-3012-0050' WHERE GLACCT = '3012-943007-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-943019-3012-0050' WHERE GLACCT = '3012-943019-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-961010-3012-0050' WHERE GLACCT = '3012-961010-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-961030-3012-0050' WHERE GLACCT = '3012-961030-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-985000-3012-0050' WHERE GLACCT = '3012-985000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-986000-3012-0050' WHERE GLACCT = '3012-986000-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-986002-3012-0050' WHERE GLACCT = '3012-986002-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-986024-3012-0050' WHERE GLACCT = '3012-986024-3012-0052'
UPDATE [EliteLive].[dbo].[rptActualDetail] SET GLACCT = '3012-986033-3012-0050' WHERE GLACCT = '3012-986033-3012-0052'
PRINT '.................... END ROGUE UPDATES ......................'

----------------------------------------------------
-- rptActualAggregateMTD, rptActualAggregateYTD ----
----------------------------------------------------

DECLARE @drpt varchar(20) 
set @drpt   = convert(VARCHAR(10),dateadd(dd,-(day(dateadd(mm,1,getdate()))),dateadd(mm,1,getdate())),101)
DECLARE @1stday varchar(20)
set @1stday = convert(VARCHAR(10),dateadd(dd,1-(day(dateadd(mm,1,getdate()))),getdate()),101)
--SELECT @1STDAY AS 'BEG DATE',@drpt AS 'END DATE'

IF OBJECT_ID(N'[EliteLive].[dbo].[rptActualAggregateMTD]', N'U') IS NOT NULL  
   DROP TABLE [EliteLive].[dbo].[rptActualAggregateMTD]

CREATE TABLE	[EliteLive].[dbo].[rptActualAggregateMTD] (ACCT CHAR(6), AMP VARCHAR(6), ACTEXP FLOAT)

INSERT			[EliteLive].[dbo].[rptActualAggregateMTD] (ACCT, AMP, ACTEXP)
SELECT			ACCT, AMP, SUM(NAMOUNT) 
FROM			[EliteLive].[dbo].[rptActualDetail] 
WHERE			DTRS BETWEEN @1stday AND @DRPT 
GROUP BY		ACCT, AMP

DELETE FROM		[EliteLive].[dbo].[rptActualAggregateMTD] WHERE AMP < '1100'
DELETE FROM		[EliteLive].[dbo].[rptActualAggregateMTD] WHERE ACCT = '974000' OR ACCT = '962010' 

---- YEAR TO DATE TRANSACTIONS
IF OBJECT_ID(N'[EliteLive].[dbo].[rptActualAggregateYTD]', N'U') IS NOT NULL  
   DROP TABLE [EliteLive].[dbo].[rptActualAggregateYTD]


CREATE TABLE	[EliteLive].[dbo].[rptActualAggregateYTD] (ACCT CHAR(6), AMP VARCHAR(6), ACTEXP FLOAT)

INSERT			[EliteLive].[dbo].[rptActualAggregateYTD] (ACCT, AMP, ACTEXP)
SELECT			ACCT, AMP, SUM(NAMOUNT) 
FROM			[EliteLive].[dbo].[rptActualDetail] 
GROUP BY		ACCT, AMP

DELETE FROM		[EliteLive].[dbo].[rptActualAggregateYTD]
WHERE			AMP IN ('0000', '4000')

UPDATE			[EliteLive].[dbo].[rptActualAggregateYTD]
SET				ACTEXP = -ACTEXP
WHERE			LEFT(ACCT, 1) = '7'

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@ INSERT DRAWN ACCOUNTS NOT BUDGETED FOR @@@@@@@@@@@
*/

INSERT INTO		[EliteLive].[dbo].[rptBudgetActual] (ACCT, AMP, YAMTA, SEG, NOBUDGET, IS_AGGREGATE)
SELECT			T1.ACCT, T1.AMP, T1.ACTEXP, (LEFT(T1.ACCT, 2)) AS SEG, 1 AS NOBUDGET, 0 AS IS_AGGREGATE
FROM			[EliteLive].[dbo].[rptActualAggregateYTD] AS T1
LEFT OUTER JOIN [EliteLive].[dbo].[rptBudgetActual] T3 ON T1.ACCT = T3.ACCT AND T1.AMP = T3.AMP
WHERE			T3.ACCT IS NULL
AND				T1.ACTEXP IS NOT NULL;

UPDATE			T1
SET				T1.MAMTA = T2.ACTEXP
FROM			[EliteLive].[dbo].[rptBudgetActual] AS T1
INNER JOIN		[EliteLive].[dbo].[rptActualAggregateMTD] AS T2 
				ON T1.AMP = T2.AMP 
				AND T1.ACCT = T2.ACCT;


-- Backfill, Part 1...

WITH		data1 AS
(
SELECT		GLACCT, AMP, ACCT, DESCRIPT
FROM		[EliteLive].[dbo].[rptActualDetail]
GROUP BY	GLACCT, AMP, ACCT, DESCRIPT
)
UPDATE		T1
SET			T1.GLACCT = data1.GLACCT
			, T1.DESCRIPT = data1.DESCRIPT
FROM		[EliteLive].[dbo].[rptBudgetActual] AS T1
INNER JOIN	data1 
			ON T1.AMP = data1.AMP
			AND T1.ACCT = data1.ACCT
WHERE		T1.GLACCT IS NULL

-- Set [EliteLive].[dbo].[rptBudgetActual].SEG. Put '10' suffix in same bucket as 'revenue'.

UPDATE		[EliteLive].[dbo].[rptBudgetActual]
SET			SEG =	(
							CASE 
							WHEN LEFT(ACCT, 2) = '10' THEN '79'
							WHEN LEFT(ACCT, 1) = '7' THEN '79'
							ELSE LEFT(ACCT, 2)
							END
							)


/*
@@@@@@@@@@@@@@@@@@@@@@@@@@ UPDATE BUDGET WITH ACTUAL @@@@@@@@@@@@@@@@@@@@@@@@
*/



UPDATE				[EliteLive].[dbo].[rptBudgetActual]
SET					MBUDAMT = 0
WHERE				MBUDAMT IS NULL

UPDATE				[EliteLive].[dbo].[rptBudgetActual]
SET					YBUDAMT = 0
WHERE				YBUDAMT IS NULL

UPDATE				[EliteLive].[dbo].[rptBudgetActual]
SET					MAMTA = 0
WHERE				MAMTA IS NULL

UPDATE				[EliteLive].[dbo].[rptBudgetActual]
SET					YAMTA = 0
WHERE				YAMTA IS NULL

DELETE				FROM [EliteLive].[dbo].[rptBudgetActual]
WHERE				MBUDAMT = 0 AND YBUDAMT = 0 AND MAMTA = 0 AND YAMTA = 0


UPDATE				T1
SET					T1.MAMTA = T2.ACTEXP
FROM				[EliteLive].[dbo].[rptBudgetActual]  T1
LEFT OUTER JOIN		[EliteLive].[dbo].[rptActualAggregateMTD] T2
ON					T1.ACCT = T2.ACCT AND T1.AMP = T2.AMP
--WHERE				T1.MAMTA IS NULL

UPDATE				T1
SET					T1.YAMTA = T2.ACTEXP
FROM				[EliteLive].[dbo].[rptBudgetActual]  T1
LEFT OUTER JOIN		[EliteLive].[dbo].[rptActualAggregateYTD] T2
ON					T1.ACCT = T2.ACCT AND T1.AMP = T2.AMP
--WHERE				T1.YAMTA IS NULL


UPDATE				[EliteLive].[dbo].[rptBudgetActual]
SET					MAMTA = -(MAMTA)
WHERE				LEFT(ACCT, 1) IN ('1', '7');


UPDATE				[EliteLive].[dbo].[rptBudgetActual]
SET					MVARIANCE = (
								CASE
								WHEN LEFT(ACCT, 1) IN ('1', '7') THEN MAMTA - MBUDAMT
								ELSE MBUDAMT - MAMTA
								END
								)

UPDATE				[EliteLive].[dbo].[rptBudgetActual]
SET					MPER = MAMTA / MBUDAMT
WHERE				MBUDAMT <> 0


UPDATE				[EliteLive].[dbo].[rptBudgetActual]
SET					YVARIANCE = (
								CASE
								WHEN LEFT(ACCT, 1) IN ('1', '7') THEN YAMTA - YBUDAMT
								ELSE YBUDAMT - YAMTA
								END
								)

UPDATE				[EliteLive].[dbo].[rptBudgetActual]
SET					YPER = YAMTA / YBUDAMT
WHERE				YBUDAMT <> 0;

----------------------------------------------------------------------------------------
-- Adjust Operating Transfers in (ACCT 100100) so they always have actuals data display. 
----------------------------------------------------------------------------------------

UPDATE		[EliteLive].[dbo].[rptBudgetActual]
SET			MAMTA = 0
			, MVARIANCE = MBUDAMT
WHERE		ACCT = '100100'
AND			ISNULL(MAMTA, 0) = 0

UPDATE		[EliteLive].[dbo].[rptBudgetActual]
SET			YAMTA = 0
			, YVARIANCE = YBUDAMT
			, AVAILABLE = TOTBUDAMT
WHERE		ACCT = '100100'
AND			ISNULL(YAMTA, 0) = 0

UPDATE		[EliteLive].[dbo].[rptBudgetActual]
SET			YAMTA = - (YAMTA)
			, YVARIANCE = YBUDAMT + YAMTA
WHERE		ACCT = '100100'
AND			ISNULL(YAMTA, 0) <> 0;

/*
@@@@@@@@@@@@@@@@ BUCKET ROWS & CALCULATIONS @@@@@@@@@@@@@@@@
*/

-- Variable buckets

WITH T1 AS
(
SELECT			AMP, LEFT(ACCT, 2) AS SEG
FROM			[EliteLive].[dbo].[rptBudgetActual] 
GROUP BY		AMP, LEFT(ACCT, 2)
)
INSERT INTO		[EliteLive].[dbo].[rptBudgetActual]  (AMP, ACCT, DESCRIPT, IS_AGGREGATE, NOBUDGET)
SELECT			T1.AMP, T2.ACCT, T2.DESCRIPT, T2.IS_AGGREGATE, 0 AS NOBUDGET
FROM			T1
INNER JOIN		[ITAnalytics].[dbo].[budgetrpt_aggregates] T2 
				ON T1.SEG = T2.SEG
WHERE			T2.ACCT NOT IN ('999998', '999999')
ORDER BY		T1.AMP, T2.ACCT;

-- Universal Buckets: Revenue AMPs

WITH T1 AS
(
SELECT			AMP
FROM			[EliteLive].[dbo].[rptBudgetActual] 
WHERE			LEFT(ACCT, 1) IN ('1', '7')
GROUP BY		AMP
)
INSERT INTO		[EliteLive].[dbo].[rptBudgetActual]  (AMP, ACCT, DESCRIPT, IS_AGGREGATE, NOBUDGET)
SELECT			T1.AMP, T2.ACCT, T2.DESCRIPT, T2.IS_AGGREGATE, 0 AS NOBUDGET
FROM			T1, [ITAnalytics].[dbo].[budgetrpt_aggregates] T2 
WHERE			T2.SEG = 79
ORDER BY		T1.AMP, T2.ACCT;

-- Universal buckets: Applicable to all AMPs

WITH T1 AS
(
SELECT			AMP
FROM			[EliteLive].[dbo].[rptBudgetActual]
GROUP BY		AMP
)
INSERT INTO		[EliteLive].[dbo].[rptBudgetActual]  (AMP, ACCT, DESCRIPT, IS_AGGREGATE, NOBUDGET)
SELECT			T1.AMP, T2.ACCT, T2.DESCRIPT, T2.IS_AGGREGATE, 0 AS NOBUDGET
FROM			T1, [ITAnalytics].[dbo].[budgetrpt_aggregates] T2 
WHERE			T2.ACCT IN ('999998', '999999', 'TOT')
ORDER BY		T1.AMP, T2.ACCT;


------------------------------------------------------------
-- Bucket calculations.
------------------------------------------------------------

-- Non "799998", "999999", "TOT"

UPDATE			[EliteLive].[dbo].[rptBudgetActual]
SET				MAMTA = 0
				, YAMTA = 0
				, MVARIANCE = 0
				, YVARIANCE = 0
WHERE			ACCT IN
				(
				SELECT			ACCT
				FROM			[ITAnalytics].[dbo].[budgetrpt_aggregates]
				WHERE			LEN(DESCRIPT) > 0
				);

WITH			aggr AS
(
SELECT			T1.AMP
				, T1.SEG
				, T2.ACCT
				, SUM(T1.TOTBUDAMT) AS TOTBUDAMT
				, SUM(T1.MBUDAMT) AS MBUDAMT
				, SUM(T1.YBUDAMT) AS YBUDAMT
				, SUM(T1.MAMTA) AS MAMTA
				, SUM(T1.YAMTA) AS YAMTA
FROM			[EliteLive].[dbo].[rptBudgetActual] T1
INNER JOIN		[ITAnalytics].[dbo].[budgetrpt_aggregates] T2
				ON T1.SEG = T2.SEG
				AND T2.IS_AGGREGATE = 1
				AND T2.ACCT NOT IN ('799998', '999999', 'TOT') -- Update these separately TODO
GROUP BY		T1.AMP, T1.SEG, T2.ACCT
)
UPDATE			T1
SET				T1.TOTBUDAMT = aggr.TOTBUDAMT
				, T1.MBUDAMT = aggr.MBUDAMT
				, T1.YBUDAMT = aggr.YBUDAMT
				, T1.MAMTA = aggr.MAMTA
				, T1.MVARIANCE = aggr.MBUDAMT - aggr.MAMTA
				, T1.YAMTA = aggr.YAMTA
				, T1.YVARIANCE = aggr.YBUDAMT - aggr.YAMTA
				, T1.MPER = (CASE WHEN ISNULL(aggr.MBUDAMT, 0) = 0 THEN NULL
							WHEN aggr.MBUDAMT = 0 THEN NULL
							ELSE ISNULL(aggr.MAMTA, 0)/aggr.MBUDAMT
							END)
				, T1.YPER = (CASE WHEN ISNULL(aggr.YBUDAMT, 0) = 0 THEN NULL
							WHEN aggr.YBUDAMT = 0 THEN NULL
							ELSE ISNULL(aggr.YAMTA, 0)/aggr.YBUDAMT
							END)
FROM			[EliteLive].[dbo].[rptBudgetActual] T1
INNER JOIN		aggr ON T1.AMP = aggr.AMP AND T1.ACCT = aggr.ACCT;


-- 799998

WITH			aggr AS
(
SELECT			AMP
				, '799998' AS ACCT
				, SUM(TOTBUDAMT) AS TOTBUDAMT
				, SUM(MBUDAMT) AS MBUDAMT
				, SUM(YBUDAMT) AS YBUDAMT
				, SUM(MAMTA) AS MAMTA
				, SUM(YAMTA) AS YAMTA
FROM			[EliteLive].[dbo].[rptBudgetActual]
WHERE			LEFT(LTRIM(ACCT), 2) IN ('10', '70') 
AND				IS_AGGREGATE = 0
GROUP BY		AMP
)
UPDATE			T1
SET				T1.TOTBUDAMT = aggr.TOTBUDAMT
				, T1.MBUDAMT = aggr.MBUDAMT
				, T1.YBUDAMT = aggr.YBUDAMT
				, T1.MAMTA = aggr.MAMTA
				, T1.YAMTA = aggr.YAMTA
				, T1.MVARIANCE = aggr.MBUDAMT - aggr.MAMTA
				, T1.YVARIANCE = aggr.YBUDAMT - aggr.YAMTA
FROM			[EliteLive].[dbo].[rptBudgetActual] T1
INNER JOIN		aggr ON T1.AMP = aggr.AMP 
				AND T1.ACCT = aggr.ACCT;


-- 999999

WITH			aggr AS
(
SELECT			AMP
				, SUM(TOTBUDAMT) AS TOTBUDAMT
				, SUM(MBUDAMT) AS MBUDAMT
				, SUM(YBUDAMT) AS YBUDAMT
				, SUM(MAMTA) AS MAMTA
				, SUM(YAMTA) AS YAMTA
FROM			[EliteLive].[dbo].[rptBudgetActual]
WHERE			LEFT(LTRIM(ACCT), 1) = '9' 
AND				IS_AGGREGATE = 0
GROUP BY		AMP
)
UPDATE			T1
SET				T1.TOTBUDAMT = aggr.TOTBUDAMT
				, T1.MBUDAMT = aggr.MBUDAMT
				, T1.YBUDAMT = aggr.YBUDAMT
				, T1.MAMTA = aggr.MAMTA
				, T1.YAMTA = aggr.YAMTA
				, T1.MVARIANCE = aggr.MBUDAMT - aggr.MAMTA
				, T1.YVARIANCE = aggr.YBUDAMT - aggr.YAMTA
FROM			[EliteLive].[dbo].[rptBudgetActual] T1
INNER JOIN		aggr ON T1.AMP = aggr.AMP AND T1.ACCT = '999999';

-- TOT

WITH			rev AS
(
SELECT			AMP
				, SUM(TOTBUDAMT) AS TOTBUDAMT
				, SUM(MBUDAMT) AS MBUDAMT
				, SUM(YBUDAMT) AS YBUDAMT
				, SUM(MAMTA) AS MAMTA
				, SUM(YAMTA) AS YAMTA
FROM			[EliteLive].[dbo].[rptBudgetActual]
WHERE			ACCT = '799998'
GROUP BY		AMP
),				expc AS
(
SELECT			AMP
				, SUM(TOTBUDAMT) AS TOTBUDAMT
				, SUM(MBUDAMT) AS MBUDAMT
				, SUM(YBUDAMT) AS YBUDAMT
				, SUM(MAMTA) AS MAMTA
				, SUM(YAMTA) AS YAMTA
FROM			[EliteLive].[dbo].[rptBudgetActual]
WHERE			ACCT = '999999'
GROUP BY		AMP
)
UPDATE			T1
SET				T1.TOTBUDAMT = rev.TOTBUDAMT - expc.TOTBUDAMT
				, T1.MBUDAMT = rev.MBUDAMT - expc.MBUDAMT
				, T1.YBUDAMT = rev.YBUDAMT - expc.YBUDAMT
				, T1.MAMTA = rev.MAMTA - expc.MAMTA
				, T1.YAMTA = rev.YAMTA - expc.YAMTA
				, T1.MVARIANCE = (rev.MBUDAMT - expc.MBUDAMT) - (rev.MAMTA - expc.MAMTA)
				, T1.YVARIANCE = (rev.YBUDAMT - expc.YBUDAMT) - (rev.YAMTA - expc.YAMTA)
FROM			[EliteLive].[dbo].[rptBudgetActual] T1
INNER JOIN		rev ON T1.AMP = rev.AMP AND T1.ACCT = 'TOT'
INNER JOIN		expc ON T1.AMP = expc.AMP AND T1.ACCT = 'TOT'


------------------------------------
-- Calculate Available
------------------------------------

UPDATE			[EliteLive].[dbo].[rptBudgetActual]
SET				AVAILABLE = ISNULL(TOTBUDAMT, 0) - YAMTA
WHERE			YAMTA IS NOT NULL;


------------------------------------
-- Calculate Percent Expended
------------------------------------

UPDATE			[EliteLive].[dbo].[rptBudgetActual]
SET				PEREXP = YAMTA / YBUDAMT
WHERE			ISNULL(YBUDAMT, 0) <> 0
AND				YAMTA IS NOT NULL;


------------------------------------
-- Backfill, Part 2
------------------------------------

WITH		data1 AS
(
SELECT		AMP, AMPNAME, MGRNAME, DIRNAME, CHIEFNAME
FROM		[EliteLive].[dbo].[rptBudgetActual] 
WHERE		AMPNAME IS NOT NULL
GROUP BY	AMP, AMPNAME, MGRNAME, DIRNAME, CHIEFNAME
)
UPDATE		T1
SET			T1.AMP = data1.AMP
			, T1.AMPNAME = data1.AMPNAME
			, T1.MGRNAME = data1.MGRNAME
			, T1.DIRNAME = data1.DIRNAME
			, T1.CHIEFNAME = data1.CHIEFNAME
FROM		[EliteLive].[dbo].[rptBudgetActual] AS T1
INNER JOIN	data1 ON T1.AMP = data1.AMP
WHERE		T1.AMPNAME IS NULL;



------------------------------------
-- House Cleaning
------------------------------------

UPDATE [EliteLive].[dbo].[rptBudgetActual]
SET MBUDAMT = NULL
WHERE MBUDAMT = 0

UPDATE [EliteLive].[dbo].[rptBudgetActual]
SET MAMTA = NULL
WHERE MAMTA = 0

UPDATE [EliteLive].[dbo].[rptBudgetActual]
SET YBUDAMT = NULL
WHERE YBUDAMT = 0

UPDATE [EliteLive].[dbo].[rptBudgetActual]
SET YAMTA = NULL 
WHERE YAMTA = 0

UPDATE [EliteLive].[dbo].[rptBudgetActual]
SET MVARIANCE = MBUDAMT - MAMTA
WHERE MVARIANCE IS NULL
AND LEN(DESCRIPT) > 0

UPDATE [EliteLive].[dbo].[rptBudgetActual]
SET YVARIANCE = YBUDAMT - YAMTA
WHERE YVARIANCE IS NULL
AND LEN(DESCRIPT) > 0

UPDATE	[EliteLive].[dbo].[rptBudgetActual]
SET		MBUDAMT = NULL
		, YBUDAMT = NULL
		, MAMTA = NULL
		, YAMTA = NULL
WHERE	LEN(DESCRIPT) = 0

------------------------------------
-- ETL Date
------------------------------------

UPDATE [EliteLive].[dbo].[rptBudgetActual]
SET ETLDATE = CONCAT(DATENAME(WEEKDAY, GETDATE()), ' ', CONVERT(VARCHAR, GETDATE(), 109));



/*							END							*/




GO


