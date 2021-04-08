CREATE PROCEDURE [Base].[XML_06MA01Message_v2_Audit_tv_Entities_XML]
@tv_Entities_XML base.tv_Entities_XML			READONLY 
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
		'tv_Entities_XML',
		'Entities_Id:[' + convert(nvarchar(255),ISNULL(xml.[Entities_Id],''))  + '], '  + 
		'ICN_Id:[' + convert(nvarchar(255),ISNULL(xml.[ICN_Id],'')) + ']'   AS [Results]
	FROM  @tv_Entities_XML xml;
end