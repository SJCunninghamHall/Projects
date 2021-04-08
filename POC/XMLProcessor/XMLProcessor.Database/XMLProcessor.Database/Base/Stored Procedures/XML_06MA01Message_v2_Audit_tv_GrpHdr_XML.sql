CREATE PROCEDURE [Base].[XML_06MA01Message_v2_Audit_tv_GrpHdr_XML]
	@tv_GrpHdr_XML			base.tv_GrpHdr_XML			READONLY 
AS
BEGIN
 	-- ----------------------------------------------------
	-- Audit Contents of tv_GrpHdr_XML
	-- ----------------------------------------------------
	INSERT INTO [Test].[TVPTrace] 
	(
		[Procedure],
		[Step],
		[Results]
	) 
	SELECT 
		'[Base].[XML_06MA01Message_v2]' as [Procedure], 
		'tv_GrpHdr_XML' as [Step],  
		'[MsgId]=[' + convert(nvarchar(255),[MsgId]) + '], '  +
		'[CreDtTm]=[' + convert(nvarchar(255),[CreDtTm]) +'], '  +
		'[NbOfTxs]=[' + convert(nvarchar(255),[NbOfTxs]) + ', '   +
		'[RcvrId]=[' + convert(nvarchar(255),[RcvrId]) +  '], ' +
		'[TstInd]=[' + convert(nvarchar(255),[TstInd]) + '], ' +
		'[Sgntr]=['  + left([Sgntr],255) + '], '  +
		'[ReqToPay_Id]=[' + convert(nvarchar(255),[ReqToPay_Id]) + ']'   AS [Results]
	FROM 
		@tv_GrpHdr_XML;
END