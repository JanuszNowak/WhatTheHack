CREATE TABLE [FACTSALES]
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
AS
SELECT
	[ORDERDATEKEY]
	, [PRODUCTKEY]
	, [CUSTOMERKEY]
	, [SALESORDERNUMBER]
	, [PROMOTIONKEY]
	, [CURRENCYKEY]
	, 2 [REVISIONNUMBER]
	, [ORDERQUANTITY]
	, [SALESAMOUNT]
FROM [FACTINTERNETSALES]
GO





