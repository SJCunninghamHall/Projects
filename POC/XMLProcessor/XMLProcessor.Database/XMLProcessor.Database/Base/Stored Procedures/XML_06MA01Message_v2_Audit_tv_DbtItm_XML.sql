

CREATE PROCEDURE [Base].[XML_06MA01Message_v2_Audit_tv_DbtItm_XML]
	@tv_DbtItm_XML			base.tv_DbtItm_XML			READONLY
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
		'tv_DbtItm_XML', 
		'DbtItmId:[' + convert(nvarchar(255),[DbtItmId]) + '], '  + 
		'DbtItmTp:[' + convert(nvarchar(255),[DbtItmTp]) + '], '  + 
		'RpresentdItmInd:[' + convert(nvarchar(255),[DbtItmId]) + '], '  + 
		'BkCd:[' + convert(nvarchar(255),[DbtItmId]) + '], '  + 	
		'AcctNb:[' + convert(nvarchar(255),[DbtItmId])+ '], '  + 
		'SrlNb:[' + convert(nvarchar(255),[DbtItmId]) + '], '  + 
		'HghValItm:[' + convert(nvarchar(255),[DbtItmId]) + '], '  + 
		'DayOneRspnWndwStartDatetime:[' + convert(nvarchar(255),[DbtItmId]) + '], '  + 
		'DayOneRspnWndwEndDatetime:[' + convert(nvarchar(255),[DbtItmId]) + '], '  + 
		'DayTwoRspnWndwStartDatetime:[' + convert(nvarchar(255),[DbtItmId]) + '], '  + 
		'DayTwoRspnWndwEndDatetime:[' + convert(nvarchar(255),[DbtItmId]) + '], '  + 
		'XtrnlDataRef:[' + convert(nvarchar(255),[DbtItmId])+ '], '  + 
		'DbtItm_Id:[' + convert(nvarchar(255),[DbtItmId]) + '], '  + 
		'TxSet_Id:[' + convert(nvarchar(255),[DbtItmId]) + ']'    AS [Results]
	FROM  @tv_DbtItm_XML;
END