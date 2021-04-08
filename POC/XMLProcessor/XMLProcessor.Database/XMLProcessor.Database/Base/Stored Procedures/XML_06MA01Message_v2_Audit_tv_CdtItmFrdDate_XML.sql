CREATE PROCEDURE[Base].[XML_06MA01Message_v2_Audit_tv_CdtItmFrdDate_XML]
	@tv_CdtItmFrdDate_XML 	base.tv_CdtItmFrdDate_XML			READONLY
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
		'tv_CdtItmFrdDate_XML',
		'BnfcryNm:[' + convert(nvarchar(255),xml.[BnfcryNm]) + '], '  + 
		'VrtlCdtInd:[' + convert(nvarchar(255),xml.[VrtlCdtInd]) + '], '  + 
		'RefData:[' + convert(nvarchar(255),xml.[RefData]) + '], '  + 
		'CrdtItm_Id:[' + convert(nvarchar(255),xml.[CrdtItm_Id]) + ']'      AS [Results]
	FROM  @tv_CdtItmFrdDate_XML xml;
END