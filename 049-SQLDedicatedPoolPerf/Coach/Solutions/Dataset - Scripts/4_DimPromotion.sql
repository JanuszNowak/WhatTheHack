RENAME OBJECT [DIMPROMOTION] TO [DIMPROMOTION_OLD]
GO

CREATE TABLE [DBO].[DIMPROMOTION]
(
	[PROMOTIONKEY] [INT] NOT NULL,
	[PROMOTIONALTERNATEKEY] [INT] NULL,
	[ENGLISHPROMOTIONNAME] [NVARCHAR](255) NULL,
	[SPANISHPROMOTIONNAME] [NVARCHAR](255) NULL,
	[FRENCHPROMOTIONNAME] [NVARCHAR](255) NULL,
	[DISCOUNTPCT] [FLOAT] NULL,
	[ENGLISHPROMOTIONTYPE] [NVARCHAR](50) NULL,
	[SPANISHPROMOTIONTYPE] [NVARCHAR](50) NULL,
	[FRENCHPROMOTIONTYPE] [NVARCHAR](50) NULL,
	[ENGLISHPROMOTIONCATEGORY] [NVARCHAR](50) NULL,
	[SPANISHPROMOTIONCATEGORY] [NVARCHAR](50) NULL,
	[FRENCHPROMOTIONCATEGORY] [NVARCHAR](50) NULL,
	[STARTDATE] [DATETIME] NOT NULL,
	[ENDDATE] [DATETIME] NULL,
	[MINQTY] [INT] NULL,
	[MAXQTY] [INT] NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED COLUMNSTORE INDEX
)
GO

DECLARE @I SMALLINT = 1
DECLARE @STEPP SMALLINT = 16
DECLARE @STEPD TINYINT = 2
DECLARE @MAXDATE DATETIME2

INSERT INTO [DIMPROMOTION]
SELECT
	[PROMOTIONKEY]
	, [PROMOTIONALTERNATEKEY]
	, [ENGLISHPROMOTIONNAME] + ' - DISMISSED -  ' + CASE WHEN [ENDDATE] IS NULL THEN CONVERT(CHAR(8),DATEADD(MONTH,@STEPD,[STARTDATE]),112) ELSE CONVERT(CHAR(8),[ENDDATE],112) END [ENGLISHPRODUCTNAME]
	, [SPANISHPROMOTIONNAME] + ' - DESPEDIDO - ' + CASE WHEN [ENDDATE] IS NULL THEN CONVERT(CHAR(8),DATEADD(MONTH,@STEPD,[STARTDATE]),112) ELSE CONVERT(CHAR(8),[ENDDATE],112) END [SPANISHPRODUCTNAME]
	, [FRENCHPROMOTIONNAME] + ' - CONG�DI� - ' + CASE WHEN [ENDDATE] IS NULL THEN CONVERT(CHAR(8),DATEADD(MONTH,@STEPD,[STARTDATE]),112) ELSE CONVERT(CHAR(8),[ENDDATE],112) END [FRENCHPRODUCTNAME]
	, [DISCOUNTPCT]
	, [ENGLISHPROMOTIONTYPE]
	, [SPANISHPROMOTIONTYPE]
	, [FRENCHPROMOTIONTYPE]
	, [ENGLISHPROMOTIONCATEGORY]
	, [SPANISHPROMOTIONCATEGORY]
	, [FRENCHPROMOTIONCATEGORY]
	, [STARTDATE]
	, [ENDDATE]
	, [MINQTY]
	, [MAXQTY]
FROM [DIMPROMOTION_OLD]
--ORDER BY 1


SET @MAXDATE = (SELECT MAX(ENDDATE) FROM [DIMPROMOTION_OLD])

WHILE(DATEADD(MONTH,@STEPD,@MAXDATE)<=DATEADD(MONTH,@STEPD,GETDATE()))
--WHILE (@I <= 107)
BEGIN

	;WITH CTE AS (SELECT TOP(@STEPP) * FROM DIMPROMOTION WHERE PROMOTIONKEY > (@I * @STEPP) - @STEPP)
	INSERT INTO DIMPROMOTION
	SELECT
	 		ROW_NUMBER() OVER(ORDER BY [PROMOTIONALTERNATEKEY]) + (@STEPP * @I) [PROMOTIONKEY]
			, ROW_NUMBER() OVER(ORDER BY [PROMOTIONALTERNATEKEY]) + (@STEPP * @I)  [PROMOTIONALTERNATEKEY]
			, [ENGLISHPROMOTIONNAME]
			, [SPANISHPROMOTIONNAME]
			, [FRENCHPROMOTIONNAME]
			, [DISCOUNTPCT]+ ABS(CHECKSUM(NEWID())) % 30.21 + 1
			, [ENGLISHPROMOTIONTYPE]
			, [SPANISHPROMOTIONTYPE]
			, [FRENCHPROMOTIONTYPE]
			, [ENGLISHPROMOTIONCATEGORY]
			, [SPANISHPROMOTIONCATEGORY]
			, [FRENCHPROMOTIONCATEGORY]
			, [ENDDATE]
			, DATEADD(MONTH, @STEPD, [ENDDATE]) [ENDDATE]
			, + ABS(CHECKSUM(NEWID())) % 50 + 1 [MINQTY]
			, + ABS(CHECKSUM(NEWID())) % 100 + 50 [MAXQTY]
	FROM CTE

	SET @I+=1
	SET @MAXDATE = (SELECT MAX(ENDDATE) FROM DIMPROMOTION)

END
GO

