

 
--/*
		
--	Initial Test Data: 06MA01_20190205_014404_466349
     
--	 Scenario        Stored Procedure              TVP In Memory     In Memnory Table        Possible        SP Name(s)
--        2            Header Not Compiled             Yes                  Yes*              ??              Process_XML_2
--                     Child Compiled   



      


--*/
---- drop procedure  [Base].[XML_06MA01Message]
--CREATE    PROCEDURE [Base].[XML_06MA01Message]
--	--@tv_ReqToPay				base.tv_ReqToPay_native				READONLY,				--tv_ReqToPay
--	@tv_StgGroupHeader          base.tv_GroupHeader_XML_native		READONLY,			--tv_GrpHdr
--	@tv_StgTxSet                base.tv_TxSet_XML_native			READONLY,					--tv_TxSet
--	@tv_StgCreditItem           base.[tv_CreditItem_xml_native]		READONLY,				--tv_CrdtItm

--	@tv_StgAmount               base.tv_Amount_native				READONLY,					--tv_Amt
--	@tv_StgCreditItemFraudData  base.tv_CreditItemFraudData_native	READONLY,	--tv_CdtItmFrdDate
--	@tv_StgRepairedItem         base.tv_RepairedItem_native			READONLY,			--tv_RprdItm
--	@tv_StgDefaultedItem        base.tv_DefaultedItem_native		READONLY,			--tv_DfltdItm
--	--@tv_StgSwitchedItem       base.tv_SwitchedItem_native			READONLY,
--	@tv_StgDebitItem            base.tv_DebitItem_native			READONLY,				--tv_DbtItm
--	@tv_StgItemImageData        base.tv_ItemImageData_native		READONLY,			--tv_ItmImgData
--	--@tv_StgDebitItemFraudData base.tv_DebitItemFraudData_native	READONLY,
--	--/@tv_StgDebitDuplicateItem base.tv_DebitDuplicateItem_native	READONLY,
--	--@tv_StgDebitStoppedItem   base.tv_DebitStoppedItem_native		READONLY,
--	@tv_StgCore                 base.tv_Core_native					READONLY,					--tv_Core
--	@tv_StgEntity               base.tv_Entity_native				READONLY--tv_Entity
--AS
--BEGIN
--	IF 1=1
--	BEGIN

--		DELETE FROM [Test].[TVPTrace];
		
--		-- Debug @tv_StgGroupHeader  
--		INSERT INTO [Test].[TVPTrace] 
--		(
--			[Procedure],
--			[Step],
--			[XmlMessage]
--		) 
--		SELECT 
--			'[Base].[XML_06MA01Message]', 
--			'Trace of tv_StgGroupHeader', 
--			'<tv_StgGroupHeader>' + 
--			'<MsgId>' + convert(nvarchar(255),[MsgId]) + '</MsgId>'  +
--			'<CreDtTm>' + convert(nvarchar(255),[CreDtTm]) +'</CreDtTm>'  +
--			'<NbOfTxs>' + convert(nvarchar(255),[NbOfTxs]) + '</NbOfTxs>'   +
--			'<RcvrId>' + convert(nvarchar(255),[RcvrId]) +  '</RcvrId>' +
--			'<TstInd>' + convert(nvarchar(255),[TstInd]) + '</TstInd>' +
--			'<Sgntr>'  + left([Sgntr],255) + '</Sgntr>'  +
--			'<GroupHeaderId>'  + convert(nvarchar(255),ISNULL([GroupHeaderId],'')) + '</GroupHeaderId>' + 
--			'</tv_StgGroupHeader>' AS [XmlMessage]
--		FROM 
--			@tv_StgGroupHeader;


--		INSERT INTO [Test].[TVPTrace] 
--		(
--			[Procedure],
--			[Step],
--			[XmlMessage]
--		) 
--		SELECT 
--			'[Base].[XML_06MA01Message]', 
--			'Trace of tv_StgTxSet', 
--			'<tv_StgTxSet>' + 
--				'<TxSetId>' + convert(nvarchar(255),[TxSetId]) + '</TxSetId>'  +
--				'<TxSetVrsn> ' + convert(nvarchar(255),[TxSetVrsn]) + '</TxSetVrsn]>'  +
--				'<ColltngPtcptId> ' + convert(nvarchar(255),[ColltngPtcptId]) + '</ColltngPtcptId>'  +
--				'<CaptrdDtTm>  ' + convert(nvarchar(255),[CaptrdDtTm]) + '</CaptrdDtTm>'  +
--				'<TxSetSubDtTm>  ' + convert(nvarchar(255),[TxSetSubDtTm]) + '</TxSetSubDtTm>'  +
--				'<Src> ' + convert(nvarchar(255),[Src]) + '</Src>'  +
--				'<ColltngBrnchLctn>' + convert(nvarchar(255),[ColltngBrnchLctn]) + '</ColltngBrnchLctn>'  +
--				'<ColltngLctn> ' + convert(nvarchar(255),[ColltngLctn]) + '</ColltngLctn>'  +
--				'<ChanlRskTp>  ' + convert(nvarchar(255),[ChanlRskTp]) + '</ChanlRskTp>'  +
--				'<ChanlDesc>  ' + convert(nvarchar(255),[ChanlDesc]) + '</ChanlDesc>'  +
--				'<ColltnPt> ' + convert(nvarchar(255),[ColltnPt]) + '</ColltnPt>'  +
--				'<ColltngBrnchRef>' + convert(nvarchar(255),[ColltngBrnchRef]) + '</ColltngBrnchRef>'  +
--				'<NbOfItms>' + convert(nvarchar(255),[NbOfItms]) + '</NbOfItms>'  +
--				'<EndPtId>  ' + convert(nvarchar(255),[EndPtId]) + '</EndPtId>'  +
--				'<CrdtItm>' + convert(nvarchar(255),[CrdtItm]) + '</CrdtItm>'  +
--				'<DbtItm>' + convert(nvarchar(255),[DbtItm]) + '</DbtItm>'  +
--			'</tv_StgTxSet>' AS [XmlMessage]
--		FROM 
--			@tv_StgTxSet;

--		INSERT INTO [Test].[TVPTrace] 
--		(
--			[Procedure],
--			[Step],
--			[XmlMessage]
--		) 
--		SELECT 
--			'[Base].[XML_06MA01Message]', 
--			'Trace of tv_CreditItem_xml_native', 
--			'<tv_StgCreditItem>' + 
 
--			'<CdtItmId>' + convert(nvarchar(255),CdtItmId) + '</CdtItmId>'  +
--			'<CdtItmTp>' + convert(nvarchar(255),CdtItmTp) + '</CdtItmTp>'  +
--			'<CreditItem_Id>' + convert(nvarchar(255),CreditItem_Id) + '</CreditItem_Id>'  +
--			'<Amt>' + convert(nvarchar(255),Amt) + '</Amt>'  +
--			'<BkCd>' + convert(nvarchar(255),BkCd) + '</BkCd>'  +
--			'<RefNb>' + convert(nvarchar(255),RefNb) + '</RefNb>'  +
			 
--			'</tv_StgCreditItem>' AS [XmlMessage]
--		 FROM 
--			@tv_StgCreditItem;
--	END
--	return


--	select * from [Test].[TVPTrace]  ORDER BY TVPTrace;
--	-- 

--	--INSERT INTO [Test].[TVPTrace] ([Procedure],[Step],[XmlMessage]) 
--	--		select 
--	--		'<MsgId>' + [MsgId] + '</MsgId>' +
--	--		'<CreatedDatetime>' + convert(nvarchar(255),[CreatedDatetime]) + '</CreatedDatetime>' +
--	--		'<ReceiverId>' + convert(nvarchar(255),[ReceiverId]) + '<ReceiverId>' +
--	--		'<TstInd>' + convert(nvarchar(255),TstInd) +  '<TstInd>' +
--	--		'<Signature>' + convert(nvarchar(255),Signature) +  '<Signature>' +
--	--		'<ReqToPay_Idv>' + convert(nvarchar(255),ReqToPay_Idv) +  '<ReqToPay_Idv>'
--	--		 from @tv_StgGroupHeader



--	--SELECT IntMessageType from @tv_StgCore;
--	DECLARE @businessDate varchar = '2019-02-05';
--	DECLARE @ISODocumentId bigint;
 
--	--TODO We cannot use the REPLICATE Keyword in our native sp!
--	SET @ISODocumentId = CAST(CONCAT(CONVERT(VARCHAR(8), @businessDate, 112), REPLICATE('0', 11)) AS BIGINT) + NEXT VALUE FOR dbo.[sqn_MsgID];
	
	 
--	DECLARE @ShredTime DateTime2(2);

--	EXEC [Base].[XML_06MA01Message_Child_Shred_Native]	@tv_StgGroupHeader,	
--												@tv_StgTxSet,	
--												@tv_StgCreditItem,		
--												@tv_StgAmount,			
--												@tv_StgCreditItemFraudData,	
--												@tv_StgRepairedItem,	
--												@tv_StgDefaultedItem,	
--												--@tv_StgSwitchedItem,	
--												@tv_StgDebitItem,	
--												@tv_StgItemImageData,		
--												--@tv_StgDebitItemFraudData,	
--												--@tv_StgDebitDuplicateItem,
--												--@tv_StgDebitStoppedItem,	
--												@tv_StgCore,	
--												@tv_StgEntity,			
--												@businessDate,
--												@ISODocumentId, 
--												@ShredTime   OUTPUT

--	DECLARE @RC int
--	--DECLARE @tv_StgGroupHeader [Base].[tv_GroupHeader_native]
--	--DECLARE @tv_StgTxSet [Base].[tv_TxSet_native]
--	--DECLARE @tv_StgCreditItem [Base].[tv_CreditItem_native]
--	--DECLARE @tv_StgAmount [Base].[tv_Amount_native]
--	--DECLARE @tv_StgCreditItemFraudData [Base].[tv_CreditItemFraudData_Native]
--	--DECLARE @tv_StgRepairedItem [Base].[tv_RepairedItem_native]
--	--DECLARE @tv_StgDefaultedItem [Base].[tv_DefaultedItem_native]
--	--DECLARE @tv_StgSwitchedItem [Base].[tv_SwitchedItem_native]
--	--DECLARE @tv_StgDebitItem [Base].[tv_DebitItem_native]
--	--DECLARE @tv_StgItemImageData [Base].[tv_ItemImageData_native]
--	--DECLARE @tv_StgDebitItemFraudData [Base].[tv_DebitItemFraudData_native]
--	--DECLARE @tv_StgDebitDuplicateItem [Base].[tv_DebitDuplicateItem_Native]
--	--DECLARE @tv_StgDebitStoppedItem [Base].[tv_DebitStoppedItem_native]
--	--DECLARE @tv_StgCore [Base].[tv_Core_Native]
--	--DECLARE @tv_StgEntity [Base].[tv_Entity_native]
--	--DECLARE @businessDate date
--	--DECLARE @ISODocumentId bigint
--	DECLARE @xmlMessageId bigint
--	--DECLARE @ShredTime datetime2(2)

--	-- TODO: Set parameter values here.

--	--EXECUTE @RC = [Base].[usp_Load_XML_06MA01Message_Child_Loading] 
--	--   @tv_StgGroupHeader
--	--  ,@tv_StgTxSet
--	--  ,@tv_StgCreditItem
--	--  ,@tv_StgAmount
--	--  ,@tv_StgCreditItemFraudData
--	--  ,@tv_StgRepairedItem
--	--  ,@tv_StgDefaultedItem
--	--  --,@tv_StgSwitchedItem
--	--  ,@tv_StgDebitItem
--	--  ,@tv_StgItemImageData
--	--  --,@tv_StgDebitItemFraudData
--	--  --,@tv_StgDebitDuplicateItem
--	-- -- ,@tv_StgDebitStoppedItem
--	--  ,@tv_StgCore
--	--  ,@tv_StgEntity
--	--  ,@businessDate
--	--  ,@ISODocumentId
--	--  ,@xmlMessageId
--	--  ,@ShredTime OUTPUT
--END