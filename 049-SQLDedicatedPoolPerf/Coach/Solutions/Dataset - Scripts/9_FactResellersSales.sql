RENAME OBJECT [FACTRESELLERSALES] TO [FACTRESELLERSALES_OLD]
GO


CREATE TABLE [DBO].[FACTRESELLERSALES]
(
	[PRODUCTKEY] [INT] NOT NULL,
	[ORDERDATEKEY] [INT] NOT NULL,
	[DUEDATEKEY] [INT] NOT NULL,
	[SHIPDATEKEY] [INT] NOT NULL,
	[RESELLERKEY] [INT] NOT NULL,
	[EMPLOYEEKEY] [INT] NOT NULL,
	[PROMOTIONKEY] [INT] NOT NULL,
	[CURRENCYKEY] [INT] NOT NULL,
	[SALESTERRITORYKEY] [INT] NOT NULL,
	[SALESORDERNUMBER] [NVARCHAR](20) NOT NULL,
	[SALESORDERLINENUMBER] [SMALLINT] NOT NULL,
	[REVISIONNUMBER] [TINYINT] NULL,
	[ORDERQUANTITY] [SMALLINT] NULL,
	[UNITPRICE] [MONEY] NULL,
	[EXTENDEDAMOUNT] [MONEY] NULL,
	[UNITPRICEDISCOUNTPCT] [FLOAT] NULL,
	[DISCOUNTAMOUNT] [FLOAT] NULL,
	[PRODUCTSTANDARDCOST] [MONEY] NULL,
	[TOTALPRODUCTCOST] [MONEY] NULL,
	[SALESAMOUNT] [MONEY] NULL,
	[TAXAMT] [MONEY] NULL,
	[FREIGHT] [MONEY] NULL,
	[CARRIERTRACKINGNUMBER] [NVARCHAR](25) NULL,
	[CUSTOMERPONUMBER] [NVARCHAR](25) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [PRODUCTKEY] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

DECLARE @I INT = 1
DECLARE @BASEDATE DATETIME2 =  '2001/07/01' --<- ORIGINAL ONE.

DECLARE @ORDERS TINYINT
DECLARE @TOPPRODUCT SMALLINT
DECLARE @TOPRESELLER SMALLINT

DECLARE @REVISIONNUMBER TINYINT
DECLARE @PROMOTIONKEY INT
DECLARE @CURRENCYKEY TINYINT
DECLARE @SALESTERRITORYKEY SMALLINT
DECLARE @EMPLOYEE SMALLINT

WHILE (DATEADD(DAY,@I,@BASEDATE)  < GETDATE())
BEGIN

	SET @TOPPRODUCT = (SELECT  ABS(CHECKSUM(NEWID())) % 125 + 1)
	SET @TOPRESELLER = (SELECT  ABS(CHECKSUM(NEWID())) % 510 + 1)
	SET @REVISIONNUMBER = (SELECT  ABS(CHECKSUM(NEWID())) % 4 + 1)
	SET @SALESTERRITORYKEY = (SELECT ABS(CHECKSUM(NEWID())) % 10 + 1)

	SET @PROMOTIONKEY = (SELECT TOP 1 PROMOTIONKEY FROM DIMPROMOTION WHERE DATEADD(DAY,@I,@BASEDATE) >= STARTDATE AND DATEADD(DAY,@I,@BASEDATE) < ISNULL(ENDDATE,'99991231') AND ENGLISHPROMOTIONNAME LIKE 'NO DISCOUNT%')
	SET @CURRENCYKEY = (SELECT TOP 1 CURRENCYKEY FROM DIMCURRENCY ORDER BY NEWID())
	--SET @SALESTERRITORYKEY = (SELECT TOP 1 SALESTERRITORYKEY FROM DIMSALESTERRITORY ORDER BY NEWID())
	SET @EMPLOYEE = (SELECT TOP 1 EMPLOYEEKEY FROM DIMEMPLOYEE WHERE DATEADD(DAY,@I,@BASEDATE) >= STARTDATE AND DATEADD(DAY,@I,@BASEDATE) < ISNULL(ENDDATE,'99991231') ORDER BY NEWID())

	;WITH RESELLERPROD AS
	(
		SELECT DISTINCT RESELLERKEY
			, PRODUCTKEY
			, CONVERT(VARCHAR(8), DATEADD(DAY, 1, DATEADD(DAY,@I,@BASEDATE)), 112) [ORDERDATEKEY]
			, CONVERT(VARCHAR(8), DATEADD(DAY, 2, DATEADD(DAY,@I,@BASEDATE)), 112)  [DUEDATEKEY]
			, CONVERT(VARCHAR(8), DATEADD(DAY, 3, DATEADD(DAY,@I,@BASEDATE)), 112) [SHIPDATEKEY]
			, @REVISIONNUMBER [REVISIONNUMBER]
			, @PROMOTIONKEY [PROMOTIONKEY]
			, 'SO' + CAST(RESELLERKEY AS VARCHAR(5))+ CONVERT(VARCHAR(8), DATEADD(DAY, 1, DATEADD(DAY,@I,@BASEDATE)), 112) +  CAST(DENSE_RANK() OVER(ORDER BY RESELLERKEY) AS VARCHAR(20)) [SALESORDERNUMBER]
			, @CURRENCYKEY CURRENCYKEY
			, @SALESTERRITORYKEY SALESTERRITORYKEY
			, @EMPLOYEE EMPLOYEEKEY
		FROM
		(
			--PRODUCT
			SELECT TOP(@TOPPRODUCT) PRODUCTKEY FROM DIMPRODUCT WHERE DATEADD(DAY,@I,@BASEDATE) >= STARTDATE AND DATEADD(DAY,@I,@BASEDATE) < ISNULL(ENDDATE,'99991231')
		)A,
		(
			SELECT TOP(@TOPRESELLER) RESELLERKEY FROM DIMRESELLER WHERE DATEPART(YEAR,DATEADD(DAY,@I,@BASEDATE)) >= YEAROPENED
		)B

	)
	----SELECT * FROM RESELLERPROD ORDER BY 1
	,RESELLERSPRODDETAILS AS
	(

		SELECT DISTINCT
			PD.[PRODUCTKEY]
			, [PROMOTIONKEY]
			, [ORDERDATEKEY]
			, [DUEDATEKEY]
			, [SHIPDATEKEY]
			, RESELLERKEY
			, EMPLOYEEKEY
			, CURRENCYKEY
			, SALESTERRITORYKEY
			, [SALESORDERNUMBER] --+ CAST(EMPLOYEEKEY AS VARCHAR(5)) [SALESORDERNUMBER]
			, ROW_NUMBER() OVER(PARTITION BY RESELLERKEY ORDER BY PD.PRODUCTKEY) [SALESORDERLINENUMBER]
			, [REVISIONNUMBER]
			, ABS(CHECKSUM(NEWID())) % 5 + 1 [ORDERQUANTITY]
			, ISNULL(PD.LISTPRICE,0) [UNITPRICE]
			--, [EXTENDEDAMOUNT]
			,0 [UNITPRICEDISCOUNTPCT]
			--, [DISCOUNTAMOUNT]
			, ISNULL(PD.STANDARDCOST,0) [PRODUCTSTANDARDCOST]
			--, [TOTALPRODUCTCOST]
			--, [SALESAMOUNT]
			, ABS(CHECKSUM(NEWID())) % 10.00 + 1 [TAXAMT]
			, ABS(CHECKSUM(NEWID())) % 8.00 + 1 [FREIGHT]
			, NULL [CARRIERTRACKINGNUMBER]
			, NULL [CUSTOMERPONUMBER]
		FROM RESELLERPROD P
			INNER JOIN DIMPRODUCT PD
				ON P.PRODUCTKEY = PD.PRODUCTKEY
	--GROUP BY P.CUSTOMERKEY, PD.[PRODUCTKEY],  PD.LISTPRICE, PD.STANDARDCOST
	)
	INSERT INTO FACTRESELLERSALES
	SELECT DISTINCT
		[PRODUCTKEY]
		, [ORDERDATEKEY]
		, [DUEDATEKEY]
		, [SHIPDATEKEY]
		, [RESELLERKEY]
		, [EMPLOYEEKEY]
		, [PROMOTIONKEY]
		, [CURRENCYKEY]
		, [SALESTERRITORYKEY]
		, [SALESORDERNUMBER]
		, [SALESORDERLINENUMBER]
		, [REVISIONNUMBER]
		, [ORDERQUANTITY]
		, [UNITPRICE]
		, [ORDERQUANTITY]*[UNITPRICE] [EXTENDEDAMOUNT]
		, [UNITPRICEDISCOUNTPCT]
		, 0 [DISCOUNTAMOUNT]
		, [PRODUCTSTANDARDCOST]
		, [PRODUCTSTANDARDCOST] * [ORDERQUANTITY] [TOTALPRODUCTCOST]
		, [ORDERQUANTITY]*[UNITPRICE]  [SALESAMOUNT]
		, [TAXAMT]
		, [FREIGHT]
		, [CARRIERTRACKINGNUMBER]
		, [CUSTOMERPONUMBER]
	FROM RESELLERSPRODDETAILS

	SET @I+=1

END
