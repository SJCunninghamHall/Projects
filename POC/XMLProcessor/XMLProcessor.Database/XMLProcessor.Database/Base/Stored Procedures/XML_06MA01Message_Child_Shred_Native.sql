

/*
		
	EXEC base.[XML_06MA01Message_Child_Shred_Native]	@tv_StgGroupHeader,	
														@tv_StgTxSet,	
														@tv_StgCreditItem,		
														@tv_StgAmount,			
														@tv_StgCreditItemFraudData,	
														@tv_StgRepairedItem,	
														@tv_StgDefaultedItem,	
														--@tv_StgSwitchedItem,	
														@tv_StgDebitItem,	
														@tv_StgItemImageData,		
														--@tv_StgDebitItemFraudData,	
														--@tv_StgDebitDuplicateItem,
														--@tv_StgDebitStoppedItem,	
														@tv_StgCore,	
														@tv_StgEntity,			
														@businessDate,
														@ISODocumentId, 
														@ShredTime   OUTPUT

*/
CREATE PROCEDURE [Base].[XML_06MA01Message_Child_Shred_Native]
--@tv_ReqToPay				base.tv_ReqToPay_native READONLY,				--tv_ReqToPay
	@tv_StgGroupHeader			base.tv_GroupHeader_native READONLY,			--tv_GrpHdr
	@tv_StgTxSet				base.tv_TxSet_native READONLY,					--tv_TxSet
	@tv_StgCreditItem			base.tv_CreditItem_native READONLY,				--tv_CrdtItm
	@tv_StgAmount				base.tv_Amount_native READONLY,					--tv_Amt
	@tv_StgCreditItemFraudData	base.tv_CreditItemFraudData_native READONLY,	--tv_CdtItmFrdDate
	@tv_StgRepairedItem			base.tv_RepairedItem_native READONLY,			--tv_RprdItm
	@tv_StgDefaultedItem		base.tv_DefaultedItem_native READONLY,			--tv_DfltdItm


	--@tv_StgSwitchedItem			base.tv_SwitchedItem_native READONLY,
	@tv_StgDebitItem			base.tv_DebitItem_native READONLY,				--tv_DbtItm
	@tv_StgItemImageData		base.tv_ItemImageData_native READONLY,			--tv_ItmImgData

	--@tv_StgDebitItemFraudData	base.tv_DebitItemFraudData_native READONLY,
	--@tv_StgDebitDuplicateItem	base.tv_DebitDuplicateItem_native READONLY,
	--@tv_StgDebitStoppedItem		base.tv_DebitStoppedItem_native READONLY,

	@tv_StgCore					base.tv_Core_native READONLY,					--tv_Core
	@tv_StgEntity				base.tv_Entity_native READONLY,					--tv_Entity  
	@businessDate varchar,
	@ISODocumentId Bigint,
	  @ShredTime  DateTime2(2)  OUTPUT

WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE='us_english')
 
	DECLARE @tv_StgSwitchedItem			base.tv_SwitchedItem_native;		--missing from Params passed in 
	DECLARE @tv_StgDebitItemFraudData	base.tv_DebitItemFraudData_native;  --missing from Params passed in 
	DECLARE @tv_StgDebitDuplicateItem	base.tv_DebitDuplicateItem_native;  --missing from Params passed in 
	DECLARE @tv_StgDebitStoppedItem		base.tv_DebitStoppedItem_native;	--missing from Params passed in 



	DECLARE @CoreId                                   BIGINT;
	--DECLARE @ISODocumentId                  BIGINT;
	DECLARE @XMLMessageID								BIGINT;					

	DECLARE @DocumentType                     VARCHAR(10);
	DECLARE @RowPattern                       VARCHAR(150);
	DECLARE @ExtractId                        VARCHAR(26);
	DECLARE @MessageType						VARCHAR(6) = 'MSG06'; 
	DECLARE @IntMessageTypeParam				VARCHAR(6) = '06MA01';            
	DECLARE @ChargingParticipantId			VARCHAR(6);

	DECLARE @ICNEntityHolder					[Base].[ICNEntity_New];
	DECLARE @TVPTxSet							[Base].[tv_TxSet];
	DECLARE @TVPCredit							[Base].[tv_Credit_New];
	DECLARE @TVPDebit							[Base].[tv_Debit_New];
	DECLARE @TVPDocument						[Base].[tv_Document_New]
	DECLARE @TVPCore							[Base].[tv_Core_New]
	DECLARE @TVCreditFraudData					[Base].[tv_CreditFraudData]		


        --Preprocessing
        SET @DocumentType    = 'MSG06'
        SET @RowPattern             = Base.cfn_XML_Get_WrapperXPath(@DocumentType)
        --SET @ISODocumentId = CAST(CONCAT(CONVERT(VARCHAR(8), @businessDate, 112), REPLICATE('0', 11)) AS BIGINT) + NEXT VALUE FOR [Base].[sqn_MsgID];
              

              BEGIN --SHREDDIN XML to TVP 
             
				  --1)Document 
						 INSERT INTO @TVPDocument--1)Document 
					(
						 [DocumentId]           
						,[ParticipantId]       
						,[SubmissionDate]       
						,[Mechanism]           
						,[SubmissionCounter]     
						,[CreatedDate]         
						,[NumberOfEntries]      
						,[ReceiverParticipantId]
						,[SenderParticipantId]  
						,[ChargedParticipantId]         
						,[Signature]				         
						,[TestFlag]             
						,[DocumentMessageID]	
						,DocumentTypeXML	
					)
					SELECT
						@ISODocumentId
						,SUBSTRING(MsgId,1,6)
						,(Select DateAdd(DAY,(cast(SUBSTRING(MsgId, 9, 3) as int)),DateFromParts(cast('20'+ SUBSTRING(MsgId, 7, 2) as int)-1,12,31)))
						--,Base.cfn_XML_Convert_Date(SUBSTRING(MsgId, 7, 2), SUBSTRING(MsgId, 9, 3))
						,SUBSTRING(MsgId, 12, 1)
						,CAST(SUBSTRING(MsgId, 14, 10) AS BIGINT)
						,CreatedDatetime
						,CAST(NoOftransactions AS BIGINT)
						,ReceiverId
						,NULL--SndrId
						,NULL--DrctPtcpt
						,'666'--,[Signature]
						,TstInd
						,MsgId
						,NULL--DocTp
					FROM
						@tv_StgGroupHeader grpHeader;



			--declare @output nvarchar(max) 
			--select @output =  (select 
 
			
			--'<MsgId>' + [MsgId] + '</MsgId>' +
			--'<CreatedDatetime>' + convert(nvarchar(255),[CreatedDatetime]) + '</CreatedDatetime>'

			-- from @tv_StgGroupHeader );
			----[CreatedDatetime] ,
			----[NoOftransactions],
			----[ReceiverId] ,
			----[TstInd],
			----[Signature] ,
			----[ReqToPay_Id] 
			
			----from @tv_StgGroupHeader    )

 

 

		--2)tv_StgTxSet
                    

			INSERT INTO @TVPTxSet
				 (
					 XsdParseId					
					,[DocumentId]
					,[InternalTXId]
					,[CollectingPId]
					,[TXIdDate]
					,[Source]
					,[Sequence]
					,[Version]
					,[CollectingParticipantId]
					,[CaptureDate]
					,[TSetSubmissionDateTime]
					,[AltSource]
					,[NumberOfItems]
					,[EndPointId]
					,[CollectingBranchLocation]
					,[CollectingLocation]
					,[ChannelRiskType]
					,[ChannelDescription]
					,[CollectionPoint]
					,[CollectionBranchRef]
					,[FraudCheckOnly]			
				--	,[TransactionSetIdWithVersion]
					,[TransactionSetId]			
				 )		 	
				  SELECT 
					TxSet_Id
					,@ISODocumentId
					,@ISODocumentId --,@CoreId amended 22/07/2019
					,SUBSTRING(TxSetId,0, 6)
					,(Select DateAdd(DAY,(cast(SUBSTRING(TxSetId, 9, 3) as int)),DateFromParts(cast('20'+ SUBSTRING(TxSetId, 7, 2) as int)-1,12,31)))
					--,Base.cfn_XML_Convert_Date(SUBSTRING(TxSetId, 7, 2), SUBSTRING(TxSetId, 9, 3))
					,SUBSTRING(TxSetId, 12, 4)
					,SUBSTRING(TxSetId, 16, 7)
					,TxSetVersion
					,CollectionParticipantId
					,CapturedDateTime
					,TxSetSubmissionDateTime
					,[Source]
					,NoOfItems
					,EndPtId
					,CollectionBranchLocation
					,CollectingLocation
					,ChannelRsktp
					,ChannelDescription
					,CollectionPoint
					,CollectionBranchRef
					,NULL--FrdChckOnlyInd
				--	,TxSetId + SUBSTRING('00' + TXSetVersion, len('00' + TXSetVersion)-2,2) as TxSetId
					,TxSetId 
				FROM
					@tv_StgTxSet;



    
		--3)Credit

		   
					INSERT  INTO @TVPCredit
				(
					 XsdParseId
					,[ItemID]					 
					,[Reference]					 
					,[CreditId]					 
					--,[TXId]						 
					,[Revision]					 
					,[ItemTypeXML]	-- Before look				 
					,[CurrencyXML]	-- Before look				 
					,[Amount]					 
					,[AccountNumber]				 
					,[Sortcode]					 
					,[TranCode]					 
					,[RicherDataRef]				 
					,[OnUs]						 
					,[RepairedSortcode]			 
					,[RepairedAccount]			 
					,[RepairedAmount]			 
					,[RepairedSerial]			 
					,[RepairedReference]			 
					,[DefaultedSortcode]			 
					,[DefaultedAccount]			 
					,[DefaultedReference]		 
					 -------Images				 
					,[Image]						 
					,[ImageHash]					 
					,[CaptureId]					 
					,[CaptureDeviceID]			 
					,[CaptureLocation]			 
					,[CaptureDateTime]			 
					,[FrontImageQuality]			 
					,[RearImageQuality]			 
					 -----Credit Fraud Data		 
					,[ChequeAtRisk]				 
					,[BeneficiaryName]			 
					,[FraudVirtualCredit]		 
					,[ReferenceData]				 
					,[CashAmount]				 
					,[CashCurrencyXML]			-- Before look		 
					,[FundedAmount]				 
					,[FundedCurrencyXML]		-- Before look		 
					,[NonFundedAmount]		
					,[NonFundedCurrencyXML]		-- Before look		 
					,[NumberOfItems]				 
					 -----Switched Account info	 
					,[SwitchedSortcode]			 
					,[SwitchedAccountNumber]		 
					,[XMLId]						 
					,[EndPointId]				 
					,[CollectingParticipantId]	 
					,[TransactionSetId]			 
					,[Version]					 
				--	,[TSetIDWithVersion]			 
					,CaptureDate					 
					,[Source]					 					 
				)
        
				SELECT 
					TxSet_id --XSDPARSEID
					,@ISODocumentId --@CoreId amended 22/07/2019
					,RefNo AS [Reference]
					,CreditItemId AS [CreditId] 
					,(DatePart(dy,'2019-02-05') * 1000)  AS Revision
					,LkpItemTyp.Id [Itemtype]
					,AmtCurr.Id [Currency]
					,NULL--Amt [Amount]
					,NULL--StgCredit.AcctNb [AccountNumber]
					,StgCredit.BkCd [Sortcode]
					,NULL--CdtItmTxCd AS [TranCode]
					,NULL--XtrnlDataRef [RicherDataRef]
					,NULL--OnUsItmInd AS [OnUs]
					,BkCdRprdInd AS [RepairedSortcode]
					,AcctNbRrdInd AS [RepairedAccount]
					,AmtRprdInd AS [RepairedAmount]
					,SrlNbRprdInd AS [RepairedSerial]
					,RefNbRprdInd AS [RepairedReference]
					,BkCdDfltdInd AS [DefaultedSortcode]
					,AccNbDfltdInd AS [DefaultedAccount]
					,RefNoDfltdInd AS [DefaultedReference]
					,Img AS [Image]
					,null--ImgHash AS [ImageHash]
					,NULL AS [ImgCaptureId]
					,NULL AS [ImgCaptureDeviceId]
					,NULL AS [ImgCaptureLocation]
					,NULL AS [ImgCaptureDate]
					,NULL AS [FrontImageQuality]
					,NULL AS [RearImageQuality]
					,null--ChqAtRskInd AS [ChequeAtRisk]
					,BenificiaryName AS [BeneficiaryName]
					,VrtlCreditInd AS [FraudVirtualCredit]
					,RefData AS [ReferenceData]
					,null--CshAmt AS [CashAmount]
					,NULL--CashAmtCurr.Id AS [CashCurrency] --Not applicable for 06MA01
					,null--FnddAmt AS FundedAmount
					,NULL--FndDbAmtCurr.Id AS [FundedCurrency]--CashAmtCurr.Id AS [CashCurrency] --Not applicable for 06MA01
					,null--NonFunddAmt AS [NonFundedAmount]
					,NULL--NonFndDbAmtCurr.Id AS [NonFundedCurrency]--CashAmtCurr.Id AS [CashCurrency] --Not applicable for 06MA01
					,null--NbOfCdtsOrDbts AS [NumberOfItems]
					,stgSwitched.BkCd AS [SwitchedSortcode]
					,stgSwitched.AcctNb AS [SwitchedAccountNumber]
					,CreditItem_Id AS [XsdId]
					,Tx.EndPointId AS [EndPointId]
					,CollectingParticipantId AS [CollectingParticipantId]
					,TX.TransactionSetId AS [TransactionSetId]  		
					,NULL--TX.TransactionSetIdWithVersion AS TXSetVersion
					--,[TransactionSetId] + right('00'+ cast(TX.[TransactionSetIdWithVersion] as varchar(2)),2) as [TSetIDWithVersion]
					,TX.CaptureDate AS [CaptureDate]
					,[Source] AS [Source]
				FROM
					@tv_StgCreditItem StgCredit
					INNER JOIN @TVPTxSet Tx ON StgCredit.TxSet_id=Tx.XsdParseId
					LEFT OUTER JOIN @tv_StgRepairedItem stgRepaired ON StgCredit.CreditItem_Id=stgRepaired.Crditm_Id
					LEFT OUTER JOIN @tv_StgDefaultedItem stgDefault ON StgCredit.CreditItem_Id=stgDefault.CrdtItm_Id
					LEFT OUTER JOIN @tv_StgItemImageData stgImage ON StgCredit.CreditItem_Id=stgImage.DbtItem_Id
					LEFT OUTER JOIN @tv_StgCreditItemFraudData stgFraud ON StgCredit.CreditItem_Id=stgFraud.CrdItm_Id
					LEFT OUTER JOIN @tv_StgSwitchedItem stgSwitched ON StgCredit.CreditItem_Id=stgSwitched.CrdItm_Id
					LEFT OUTER JOIN @tv_StgAmount stgAmt ON stgAmt.CrdtItm_Id=StgCredit.CreditItem_Id
					LEFT OUTER JOIN Lookup.ItemType LkpItemTyp ON StgCredit.CreditItemTp = LkpItemTyp.ItemTypeCode collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN Lookup.Currency AmtCurr ON stgAmt.Ccy = AmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					--LEFT OUTER JOIN Lookup.Currency CashAmtCurr ON X.[CashCurrency] = CashAmtCurr.Currency
					--LEFT OUTER JOIN Lookup.Currency FndDbAmtCurr ON X.[FundedCurrency] = FndDbAmtCurr.Currency
					--LEFT OUTER JOIN Lookup.Currency NonFndDbAmtCurr ON X.[NonFundedCurrency] = NonFndDbAmtCurr.Currency;	
					   
		   
		--4)Debit     
                
					INSERT  INTO @TVPDebit
				(
					XsdParseId
					,ItemId							
					,Revision						
					--,TXId							
					,SerialNumber					
					,DebitId							
					,[ItemTypeXML]	-- Before look				 
					,[CurrencyXML]	-- Before look						
					,[Amount]						
					,[AccountNumber]					
					,[Sortcode]						
					,[TranCode]						
					,[RicherDataRef]					
					,[Day1ResponseStartDateTime]		
					,[Day1ResponseEndDateTime]		
					,[Day2ResponseStartDatetime]		
					,[Day2ResponseEndDateTime]		
					,[PayReasonCode]					
					,[SettlementPeriodId]			
					,[FraudStatusCode]				
					,[FraudReasonCode]				
					,[OnUs]							
					,[Represent]						
					,[HighValue]						
					,[PayDecision]					
					,[RepairedSortcode]				
					,[RepairedAccount]				
					,[RepairedAmount]				
					,[RepairedSerial]				
					,[RepairedReference]				
					,[DefaultedSortcode]				
					,[DefaultedAccount]				
					,[DefaultedSerialNumber]			
					 -------Images				
					,[Image]							
					,[ImageHash]						
					,[CaptureId]						
					,[CaptureDeviceID]				
					,[CaptureLocation]				
					,[CaptureDateTime]				
					,[FrontImageQuality]				
					,[RearImageQuality]				
					 -------Fraud					
					,RiskInd							
					,DateOfFirstChq					
					,DateOfLastChq					
					,NbOfCounterparties				
					,NbOfGoodCheques					
					,NbOfFraudCheques				
					,HighestAmt						
					,LargestAmountCurrencyXML	 -- Before look			
					,RiskIndicator					
					 -------Switched					
					,SwitchedSortCode				
					,SwitchedAccount					
					 -------DuplicateItem			
					,DuplicateItemId					
					,DuplicateStatus					
					,DateFirstSeen					
					,OriginalCollectingParticipant	
					,OriginalCaptureDate				
					,OriginalSource					
					-------Stopped					
					,StopDate						
					,StopStatus						
					,StopAmount						
					,StopAmountCurrencyXML	 -- Before look			
					,StopBeneficiary					
					,StopStartRange					
					,StopEndRange					
					,XMLId							
					,[EndPointId]					
					,[CollectingParticipantId]		
					,[TransactionSetId]				
					,[Version]						
					,[TSetIDWithVersion]				
					,CaptureDate						
					,[Source]						
				)
				SELECT
					TxSet_Id
					,@ISODocumentId --@CoreId amended 22/07/2019
					,(DatePart(dy,'2019-02-05') * 1000)  AS Revision
					,SrlNb AS [SerialNumber]
					,DbtItmId AS [DebitId]
					,LkpItemTyp.Id AS [Itemtype]
					,AmtCurr.Id AS [Currency]
					,NULL--stgDebit.Amt AS [Amount]
					,stgDebit.AcctNb AS [AccountNumber]
					,stgDebit.BkCd AS [Sortcode]
					,NULL--DbtItmTxCd AS [TranCode]
					,XmlDataRef AS [RicherDataRef]
					,DayOneRspnWndwStartDatetime AS [Day1ResponseStartDateTime]
					,DayOneRspnWndwEndDatetime AS [Day1ResponseEndDateTime]
					,DayTwoRspnWndwStartDatetime AS [Day2ResponseStartDatetime]
					,DayTwoRspnWndwEndDatetime AS [Day2ResponseEndDateTime]
					,NULL--PayDcsnRsnCd AS [PayReasonCode]
					,NULL--SttlmPrdId AS SettlementPeriodId
					,NULL--FrdStsCd AS [FraudStatusCode]
					,NULL--FrdRsnCd AS [FraudReasonCode]
					,NULL--OnUsItmInd AS [OnUs]
					,RpresentdItmInd AS [Represent]
					,HghValItm AS [HighValue]
					,NULL--PayDcsnInd AS [PayDecision]
					,BkCdRprdInd AS [RepairedSortcode]
					,AcctNbRrdInd AS [RepairedAccount]
					,AmtRprdInd AS [RepairedAmount]
					,SrlNbRprdInd AS [RepairedSerial]
					,RefNbRprdInd AS [RepairedReference]
					,BkCdDfltdInd AS [DefaultedSortcode]
					,AccNbDfltdInd AS [DefaultedAccount]
					,SrlNbDfltdInd AS [DefaultedSerialNumber]
					,Img AS [Image]
					,null--ImgHash AS [ImageHash]
					,NULL AS [ImgCaptureId]
					,NULL AS [ImgCaptureDeviceId]
					,NULL AS [ImgCaptureLocation]
					,NULL AS [ImgCaptureDate]
					,NULL AS [FrontImageQuality]
					,NULL AS [RearImageQuality]
					,ChqAtRskInd AS [RiskInd]
					,DtOfFrstChq AS [DateOfFirstChq]
					,DtOfLstChq AS [DateOfLastChq]
					,NbOfCtrPtys AS [NbOfCounterparties]
					,NbOfVldChqs AS [NbOfGoodCheques]
					,NofFrdChqs AS [NbOfFraudCheques]
					,NULL--HghstAmt AS [HighestAmt]
					,NULL --,HgtAmtCurr.Id AS [LargestAmountCurrency]
					,RskInd AS [RiskIndicator]
					,stgSwitched.BkCd AS [SwitchedSortCode]
					,stgSwitched.AcctNb AS [SwitchedAccount]
					,DplctItmId AS [DuplicateItemID]
					,DbDplctStatus AS [DuplicateStatus]
					,DbtFirstPresented AS [DateFirstSeen]
					,MmbId AS [OriginalCollectingParticipant]
					,OriginalCaptureDate AS [OriginalCaptureDate]
					,OriginalSource AS [OriginalSource]          
					,StoppedDate AS [StopDate]
					,StoppedStatus AS [StopStatus]
					,NULL--stgStopped.Amt AS [StopAmount]
					,NULL--,StpAmtCurr.Id AS [StpAmtCurrency]
					,BeneficiaryName AS [StopBeneficiary]
					,StoppedItemStartFlg AS [StopStartRange]
					,StoppedItemEndFlg AS [StopEndRange]
					,stgDebit.DbtItm_Id AS [XsdId]
					,tX.EndPointId AS [EndPointId]
					,CollectingParticipantId AS [CollectingParticipantId] 
					,TransactionSetId AS [TransactionSetId]
					,[Version]
					,[TransactionSetId] + substring('00'+ cast(TX.[Version] as varchar(2)), len('00'+ cast(TX.[Version] as varchar(2))-2),2) as [TSetIDWithVersion]
					,tX.CaptureDate AS CaptureDate
					,[Source] AS [Source]
				FROM
					@tv_StgDebitItem stgDebit
					INNER JOIN @TVPTxSet Tx ON Tx.XsdParseId = stgDebit.TxSet_Id
					LEFT OUTER JOIN @tv_StgRepairedItem stgRepaired ON stgRepaired.DbtItem_Id=stgDebit.DbtItm_Id
					LEFT OUTER JOIN @tv_StgDefaultedItem stgDefault ON stgRepaired.DbtItem_Id=stgDefault.DbtItm_Id
					LEFT OUTER JOIN @tv_StgItemImageData stgImage ON stgDebit.DbtItm_Id=stgImage.DbtItem_Id
					LEFT OUTER JOIN @tv_StgDebitItemFraudData stgFraud ON stgRepaired.DbtItem_Id=stgFraud.DbtItm_Id
					LEFT OUTER JOIN @tv_StgSwitchedItem stgSwitched ON stgRepaired.DbtItem_Id=stgSwitched.CrdItm_Id
					LEFT OUTER JOIN @tv_StgDebitDuplicateItem stgDuplicate ON stgRepaired.DbtItem_Id=stgDuplicate.DbtItm_Id
					LEFT OUTER JOIN @tv_StgDebitStoppedItem stgStopped ON stgRepaired.DbtItem_Id=stgStopped.DbtItem_Id			            
					LEFT OUTER JOIN @tv_StgAmount stgAmt ON stgAmt.DbtItm_Id=stgDebit.DbtItm_Id
					LEFT OUTER JOIN Lookup.ItemType LkpItemTyp ON stgDebit.DbtItmTp = LkpItemTyp.ItemTypeCode collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN Lookup.Currency AmtCurr ON stgAmt.Ccy = AmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					--LEFT OUTER JOIN Lookup.Currency StpAmtCurr ON X.[StopAmountCurrency] = StpAmtCurr.Currency
					--LEFT OUTER JOIN Lookup.Currency FrdHgtAmtCurr ON X.[LargestAmountCurrency] = FrdHgtAmtCurr.Currency;
                             
     
	 
	 
	   --5)Core                    
       

	   		INSERT INTO @TVPCore
				(	
					 [CoreId]	,
					[ExtractId]			
					,[PostingExtractId]
					,[ParticipantId]				
					,[MessageTypeXML]	
					,[IntMessageType]	
					,[Source]			
					,[Destination]		
					,[RecordCount]		   
				)
				SELECT
					@ISODocumentId, --@CoreId amended 22/07/2019
					ExtractId
					,NULL--PostingExtractId
					,ProcessingParticipantId
					,ExtMessageType
					,IntMessageType
					,MessageSource
					,MessageDestination
					,RecordCount
				FROM 
					@tv_StgCore core
					LEFT OUTER JOIN [Lookup].[MessageType] LkpDocType ON core.ExtMessageType = LkpDocType.MessageType collate SQL_Latin1_General_CP1_CI_AS;



		 --6)Entity                  
          
		  
			  INSERT INTO @ICNEntityHolder 
				(	
					 [EntityId]
					,[CoreId]
					,[EntityType]
					,[EntityIdentifier]
					,[Revision]
					,[EntityState]
					,[SourceDateTime]
					,[ErrorCode]
					,[ErrorDescription]
				)
				SELECT 
					--??CAST(CONCAT(CONVERT(VARCHAR(8), @businessDate, 112), REPLICATE('0', 11)) AS BIGINT) + NEXT VALUE FOR [Base].[sqn_MsgID]
					@CoreId
					,@CoreId
					,EntityType
					,EntityId
					,StateRevision
					,EntityState
					,SourceDateTime
					,null
					,null
				FROM
					@tv_StgEntity Entity;
				   
                                                                                       
              SET @ShredTime       = CAST(GETDATE() AS DATETIME2(2))     
              END; 

			BEGIN --READ/UPDATE TVP

				SELECT 
					@ChargingParticipantId= [ChargedParticipantId] 
				FROM 
					@TVPDocument

				SELECT 
					@ExtractId = ExtractId
				From 
					@TVPCore
DECLARE @i INT,  @max INT, @DocMessId INT, @XMLMessID INT
				--UPDATE @TVPDocument	 
				
				SELECT  @i =  min( [RowNumber]), @max = Count( [RowNumber]) FROM @TVPDocument Doc
					LEFT OUTER JOIN [Lookup].[MessageType] DocType ON DocType.MessageType = Doc.DocumentTypeXML collate SQL_Latin1_General_CP1_CI_AS

				WHILE @i <= @max
				BEGIN
					SELECT @DocMessId = DocType.MessageId, @XMLMessID = @XMLMessageID
					FROM @TVPDocument Doc
					LEFT OUTER JOIN [Lookup].[MessageType] DocType ON DocType.MessageType = Doc.DocumentTypeXML collate SQL_Latin1_General_CP1_CI_AS
					WHERE [RowNumber] = @i
					UPDATE @TVPDocument 
							SET DocumentType= @DocMessId,
							XMLMessageId = @XMLMessID
					--SET @i +=1;
					SELECT  @i =  min( [RowNumber]) FROM @TVPDocument Doc
					LEFT OUTER JOIN [Lookup].[MessageType] DocType ON DocType.MessageType = Doc.DocumentTypeXML collate SQL_Latin1_General_CP1_CI_AS
					Where [RowNumber] > @i

				END
				
				/*declare  @tv_new_debit base.[tv_Document_New1]

				insert into @tv_new_debit 

				select @DocMessId,[ParticipantId] as [ParticipantId]
				          --UPDATE @TVPDocument 
							--XMLMessageId = @XMLMessID
					 FROM @TVPDocument Doc
					LEFT OUTER JOIN [Lookup].[MessageType] DocType 
					ON DocType.MessageType = Doc.DocumentTypeXML collate SQL_Latin1_General_CP1_CI_AS
					
					update @tv_new_debit  SET DocumentId= @DocMessId,
							               [ParticipantId] = @XMLMessID*/

				--UPDATE @TVPDocument
				--SET DocumentType= DocType.MessageId,
				--	XMLMessageId = @XMLMessageID
				--FROM @TVPDocument Doc
				--	 LEFT OUTER JOIN [Lookup].[MessageType] DocType ON DocType.MessageType = Doc.DocumentTypeXML
			
				--UPDATE @TVPCore

				SELECT @i =  min( [RowNumber]), @max = Max( [RowNumber]) FROM @TVPCore C
					 LEFT OUTER JOIN [Lookup].[MessageType] DocType ON DocType.MessageType = C.MessageTypeXML collate SQL_Latin1_General_CP1_CI_AS
				
				WHILE @i <= @max
				BEGIN
					SELECT @DocMessId = DocType.MessageId, @XMLMessID = @XMLMessageID
					FROM @TVPCore C
					LEFT OUTER JOIN [Lookup].[MessageType] DocType ON DocType.MessageType = C.MessageTypeXML collate SQL_Latin1_General_CP1_CI_AS
					Where [RowNumber] = @i

					UPDATE @TVPCore 
							SET MessageType= @DocMessId,
							XMLMessageId = @XMLMessID

					SELECT @i =  min( [RowNumber]) FROM @TVPCore C
					 LEFT OUTER JOIN [Lookup].[MessageType] DocType ON DocType.MessageType = C.MessageTypeXML collate SQL_Latin1_General_CP1_CI_AS
					 Where [RowNumber] > @i
			
				END

				
				--UPDATE @TVPCore
				--SET MessageType = DocType.MessageId ,
				--	XMLMessageId = @XMLMessageID
				--FROM @TVPCore C
				--	 LEFT OUTER JOIN [Lookup].[MessageType] DocType ON DocType.MessageType = C.MessageTypeXML
			
			
				--UPDATE @TVPCredit
				DECLARE @TXId INT, @ItemType TinyInt, @Currency TinyInt, @CashCurrency TinyInt, @FundedCurrency TinyInt, @NonFundedCurrency TinyInt
				SELECT @i =  min( [RowNumber]), @max = Max( [RowNumber]) FROM @TVPCredit CR
				INNER JOIN @TVPTxSet Tx							ON Tx.XsdParseId = CR.XsdParseId 
				LEFT OUTER JOIN LOOKUP.ItemType LkpItemTyp		ON CR.ItemTypeXML = LkpItemTyp.ItemTypeCode collate SQL_Latin1_General_CP1_CI_AS
				LEFT OUTER JOIN LOOKUP.Currency AmtCurr			ON CR.CurrencyXML = AmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
				LEFT OUTER JOIN LOOKUP.Currency CashAmtCurr		ON CR.CashCurrencyXML = CashAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
				LEFT OUTER JOIN LOOKUP.Currency FndDbAmtCurr	ON CR.FundedCurrencyXML = FndDbAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
				LEFT OUTER JOIN LOOKUP.Currency NonFndDbAmtCurr ON CR.NonFundedCurrencyXML = NonFndDbAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS

				WHILE @i <= @max
				BEGIN
					SELECT @TXId = Tx.[InternalTXId], @ItemType = LkpItemTyp.Id,  @Currency = AmtCurr.Id, @CashCurrency = CashAmtCurr.Id, @FundedCurrency =FndDbAmtCurr.Id,
					 @NonFundedCurrency = NonFndDbAmtCurr.Id
					FROM  @TVPCredit CR
					INNER JOIN @TVPTxSet Tx							ON Tx.XsdParseId = CR.XsdParseId 
					LEFT OUTER JOIN LOOKUP.ItemType LkpItemTyp		ON CR.ItemTypeXML = LkpItemTyp.ItemTypeCode collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency AmtCurr			ON CR.CurrencyXML = AmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency CashAmtCurr		ON CR.CashCurrencyXML = CashAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency FndDbAmtCurr	ON CR.FundedCurrencyXML = FndDbAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency NonFndDbAmtCurr ON CR.NonFundedCurrencyXML = NonFndDbAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					Where [RowNumber] = @i

					UPDATE @TVPCredit 
							SET [TXId]= @TXId,
							[ItemType] = @ItemType,
							[Currency] = @Currency,
							[CashCurrency] = @CashCurrency,
							[FundedCurrency] = @FundedCurrency,
							[NonFundedCurrency] = @NonFundedCurrency
					
					SELECT @i =  min( [RowNumber]) FROM  @TVPCredit CR
					INNER JOIN @TVPTxSet Tx							ON Tx.XsdParseId = CR.XsdParseId 
					LEFT OUTER JOIN LOOKUP.ItemType LkpItemTyp		ON CR.ItemTypeXML = LkpItemTyp.ItemTypeCode collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency AmtCurr			ON CR.CurrencyXML = AmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency CashAmtCurr		ON CR.CashCurrencyXML = CashAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency FndDbAmtCurr	ON CR.FundedCurrencyXML = FndDbAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency NonFndDbAmtCurr ON CR.NonFundedCurrencyXML = NonFndDbAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					Where [RowNumber] > @i
				END


			--UPDATE @TVPCredit
			--SET 
			--	[TXId]				= Tx.[InternalTXId] , 
			--	[ItemType]			= LkpItemTyp.Id ,
			--	[Currency]			= AmtCurr.Id,
			--	[CashCurrency]		= CashAmtCurr.Id,
			--	[FundedCurrency]	= FndDbAmtCurr.Id,
			--	[NonFundedCurrency]	= NonFndDbAmtCurr.Id
			--FROM @TVPCredit CR
			--	INNER JOIN @TVPTxSet Tx							ON Tx.XsdParseId = CR.XsdParseId
			--	LEFT OUTER JOIN LOOKUP.ItemType LkpItemTyp		ON CR.ItemTypeXML = LkpItemTyp.ItemTypeCode
			--	LEFT OUTER JOIN LOOKUP.Currency AmtCurr			ON CR.CurrencyXML = AmtCurr.Currency
			--	LEFT OUTER JOIN LOOKUP.Currency CashAmtCurr		ON CR.CashCurrencyXML = CashAmtCurr.Currency
			--	LEFT OUTER JOIN LOOKUP.Currency FndDbAmtCurr	ON CR.FundedCurrencyXML = FndDbAmtCurr.Currency
			--	LEFT OUTER JOIN LOOKUP.Currency NonFndDbAmtCurr ON CR.NonFundedCurrencyXML = NonFndDbAmtCurr.Currency


			--INSERT INTO @TVCreditFraudData 
			INSERT INTO @TVCreditFraudData 
			(
				ItemId,
				BeneficiaryName
			)
			SELECT
				ItemId,
				BeneficiaryName
			FROM
				@TVPCredit
			WHERE
				( 
					[BeneficiaryName] IS NOT NULL OR 
					[ReferenceData] IS NOT NULL OR
					[FraudVirtualCredit] IS NOT NULL OR
					[NumberOfItems] IS NOT NULL
				)

			--UPDATE @TVPDebit
			
				DECLARE @LargestAmountCurrency TinyInt, @StpAmtCurrency TinyInt

				SELECT @i =  min(1), @max = Max(1)  FROM @TVPDebit DB
				INNER JOIN @TVPTxSet Tx							ON Tx.XsdParseId = DB.XsdParseId 
				LEFT OUTER JOIN LOOKUP.ItemType LkpItemTyp		ON DB.ItemTypeXML = LkpItemTyp.ItemTypeCode collate SQL_Latin1_General_CP1_CI_AS
				LEFT OUTER JOIN LOOKUP.Currency AmtCurr			ON DB.CurrencyXML = AmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
				LEFT OUTER JOIN LOOKUP.Currency StpAmtCurr		ON DB.StopAmountCurrencyXML = StpAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
				LEFT OUTER JOIN LOOKUP.Currency FrdHgtAmtCurr	ON DB.LargestAmountCurrencyXML = FrdHgtAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS;

				WHILE @i <= @max
				BEGIN
					SELECT @TXId = Tx.[InternalTXId], @ItemType = LkpItemTyp.Id,  @Currency = AmtCurr.Id, @CashCurrency = FrdHgtAmtCurr.Id, @FundedCurrency =StpAmtCurr.Id
					FROM  @TVPDebit DB
					INNER JOIN @TVPTxSet Tx							ON Tx.XsdParseId = DB.XsdParseId 
					LEFT OUTER JOIN LOOKUP.ItemType LkpItemTyp		ON DB.ItemTypeXML = LkpItemTyp.ItemTypeCode collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency AmtCurr			ON DB.CurrencyXML = AmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency StpAmtCurr		ON DB.StopAmountCurrencyXML = StpAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency FrdHgtAmtCurr	ON DB.LargestAmountCurrencyXML = FrdHgtAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					Where [RowNumber] = @i

					UPDATE @TVPDebit 
							SET [TXId]= @TXId,
							[ItemType] = @ItemType,
							[Currency] = @Currency,
							[LargestAmountCurrency] = @CashCurrency,
							[StpAmtCurrency] = @FundedCurrency
					SET @i +=1;

					SELECT @i =  min(1) FROM @TVPDebit DB
					INNER JOIN @TVPTxSet Tx							ON Tx.XsdParseId = DB.XsdParseId 
					LEFT OUTER JOIN LOOKUP.ItemType LkpItemTyp		ON DB.ItemTypeXML = LkpItemTyp.ItemTypeCode collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency AmtCurr			ON DB.CurrencyXML = AmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency StpAmtCurr		ON DB.StopAmountCurrencyXML = StpAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					LEFT OUTER JOIN LOOKUP.Currency FrdHgtAmtCurr	ON DB.LargestAmountCurrencyXML = FrdHgtAmtCurr.Currency collate SQL_Latin1_General_CP1_CI_AS
					Where [RowNumber] > @i
				END	
			
					
			--UPDATE @TVPDebit
			--SET 
			--	[TXId] =Tx.[InternalTXId] , 
			--	[ItemType]= LkpItemTyp.Id ,
			--	[Currency]=AmtCurr.Id,
			--	[LargestAmountCurrency]=FrdHgtAmtCurr.Id ,
			--	[StpAmtCurrency] =StpAmtCurr.Id
			--FROM @TVPDebit DB
			--	INNER JOIN @TVPTxSet Tx							ON Tx.XsdParseId = DB.XsdParseId
			--	LEFT OUTER JOIN LOOKUP.ItemType LkpItemTyp		ON DB.ItemTypeXML = LkpItemTyp.ItemTypeCode
			--	LEFT OUTER JOIN LOOKUP.Currency AmtCurr			ON DB.CurrencyXML = AmtCurr.Currency
			--	LEFT OUTER JOIN LOOKUP.Currency StpAmtCurr		ON DB.StopAmountCurrencyXML = StpAmtCurr.Currency
			--	LEFT OUTER JOIN LOOKUP.Currency FrdHgtAmtCurr	ON DB.LargestAmountCurrencyXML = FrdHgtAmtCurr.Currency;




			
			END
       
END
GO