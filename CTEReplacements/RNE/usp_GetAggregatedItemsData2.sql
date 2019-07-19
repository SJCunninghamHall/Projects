CREATE PROCEDURE [Posting].[usp_GetAggregatedItemsData]
( @PostingID VARCHAR(26), @RneMoID BIGINT)
/*****************************************************************************************************
* Name				: [Posting].[usp_GetAggregatedItemsData]
* Description		: Loads Aggregation items to Aggregation table for validation
* Called By			: IPSL.RNE.LoadAndExtractArchive.dtsx
* Type of Procedure : Interpreted stored procedure
* Author			: Anush
* Creation Date		: 30/10/2017
* Last Modified		: 
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************/
AS

	SET NOCOUNT ON;
	 
	BEGIN TRY

		BEGIN			

			IF ( SELECT [ConfigValue] FROM   [Config].[ApplicationConfig]   WHERE  ConfigType = 'CREAgg'  AND [ConfigParameter] = 'Enabled' ) = 1
			BEGIN
					
				SELECT DISTINCT
					MAX([PostingID]) OVER(PARTITION BY RecordTranSetID ORDER BY RNEMOID DESC) AS [PostingID],
					MAX(RnEMoID) OVER(PARTITION BY RecordTranSetID ORDER BY RNEMOID DESC) AS [RnEMoID],
					[RecordTranSetID],
					RecordSettDate
				INTO
					#PostingId
				FROM 
					[Posting].[RNEPostingExtract] PE
				WHERE 
					RecordSettDate = (SELECT BusinessDate FROM Config.ProcessingDate)
				AND 
					RecordTranSetID IS NOT NULL 
				AND 
					RecordSourceMsg = 'MSG13'

				CREATE NONCLUSTERED INDEX nci_RTSID_RSTD ON #PostingId(RecordTranSetID, RecordSettDate)

				UPDATE 
					PE
				SET	
					PE.IsAggregated			=	BT.IsAggregated,
					PE.IsAllItemsTriggered	=	BT.IsAllItemsTriggered,
					PE.ExtractRecord		=	IIF((ISNULL(BT.IsAggregated,0)=1 AND ISNULL(BT.IsAllItemsTriggered,0)=1),1,0),
					PE.PostingId			=	IIF((ISNULL(BT.IsAggregated,0)=1 AND ISNULL(BT.IsAllItemsTriggered,0)=1),tmp.PostingId,PE.PostingId),
					PE.RnEMoID				=	IIF((ISNULL(BT.IsAggregated,0)=1 AND ISNULL(BT.IsAllItemsTriggered,0)=1),tmp.RnEMoID,PE.RnEMoID)
				FROM 
					[Posting].[RNEPostingExtract] PE
				INNER JOIN 
					[Posting].[vw_BeneficiaryPostingType] BT
				ON 
					BT.EntityId=PE.EntityId
				AND 
					BT.PostingType=PE.RecordPostType
				INNER JOIN 
					Config.PostingTypeSetting PS
				ON 
					PS.PostingType=BT.PostingType
				AND 
					AggregatedPosting = 1
				INNER JOIN 
					#PostingId tmp
				ON 
					PE.RecordTranSetID = tmp.RecordTranSetID
				AND 
					PE.RecordSettDate = tmp.RecordSettDate
				WHERE 
					BT.IsAggregated = 1 
				OR 
					BT.IsAllItemsTriggered = 1 ;

				-- Updating the EntityId with the Latest id received from Archive even for the Old items recevied as part of Aggregation
				UPDATE 
					AG
				SET 
					AG.EntityID = PE.EntityID
				FROM 
					[Posting].[AggregatedItemsData] AG 
				INNER JOIN 
					Staging.PostingEntity PE
				ON 
					AG.DebitTransID = PE.EntityIdentifier;


				--Update the Waiting State of CNP Records if all Tset Arrived
				UPDATE 
					PE
				SET 
					PE.IsWaitingState = 0,
					PE.PostingID = @PostingID,
					PE.RneMoID = @RneMoID,
					PE.ExtractRecord = 1
				FROM  
					Posting.RNEPostingExtract PE 
				INNER JOIN 
					(
						SELECT  
								TransactionSetId 
						FROM	
							Posting.BeneficiaryPostingType BP
						WHERE	
							BP.PostingID = @PostingID 
						AND 
							BP.IsAllItemsTriggered = 1
						AND 
							DebitEntityState IN (260,261,262,263,280) 
						GROUP BY 
							TransactionSetId
					) BP
				ON		
					PE.RecordTranSetID = BP.TransactionSetId
				WHERE 
					PE.IsWaitingState = 1;

				-- Updating the EntityId with the Latest id received from Archive even for the Old items recevied as part of Aggregation
				UPDATE
					PS
				SET 
					PS.EntityID = PE.EntityID
				FROM 
					[Posting].[RNEPostingExtract] PS 
				INNER JOIN 
					Staging.PostingEntity PE
				ON 
					PS.ItemIdentifier = PE.EntityIdentifier 
				AND 
					PS.PostingID = @PostingID;

				MERGE 
					[Posting].[AggregatedItemsData] ER
				USING 
					(                       
						SELECT 
							[RnEMoID]
							,[PostingID]
							,[HeaderSchema]
							,[HeaderParticipant]
							,[HeaderProcDate]
							,[HeaderSequence]
							,[HeaderVersion]
							,[HeaderFileDate]
							,[HeaderWeekDay]
							,[HeaderType]
							,[HeaderCurrency]
							,[HeaderEnvironment]
							,[EntityIdentifier]
							,[PostingIdentifier]
							,[ItemIdentifier]
							,[EntityId]
							,[SourceDateTime]
							,[RecordSequence]
							,[RecordPostType]
							,[RecordSubType]
							,[RecordSourceMsg]
							,[RecordChannel]
							,[RecordEntryType]
							,[RecordPostSource]
							,[RecordRespSource]
							,[RecordPostDay]
							,[RecordClearDate]
							,[RecordSettDate]
							,[RecordCaptDate]
							,[RecordAmount]
							,[RecordTranSetID]
							,[RecordReason]
							,[RecordOverride]
							,[RecordNPASort]
							,[RecordNPAAcc]
							,[RecordSuppInfo]
							,[RecordNumCheques]
							,[RecordCollPart]
							,[RecordCollLoc]
							,[DebitTransID]
							,[DebitSortCode]
							,[DebitAccNum]
							,[DebitSerNum]
							,[DebitTranCode]
							,[DebitSwitchSort]
							,[DebitSwitchAcc]
							,[DebitFullAmt]
							,[CreditTransID]
							,[CreditSortCode]
							,[CreditAccNum]
							,[CreditRef]
							,[CreditTransCode]
							,[CreditOrigAmt]
							,[CreditOrigSort]
							,[CreditOrigAcc]
							,[CreditExcepCode]
							,[CreditBeneficiary]
							,[DetailDefSort]
							,[DetailDefAcc]
							,[DetailRepresent]
							,[DetailFrontQual]
							,[DetailRearQual]
							,[DetailChannelRisk]
							,[DetailFraudCode]
							,[DetailFraudReason]
							,[DetailFraudNameCheck]
							,[DetailDuplicate]
							,[DetailDupId]
							,[DetailDupStatus]
							,[DetailDupSeen]
							,[DetailDupCollect]
							,[DetailDupCapture]
							,[DetailDupSource]
							,[DetailStopped]
							,[DetailStopDate]
							,[DetailStopStatus]
							,[DetailStopAmt]
							,[DetailStopName]
							,[DetailStopStart]
							,[DetailStopEnd]
							,[DetailRepSort]
							,[DetailRepAcc]
							,[DetailRepAmt]
							,[DetailRepSer]
							,[DetailException]
							,[TrailerTransCount]
							,[ItemPartitionSeq]
							,[ExtractRecord]
							FROM [Posting].[RNEPostingExtract]
							WHERE RecordPostType !='NIL'
							AND ISNULL( IsAggregated,0)=1 
							AND ISNULL( IsAllItemsTriggered,0)=1
					) Ext 
				ON 
					Ext.[ItemIdentifier] = ER.[ItemIdentifier]
				AND 
					Ext.[RecordPostType] = ER.[RecordPostType]				
				WHEN MATCHED AND (ER.[RecordSettDate] != Ext.[RecordSettDate]) THEN 
					UPDATE 
					SET 
						ER.[RNEMOID] = Ext.[RnEMoID]
						,ER.[PostingID] = Ext.[PostingID]
						,ER.[HeaderSchema] = Ext.[HeaderSchema] 
						,ER.[HeaderParticipant] =Ext.HeaderParticipant
						,ER.[HeaderProcDate] = Ext.HeaderProcDate
						,ER.[HeaderSequence] =Ext.HeaderSequence
						,ER.[HeaderVersion] =Ext.HeaderVersion
						,ER.[HeaderFileDate] =Ext.HeaderFileDate
						,ER.[HeaderWeekDay] = Ext.HeaderWeekDay
						,ER.[HeaderType] =Ext .HeaderType
						,ER.[HeaderCurrency] = Ext.HeaderCurrency
						,ER.[HeaderEnvironment] = Ext.HeaderEnvironment
						,ER.[EntityIdentifier] = Ext.EntityIdentifier
						,ER.[PostingIdentifier] = Ext.PostingIdentifier
						,ER.[ItemIdentifier] = Ext.ItemIdentifier
						,ER.[EntityId] = Ext.EntityId
						,ER.[SourceDateTime] = Ext.SourceDateTime
						,ER.[RecordSequence] = Ext.RecordSequence
						,ER.[RecordPostType] =Ext.RecordPostType
						,ER.[RecordSubType] = Ext.RecordSubType
						,ER.[RecordSourceMsg] = Ext.RecordSourceMsg
						,ER.[RecordChannel] = Ext.RecordChannel
						,ER.[RecordEntryType] =Ext.RecordEntryType
						,ER.[RecordPostSource] = Ext.RecordPostSource
						,ER.[RecordRespSource] =Ext.RecordRespSource
						,ER.[RecordPostDay] =Ext.RecordPostDay
						,ER.[RecordClearDate] =Ext.RecordClearDate
						,ER.[RecordSettDate] = Ext.RecordSettDate
						,ER.[RecordCaptDate] =Ext.RecordCaptDate
						,ER.[RecordAmount] =Ext.RecordAmount
						,ER.[RecordTranSetID] =Ext.RecordTranSetID
						,ER.[RecordReason] = Ext.RecordReason
						,ER.[RecordOverride] =Ext.RecordOverride
						,ER.[RecordNPASort] =Ext.RecordNPASort
						,ER.[RecordNPAAcc] =Ext.RecordNPAAcc
						,ER.[RecordSuppInfo] = Ext.RecordSuppInfo
						,ER.[RecordNumCheques] = Ext.RecordNumCheques
						,ER.[RecordCollPart] =Ext.RecordCollPart
						,ER.[RecordCollLoc] =Ext.RecordCollLoc
						,ER.[DebitTransID] =Ext.DebitTransID
						,ER.[DebitSortCode] =Ext.DebitSortCode
						,ER.[DebitAccNum] = Ext.DebitAccNum
						,ER.[DebitSerNum] =Ext.DebitSerNum
						,ER.[DebitTranCode] =Ext.DebitTranCode
						,ER.[DebitSwitchSort] = Ext.DebitSwitchSort
						,ER.[DebitSwitchAcc] =Ext.DebitSwitchAcc
						,ER.[DebitFullAmt] =Ext. DebitFullAmt
						,ER.[CreditTransID] =Ext. CreditTransID
						,ER.[CreditSortCode] = Ext.CreditSortCode
						,ER.[CreditAccNum] =Ext. CreditAccNum
						,ER.[CreditRef] =Ext. CreditRef
						,ER.[CreditTransCode] = Ext.CreditTransCode
						,ER.[CreditOrigAmt] =Ext. CreditOrigAmt
						,ER.[CreditOrigSort] = Ext.CreditOrigSort
						,ER.[CreditOrigAcc] =Ext. CreditOrigAcc
						,ER.[CreditExcepCode] = Ext.CreditExcepCode
						,ER.[CreditBeneficiary] =Ext. CreditBeneficiary
						,ER.[DetailDefSort] =Ext. DetailDefSort
						,ER.[DetailDefAcc] = Ext.DetailDefAcc
						,ER.[DetailRepresent] = Ext.DetailRepresent
						,ER.[DetailFrontQual] = Ext.DetailFrontQual
						,ER.[DetailRearQual] = Ext.DetailRearQual
						,ER.[DetailChannelRisk] =Ext. DetailChannelRisk
						,ER.[DetailFraudCode] = Ext.DetailFraudCode
						,ER.[DetailFraudReason] = Ext.DetailFraudReason
						,ER.[DetailFraudNameCheck] = Ext.DetailFraudNameCheck
						,ER.[DetailDuplicate] =Ext. DetailDuplicate
						,ER.[DetailDupId] = Ext.DetailDupId
						,ER.[DetailDupStatus] =Ext. DetailDupStatus
						,ER.[DetailDupSeen] =Ext. DetailDupSeen
						,ER.[DetailDupCollect] =Ext. DetailDupCollect
						,ER.[DetailDupCapture] =Ext. DetailDupCapture
						,ER.[DetailDupSource] = Ext.DetailDupSource
						,ER.[DetailStopped] = Ext.DetailStopped
						,ER.[DetailStopDate] =Ext. DetailStopDate
						,ER.[DetailStopStatus] = Ext.DetailStopStatus
						,ER.[DetailStopAmt] =Ext. DetailStopAmt
						,ER.[DetailStopName] =Ext. DetailStopName
						,ER.[DetailStopStart] =Ext. DetailStopStart
						,ER.[DetailStopEnd] =Ext. DetailStopEnd
						,ER.[DetailRepSort] =Ext. DetailRepSort
						,ER.[DetailRepAcc] =Ext. DetailRepAcc
						,ER.[DetailRepAmt] = Ext.DetailRepAmt
						,ER.[DetailRepSer] = Ext.DetailRepSer
						,ER.[DetailException] =Ext. DetailException
						,ER.[TrailerTransCount] = Ext.TrailerTransCount
						,ER.[ItemPartitionSeq] =Ext. ItemPartitionSeq
						,ER.[ExtractRecord] = Ext.ExtractRecord
					WHEN NOT MATCHED BY TARGET THEN
					INSERT 
						(
							[RNEMOID],[PostingID],[HeaderSchema],[HeaderParticipant],[HeaderProcDate],[HeaderSequence],[HeaderVersion],[HeaderFileDate],[HeaderWeekDay]
							,[HeaderType],[HeaderCurrency],[HeaderEnvironment],[EntityIdentifier],[PostingIdentifier],[ItemIdentifier],[EntityId],[SourceDateTime] ,[RecordSequence]
							,[RecordPostType],[RecordSubType],[RecordSourceMsg],[RecordChannel],[RecordEntryType],[RecordPostSource],[RecordRespSource],[RecordPostDay],[RecordClearDate]
							,[RecordSettDate],[RecordCaptDate],[RecordAmount],[RecordTranSetID],[RecordReason],[RecordOverride],[RecordNPASort],[RecordNPAAcc],[RecordSuppInfo]
							,[RecordNumCheques],[RecordCollPart],[RecordCollLoc],[DebitTransID],[DebitSortCode],[DebitAccNum],[DebitSerNum],[DebitTranCode],[DebitSwitchSort]
							,[DebitSwitchAcc],[DebitFullAmt],[CreditTransID],[CreditSortCode],[CreditAccNum],[CreditRef],[CreditTransCode],[CreditOrigAmt],[CreditOrigSort]
							,[CreditOrigAcc],[CreditExcepCode],[CreditBeneficiary],[DetailDefSort],[DetailDefAcc],[DetailRepresent],[DetailFrontQual],[DetailRearQual],[DetailChannelRisk]
							,[DetailFraudCode],[DetailFraudReason],[DetailFraudNameCheck],[DetailDuplicate],[DetailDupId],[DetailDupStatus],[DetailDupSeen],[DetailDupCollect]
							,[DetailDupCapture],[DetailDupSource],[DetailStopped],[DetailStopDate],[DetailStopStatus],[DetailStopAmt],[DetailStopName],[DetailStopStart],[DetailStopEnd]
							,[DetailRepSort],[DetailRepAcc],[DetailRepAmt],[DetailRepSer],[DetailException],[TrailerTransCount],[ItemPartitionSeq],[ExtractRecord]
						)
					VALUES
						(
							Ext.[RnEMoID],Ext.[PostingID],Ext.[HeaderSchema],Ext.[HeaderParticipant],Ext.[HeaderProcDate],Ext.[HeaderSequence],Ext.[HeaderVersion],Ext.[HeaderFileDate],Ext.[HeaderWeekDay]
							,Ext.[HeaderType],Ext.[HeaderCurrency],Ext.[HeaderEnvironment],Ext.[EntityIdentifier],Ext.[PostingIdentifier],Ext.[ItemIdentifier],Ext.[EntityId],Ext.[SourceDateTime] ,Ext.[RecordSequence]
							,Ext.[RecordPostType],Ext.[RecordSubType],Ext.[RecordSourceMsg],Ext.[RecordChannel],Ext.[RecordEntryType],Ext.[RecordPostSource],Ext.[RecordRespSource],Ext.[RecordPostDay],Ext.[RecordClearDate]
							,Ext.[RecordSettDate],Ext.[RecordCaptDate],Ext.[RecordAmount],Ext.[RecordTranSetID],Ext.[RecordReason],Ext.[RecordOverride],Ext.[RecordNPASort],Ext.[RecordNPAAcc],Ext.[RecordSuppInfo]
							,Ext.[RecordNumCheques],Ext.[RecordCollPart],Ext.[RecordCollLoc],Ext.[DebitTransID],Ext.[DebitSortCode],Ext.[DebitAccNum],Ext.[DebitSerNum],Ext.[DebitTranCode],Ext.[DebitSwitchSort]
							,Ext.[DebitSwitchAcc],Ext.[DebitFullAmt],Ext.[CreditTransID],Ext.[CreditSortCode],Ext.[CreditAccNum],Ext.[CreditRef],Ext.[CreditTransCode],Ext.[CreditOrigAmt],Ext.[CreditOrigSort]
							,Ext.[CreditOrigAcc],Ext.[CreditExcepCode],Ext.[CreditBeneficiary],Ext.[DetailDefSort],Ext.[DetailDefAcc],Ext.[DetailRepresent],Ext.[DetailFrontQual],Ext.[DetailRearQual],Ext.[DetailChannelRisk]
							,Ext.[DetailFraudCode],Ext.[DetailFraudReason],Ext.[DetailFraudNameCheck],Ext.[DetailDuplicate],Ext.[DetailDupId],Ext.[DetailDupStatus],Ext.[DetailDupSeen],Ext.[DetailDupCollect]
							,Ext.[DetailDupCapture],Ext.[DetailDupSource],Ext.[DetailStopped],Ext.[DetailStopDate],Ext.[DetailStopStatus],Ext.[DetailStopAmt],Ext.[DetailStopName],Ext.[DetailStopStart],Ext.[DetailStopEnd]
							,Ext.[DetailRepSort],Ext.[DetailRepAcc],Ext.[DetailRepAmt],Ext.[DetailRepSer],Ext.[DetailException],Ext.[TrailerTransCount],Ext.[ItemPartitionSeq],Ext.[ExtractRecord]
					   );
			END			   			
        END;
    END TRY
    BEGIN CATCH
            DECLARE @Number INT = ERROR_NUMBER();  
            DECLARE @Message VARCHAR(4000) = ERROR_MESSAGE();  
            DECLARE @UserName NVARCHAR(128) = CONVERT(SYSNAME, ORIGINAL_LOGIN());  
            DECLARE @Severity INT = ERROR_SEVERITY();  
            DECLARE @State INT = ERROR_STATE();  
            DECLARE @Type VARCHAR(128) = 'Stored Procedure';  
            DECLARE @Line INT = ERROR_LINE();  
            DECLARE @Source VARCHAR(128) = ERROR_PROCEDURE();  
            EXEC [Base].[usp_LogException] @Number, @Message, @UserName,
                @Severity, @State, @Type, @Line, @Source;  
            THROW
    END CATCH;
GO

GRANT EXECUTE ON [Posting].[usp_GetAggregatedItemsData] TO [RNESVCAccess];

GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)', @level0type = N'SCHEMA', @level0name = N'Posting', @level1type = N'PROCEDURE', @level1name = N'usp_GetAggregatedItemsData';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Loads Aggregation items to Aggregation table for validation', @level0type = N'SCHEMA', @level0name = N'Posting', @level1type = N'PROCEDURE', @level1name = N'usp_GetAggregatedItemsData';


GO
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'iPSL.ICE.RNE.Database', @level0type = N'SCHEMA', @level0name = N'Posting', @level1type = N'PROCEDURE', @level1name = N'usp_GetAggregatedItemsData';
