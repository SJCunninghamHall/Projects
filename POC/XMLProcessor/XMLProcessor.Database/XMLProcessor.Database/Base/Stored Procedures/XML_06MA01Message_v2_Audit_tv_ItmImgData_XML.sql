CREATE PROCEDURE [Base].[XML_06MA01Message_v2_Audit_tv_ItmImgData_XML]
	@tv_ItmImgData_XML 	base.tv_ItmImgData_XML			READONLY
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
		'tv_ItmImgData_XML',
		'<tv_ItmImgData_XML>' +
			'<Img>' + convert(nvarchar(255),[Img]) + '</Img>'  +	
			'<FrntImgQltyIndctnInd>' + convert(nvarchar(255),[FrntImgQltyIndctnInd]) + '</FrntImgQltyIndctnInd>'  +	
			'<BckImgQltyIndctnInd>' + convert(nvarchar(255),[BckImgQltyIndctnInd]) + '</BckImgQltyIndctnInd>'  +	
			'<DbtItem_Id>' + convert(nvarchar(255),[DbtItem_Id]) + '</DbtItem_Id>'  +	
		'</tv_ItmImgData_XML>' AS [Results]
	FROM  @tv_ItmImgData_XML;
END