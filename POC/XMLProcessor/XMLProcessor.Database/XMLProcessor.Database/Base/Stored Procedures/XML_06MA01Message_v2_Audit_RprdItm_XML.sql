
CREATE PROCEDURE [Base].[XML_06MA01Message_v2_Audit_RprdItm_XML]
@tv_RprdItm_XML 	base.tv_RprdItm_XML			READONLY
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
		'tv_RprdItm_XML',	
		'BkCdRprdInd:[' + convert(nvarchar(255), ISNULL(xml.BkCdRprdInd,'') ) + '] '  + 
		'AcctNbRprdInd:[' + convert(nvarchar(255),ISNULL(xml.AcctNbRprdInd,'')) + '] '  + 
		'AmtRprdInd:[' + convert(nvarchar(255),ISNULL(xml.AmtRprdInd,'')) + '] '  + 
		'SrlNbRprdInd:[' + convert(nvarchar(255),ISNULL(xml.SrlNbRprdInd,'')) + '] '  + 
		'RefNbRprdInd:[' + convert(nvarchar(255),ISNULL(xml.RefNbRprdInd,'')) + '] '  + 
		'CrdtItm_Id:[' + convert(nvarchar(255),ISNULL(xml.CrdtItm_Id,'')) + '] '  + 
		'DbtItm_Id:[' + convert(nvarchar(255),ISNULL(xml.DbtItm_Id,'')) + ']'   AS [Results]
	FROM  @tv_RprdItm_XML xml;
END