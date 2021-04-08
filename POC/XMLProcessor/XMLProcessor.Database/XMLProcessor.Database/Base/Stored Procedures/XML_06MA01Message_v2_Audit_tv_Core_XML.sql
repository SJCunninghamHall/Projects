CREATE PROCEDURE [Base].[XML_06MA01Message_v2_Audit_tv_Core_XML]
	@tv_Core_XML			base.tv_Core_XML			READONLY 
AS
BEGIN
-- ----------------------------------------------------
	-- Trace Contents of tv_Core_XML
	-- ----------------------------------------------------
	INSERT INTO [Test].[TVPTrace] 
	(
		[Procedure],
		[Step],
		[Results]
	) 
	SELECT 
		'[Base].[XML_06MA01Message_v2]' as [Procedure], 
		'tv_Core_XML' as [Step], 
		'BusinessDate:[' + convert(nvarchar(255),[BusinessDate]) + '], '  + 
		'ExtractId:[' + convert(nvarchar(255),[ExtractId]) + '], '  +  
		'ProcessingParticipantId:[' + convert(nvarchar(255),[ProcessingParticipantId]) + '], '  + 
		'ExtMessageType:[' + convert(nvarchar(255),[ExtMessageType])+ '], '  + 
		'IntMessageType:[' + convert(nvarchar(255),[IntMessageType]) + '], '  + 
		'MessageSource:[' + convert(nvarchar(255),[MessageSource]) + '], '  + 		 
		'MessageDestination:[' + convert(nvarchar(255),[MessageDestination])+ '], '  + 
		'RecordCount:[' + convert(nvarchar(255),[RecordCount]) + '], '  + 
		'ICN_Id:[' + convert(nvarchar(255),[ICN_Id])  + ']'  AS [Results]
	FROM 
		@tv_Core_XML;
END