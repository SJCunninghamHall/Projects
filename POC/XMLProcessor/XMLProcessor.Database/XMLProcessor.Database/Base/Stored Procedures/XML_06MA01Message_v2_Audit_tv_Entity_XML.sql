CREATE PROCEDURE [Base].[XML_06MA01Message_v2_Audit_tv_Entity_XML]
@tv_Entity_XML base.tv_Entity_XML			READONLY 
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
		'tv_Entity_XML',
		'EntityType:[' + convert(nvarchar(255),ISNULL(xml.EntityType,'')) + '], '  + 
		'EntityId:[' + convert(nvarchar(255),ISNULL(xml.EntityId,''))  + '], '  + 
		'StateRevision:[' + convert(nvarchar(255),ISNULL(xml.StateRevision,''))  + '], '  + 
		'EntityState:[' + convert(nvarchar(255),ISNULL(xml.EntityState,''))  + '], '  + 
		'SourceDateTime:[' + convert(nvarchar(255),ISNULL(xml.SourceDateTime,''))  + '], '  + 
		'Entities_Id:[' + convert(nvarchar(255),ISNULL(xml.Entities_Id,''))  + ']'    AS [Results]
	FROM  @tv_Entity_XML xml;
end