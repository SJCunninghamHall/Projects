CREATE PROCEDURE[Base].[XML_06MA01Message_v2_Audit_tv_CrdItm_XML]
@tv_CrdItm_XML 	base.tv_CrdItm_XML			READONLY
AS
BEGIN
	INSERT INTO [Test].[TVPTrace] 
	(
		[Procedure],
		[Step],
		[Results]
	) 
	SELECT 
		'[Base].[XML_06MA01Message_v2]', 
		'tv_CrdItm_XML',
 		'CreditItemId:[' + convert(nvarchar(255),[CreditItemId]) + '], '  + 
		'CreditItemTp:[' + convert(nvarchar(255),[CreditItemTp]) + '], '  + 
		'CreditItem_Id:[' + convert(nvarchar(255),[CreditItem_Id]) + '], '  + 
		'BkCd:[' + convert(nvarchar(255),[BkCd]) + '], '  + 
		'AcctNb:[' + convert(nvarchar(255),[AcctNb]) + '], '  + 
		'RefNo:[' + convert(nvarchar(255),[RefNo]) + '], '  + 
		'TxSet_Id:[' + convert(nvarchar(255),[TxSet_Id])  + ']'     AS [Results]
	FROM  @tv_CrdItm_XML;
END