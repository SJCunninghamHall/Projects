
CREATE PROCEDURE [Base].[XML_06MA01Message_v2_Audit_DfltdItm_XML]
@tv_DfltdItm_XML 	base.tv_DfltdItm_XML			READONLY
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
		'tv_DfltdItm_XML',
		'[DfltdItm_XML]'   AS [Results]
	FROM  @tv_DfltdItm_XML xml;
END