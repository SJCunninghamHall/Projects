
CREATE PROCEDURE [Base].[XML_06MA01Message_v2_Audit_tv_TxSet_XML]
	@tv_TxSet_XML			base.tv_TxSet_XML			READONLY 
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
		'tv_TxSet_XML',  
		'TxSetId : [' + convert(nvarchar(255),[TxSetId]) + '] '  + 
		'TxSetVrsn : [' + convert(nvarchar(255),[TxSetVrsn]) + '] '  + 	 
		'ColltngPtcptId : [' + convert(nvarchar(255),[ColltngPtcptId]) + '] '  + 		 
		'CaptrdDtTm : [' + convert(nvarchar(255),[CaptrdDtTm]) + '] '  + 	 
		'TxSetSubDtTm : [' + convert(nvarchar(255),[TxSetSubDtTm]) + '] '  + 	 
		'Src : [' + convert(nvarchar(255),[Src]) + '] '  + 			 
		'ColltngBrnchLctn : [' + convert(nvarchar(255),[ColltngBrnchLctn]) + '] '  + 	 
		'ColltngLctn : [' + convert(nvarchar(255),[ColltngLctn]) + '] '  + 		 
		'ChanlRskTp : [' + convert(nvarchar(255),[ChanlRskTp]) + '] '  + 	 
		'ChanlDesc : [' + convert(nvarchar(255),[ChanlDesc]) + '] '  + 					 
		'ColltnPt : [' + convert(nvarchar(255),[ColltnPt]) + '] '  + 				 
		'ColltngBrnchRef : [' + convert(nvarchar(255),[ColltngBrnchRef]) + '] '  +  
		'NbOfItms : [' + convert(nvarchar(255),[NbOfItms]) + '] '  + 			 
		'EndPtId : [' + convert(nvarchar(255),[EndPtId]) + '] '  + 	 
		'ReqToPay_Id : [' + convert(nvarchar(255),[ReqToPay_Id]) + ']'   AS [Results]
	FROM  @tv_TxSet_XML;
END