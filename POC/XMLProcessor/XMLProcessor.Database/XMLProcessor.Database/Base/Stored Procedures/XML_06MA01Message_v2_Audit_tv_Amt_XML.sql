
CREATE PROCEDURE [Base].[XML_06MA01Message_v2_Audit_tv_Amt_XML]
@tv_Amt_XML base.tv_Amt_XML			READONLY 
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
		'tv_Amt_XML',
		'Ccy:[' + convert(nvarchar(255),ISNULL(xml.Ccy,'')) + '], '  + 
		'Amt_Text:[' + convert(nvarchar(255),ISNULL(xml.Amt_Text,'')) + '], '  + 
		'CrdtItm_Id:[' + convert(nvarchar(255),ISNULL(xml.CrdtItm_Id,'')) + '], '  + 
		'DbtItm_Id:[' + convert(nvarchar(255),ISNULL(xml.DbtItm_Id,'')) + ']'     AS [Results]
	FROM  @tv_Amt_XML xml;
END