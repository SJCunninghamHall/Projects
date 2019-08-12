CREATE PROCEDURE [Base].[usp_Process_TransitionItems_NewWithoutTemp_native]
	@tvp_ItemUpdateInfo		[Base].[ICNItemUpdateHolder] READONLY,
	@tvp_TxSet				[Base].[tv_TxSet] READONLY,
 	@tvp_FinalCredits		[Base].[tv_FinalCredit] READONLY,
	@tvp_FinalDebits		[Base].[tv_FinalDebit] READONLY,
    @tvp_CreditsFromXML		[Base].[tv_Credit_New] READONLY,
    @tvp_DebitsFromXML 		[Base].[tv_Debit_New] READONLY, 
	@tvp_CaptureItem		[Base].[tv_Capture_History_Item] READONLY,
	@tvp_FraudInfo			[Base].[tv_FraudInfo] READONLY,
	@tvp_ICNEntityHolder	[Base].[ICNEntity_New] READONLY,	
	@tvp_CreditFraudData	[Base].[tv_CreditFraudData] READONLY,
	@CoreId					BIGINT,
	@ExtractId				VARCHAR(26),
    @MessageType			VARCHAR(6),
	@IntMessageType			VARCHAR(6),	
	@BusinessDate			DATE,
	@TransitionItemsSKID  BIGINT
	

/*********************************************************************************************************************************************************************
* Name				: [Base].[usp_Process_TransitionItems]
* Description		: This stored procedure builds the data to be inserted into flat table.
* Type of Procedure : Interpreted stored procedure
* Author			: Alpa Buddhabhatti
* Creation Date		: 14/07/2019
* Last Modified		: N/A
* Parameters		: 15
**********************************************************************************************************************************************************************
*Parameter Name				Type									Description
*---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 @tvp_ItemUpdateInfo		[Base].[ICNItemUpdateHolder]			Contains updated item information
 @tvp_TxSet					[Base].[tv_TxSet]						Contains calculated tset data
 @tvp_FinalCredits			[Base].[tv_FinalCredit]					Contains calculated credit items 
 @tvp_FinalDebits			[Base].[tv_FinalDebit]					Contains calculated debit items
 @tvp_CreditsFromXML		[Base].[tv_Credit]						Contains credit data to load into TransitionItems
 @tvp_DebitsFromXML			[Base].[tv_Debit]						Contains debit data to load into TransitionItems
 @TVPCaptureItem			[Base].[tv_Capture_History_Item]		Contains capture items inforamtion
 @tvp_FraudInfo				[Base].[tv_FraudInfo]					Contains Fraud Information
 @tvp_ICNEntityHolder		[Base].[ICNEntityAuditUpdateHolder]		Entire list of ItemUpdates
 @tvp_CreditFraudData		[Base].[tv_CreditFraudData]				Credit Fraud information
 @tvp_DuplicateDebit		[Base].[tv_DuplicateDebit]				Duplicate Debit details
 @tvp_StoppedItem			[Base].[tv_StoppedItem]					Stopped Item details
 @CoreId					BIGINT									CoreID
 @ExtractId					VARCHAR(26)								ExtractId
 @MessageType				VARCHAR(6)								MessageType
 @IntMessageType			VARCHAR(6)								IntMessageType
 @BusinessDate				DATE									BusinessDate
**********************************************************************************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
**********************************************************************************************************************************************************************
*										History
*---------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Version	ID		Date			Modified By			Reason
**********************************************************************************************************************************************************************
* 1.0.0		001		23/07/2018		Alpa				Initial version */
AS
    BEGIN

        SET NOCOUNT ON;   
		
        BEGIN TRY

			DECLARE @ResetValues BIT = 0
						IF (@IntMessageType='01MA01')
			                         SET  @ResetValues= 1

  -- converted ~temp tbale to UDT
  Declare @tv_TransitionItems Base.tv_TransitionItems_native 
			
			-- Insert into temp table TransitionItems for ICNEntityHolder 			
			INSERT INTO @tv_TransitionItems
			   ([TransitionItemsSKID]
			   ,[ExtractId]
			   ,[UniqueItemIdentifier]
			   ,[EntityState]
			   ,[MessageType]
			   ,[IntMessageType]
			   ,[StateRevision]
			   ,[CoreID]
			   ,[SwitchRejectionCode])
			(SELECT 
			    @TransitionItemsSKID
				--CAST(CONCAT(CONVERT(VARCHAR(8), @BusinessDate, 112), REPLICATE('0', 11)) AS BIGINT) + NEXT VALUE FOR [Base].[sqn_MsgID] AS TransitionItemsSKID
				,@ExtractId
				,[EntityInfoTable].[EntityIdentifier]
				,[EntityInfoTable].[EntityState]
				,@MessageType 
				,@IntMessageType
				,[EntityInfoTable].[Revision]
				,@CoreId
				,[EntityInfoTable].[ErrorCode]
			FROM
			@tvp_ICNEntityHolder EntityInfoTable	
			WHERE EntityInfoTable.EntityType = 'I')

			-- Update temp table TransitionItems for Credits, FinalCredits and CreditFraudData
			UPDATE TI
			SET
				[Gender]							=	'Cr',
				[TransactionSetId]					=	[FinalCredits].[TransactionSetId],
				[TransactionSetIdWithVersion]		=	[FinalCredits].[TSetIDWithVersion],
				[ItemType]							=	[FinalCredits].[ItemType],
				[OnUs]								=	[FinalCredits].[OnUs],
				[Sortcode]							=	[FinalCredits].[Sortcode],
				[AccountNumber]						=	[FinalCredits].[AccountNumber],
				[SerialReference]					=	[FinalCredits].[Reference],
				[Amount]							=	[FinalCredits].[Amount],
				[Currency]							=	[FinalCredits].[Currency],
				[TranCode]							=	[FinalCredits].[TranCode],
				[AlternateSortCode]					=	[FinalCredits].[AlternateSortCode],
				[AlternateAccount]					=	[FinalCredits].[AlternateAccount],
				[SwitchedSortCode]					=	[FinalCredits].[SwitchedSortCode],
				[SwitchedAccount]					=	[FinalCredits].[SwitchedAccount],
				[IsSortCodeDefaulted]				=	[FinalCredits].[DefaultedSortcode],
				[ISAccountNumberDefaulted]			=	[FinalCredits].[DefaultedAccount],
				[ISSerialReferenceDefaulted]		=	[ShreddedCredits].[DefaultedReference],
				[IsSortCodeRepaired]				=	[FinalCredits].[RepairedSortcode],
				[ISAccountNumberRepaired]			=	[FinalCredits].[RepairedAccount],
				[IsAmountRepaired]					=	[FinalCredits].[RepairedAmount],
				[ISSerialReferenceRepaired]			=	[FinalCredits].[RepairedReference],
				[NoPayReason]						=	[FinalCredits].[NoPayReason],
				[PayReason]							=	[FinalCredits].[ReasonCode],
				[Narrative]							=	[FinalCredits].[Narrative],
				[CollectingParticipantId]			=	[FinalCredits].[CollectingParticipantId],
				[ChargingParticipantId]				=	ISNULL((SELECT ChargedParticipantId FROM [Base].[Document] WHERE DocumentId = (SELECT TOP 1 DocumentId FROM [Base].[TXSet] T WHERE T.TransactionSetIdWithVersion = [FinalCredits].[TSetIDWithVersion] ORDER BY T.InternalTXId ASC)), [FinalCredits].[ChargingParticipantId]),
				[AgencyPayingParticipantId]			=	[FinalCredits].[AgencyPayingParticipantId],
				[AgencyBeneficiaryParticipantId]	=	[FinalCredits].[AgencyBeneficiaryParticipantId],
				[EISCDBeneficiaryParticipantId]		=	[FinalCredits].[EISCDBeneficiaryParticipantId],
				[SettlementParticipantId]			=	[FinalCredits].[SettlementParticipantId],
				[ItemUpdateId]						=	[FinalCredits].[ItemUpdateId],
				[CaptureItemId]						=	[FinalCredits].[CaptureItemId],
				[EntityId]							=	[FinalCredits].[EntityId],
				[BeneficiaryName]					=	[CreditFraudData].[BeneficiaryName]
			FROM @tv_TransitionItems TI
			INNER JOIN 
			@tvp_FinalCredits FinalCredits
			ON TI.UniqueItemIdentifier = FinalCredits.CreditId
			LEFT JOIN 
			@tvp_CreditsFromXML ShreddedCredits
			ON ShreddedCredits.CreditId = TI.UniqueItemIdentifier
			LEFT JOIN 			
			@tvp_CreditFraudData CreditFraudData
			ON CreditFraudData.ItemId = FinalCredits.ItemId

			-- Update temp table TransitionItems for Debits and FinalDebits
			UPDATE TI
			SET
				[Gender]							=	'Db',
				[TransactionSetId]					=	[FinalDebits].[TransactionSetId],
				[TransactionSetIdWithVersion]		=	[FinalDebits].[TSetIDWithVersion],
				[ItemType]							=	[FinalDebits].[ItemType],
				[OnUs]								=	[FinalDebits].[OnUs],
				[HighValue]							=	[ShreddedDebits].[HighValue],
				[Sortcode]							=	[FinalDebits].[Sortcode], 
				[AccountNumber]						=	[FinalDebits].[AccountNumber],
				[SerialReference]					=	[FinalDebits].[Serial],
				[Amount]							=	[FinalDebits].[Amount],
				[Currency]							=	[FinalDebits].[Currency],
				[TranCode]							=	[FinalDebits].[TranCode],
				[AlternateSortCode]					=	[FinalDebits].[AlternateSortCode],
				[AlternateAccount]					=	[FinalDebits].[AlternateAccount],
				[SwitchedSortCode]					=	[FinalDebits].[SwitchedSortCode],
				[SwitchedAccount]					=	[FinalDebits].[SwitchedAccount],
				[RepresentFlag]						=	[FinalDebits].[Represent],
				[IsSortCodeDefaulted]				=	[FinalDebits].[DefaultedSortcode],
				[ISAccountNumberDefaulted]			=	[FinalDebits].[DefaultedAccount],
				[ISSerialReferenceDefaulted]		=	[ShreddedDebits].[DefaultedSerialNumber],
				[IsSortCodeRepaired]				=	[FinalDebits].[RepairedSortcode],
				[ISAccountNumberRepaired]			=	[FinalDebits].[RepairedAccount],
				[IsAmountRepaired]					=	[FinalDebits].[RepairedAmount],
				[ISSerialReferenceRepaired]			=	[FinalDebits].[RepairedReference],
				[NoPayReason]						=	[FinalDebits].[NoPayReason],
				[PayDecision]						=	[FinalDebits].[PayDecision],
				[PayReason]							=	[FinalDebits].[PayReason],
				[Narrative]							=	[FinalDebits].[Narrative],
				[Day1ResponseStartDateTime]			=	[ShreddedDebits].[Day1ResponseStartDateTime],
				[Day1ResponseEndDateTime]			=	[ShreddedDebits].[Day1ResponseEndDateTime],
				[Day2ResponseWindowStartDateTime]	=	ISNULL([ShreddedDebits].[Day2ResponseStartDatetime], [FinalDebits].[ResponseDate]),
				[Day2ResponseWindowEndDateTime]		=	ISNULL([ShreddedDebits].[Day2ResponseEndDateTime], [FinalDebits].[ResponseTime]), 
				[SettlementPeriodId]				=	[FinalDebits].[SettlementPeriodId],
				[CollectingParticipantId]			=	[FinalDebits].[CollectingParticipantId],
				[FrontImageQuality]					=	[ShreddedDebits].[FrontImageQuality],
				[RearImageQuality]					=	[ShreddedDebits].[RearImageQuality],
				[ChargingParticipantId]				=	ISNULL((SELECT ChargedParticipantId FROM [Base].[Document] WHERE DocumentId = (SELECT TOP 1 DocumentId FROM [Base].[TXSet] T WHERE T.TransactionSetIdWithVersion = [FinalDebits].[TSetIDWithVersion] ORDER BY T.InternalTXId ASC)), [FinalDebits].[ChargingParticipantId]),
				[AgencyPayingParticipantId]			=	[FinalDebits].[AgencyPayingParticipantId],
				[AgencyBeneficiaryParticipantId]	=	[FinalDebits].[AgencyBeneficiaryParticipantId],
				[EISCDPayingParticipantId]			=	[FinalDebits].[EISCDPayingParticipantId],
				[EISCDBeneficiaryParticipantId]		=	[FinalDebits].[EISCDBeneficiaryParticipantId],
				[SettlementParticipantId]			=	[FinalDebits].[SettlementParticipantId],
				[ItemUpdateId]						=	[FinalDebits].[ItemUpdateId],
				[CaptureItemId]						=	[FinalDebits].[CaptureItemId],
				[EntityId]							=	[FinalDebits].[EntityId],
				[DuplicateItemId]					=	[ShreddedDebits].[DuplicateItemId],			
				[DuplicateItemStatus]				=	[ShreddedDebits].[DuplicateStatus],				
				[DuplicateItemDateFirstSeen]		=	[ShreddedDebits].[DateFirstSeen],
				[DuplicateItemOriginalCollectingParticipant] = [ShreddedDebits].[OriginalCollectingParticipant],
				[DuplicateItemOriginalCaptureDate]	=	[ShreddedDebits].[OriginalCaptureDate],
				[DuplicateItemOriginalSource]		=	[ShreddedDebits].[OriginalSource],
				[StoppedItemId]						=	NULL,
				[StoppedItemStoppedDate]			=	[ShreddedDebits].[StopDate],		
				[StoppedItemStatus]					=	[ShreddedDebits].[StopStatus],		
				[StoppedItemAmount]					=	[ShreddedDebits].[StopAmount],		
				[StoppedItemBeneficiary]			=	[ShreddedDebits].[StopBeneficiary],		
				[StoppedItemStopItemStartRange]		=	[ShreddedDebits].[StopStartRange],		
				[StoppedItemStopItemEndRange]		=	[ShreddedDebits].[StopEndRange]
			FROM @tv_TransitionItems TI
			INNER JOIN
			@tvp_FinalDebits FinalDebits
			ON TI.UniqueItemIdentifier = FinalDebits.DebitId
			LEFT JOIN 
			@tvp_DebitsFromXML ShreddedDebits
			ON ShreddedDebits.DebitId = TI.UniqueItemIdentifier
			
			-- Update temp table TransitionItems for ICNItemUpdate, CaptureItem, FraudInfo and TxSet
			UPDATE TI
			SET
				[IsElectronic]						=	[CaptureItemTable].[IsElectronic],
				[cf_OnBank]							=	[CaptureItemTable].[cf_OnBank],
				[cf_DeferredPosting]				=	[CaptureItemTable].[cf_DeferredPosting], 
				[cf_NPASortCode]					=	[CaptureItemTable].[cf_NPASortCode],
				[cf_ChnlInsertReason]				=	[CaptureItemTable].[cf_ChnlInsertReason],
				[cf_NoPaySuspectRsn]				=	[CaptureItemTable].[cf_NoPaySuspectRsn],
				[cf_fCashItem]						=	[CaptureItemTable].[cf_fCashItem],
				[Amount]							=	ISNULL([UpdatedItemInfo].[Amount],[TI].[Amount]),
				[OriginalAmount]					=	[CaptureItemTable].[OriginalAmount],
				[ICSAmount]							=	ISNULL([UpdatedItemInfo].[ICSAmount],[CaptureItemTable].[ICSAmount]),
				[Day2ResponseWindowStartDateTime]	=	ISNULL([UpdatedItemInfo].[ResponseDate], [TI].[Day2ResponseWindowStartDateTime]),
				[Day2ResponseWindowEndDateTime]		=	ISNULL([UpdatedItemInfo].[ResponseTime], [TI].[Day2ResponseWindowEndDateTime]), 
				[JGAccount]							=	[CaptureItemTable].[JGAccount],
				[IsTCCorrected]						=	[CaptureItemTable].[IsTCCorrected],
				[IsANCorrected]						=	[CaptureItemTable].[IsANCorrected],
				[IsSortCodeCorrected]				=	[CaptureItemTable].[IsSortCodeCorrected],
				[IsSerialCorrected]					=	[CaptureItemTable].[IsSerialCorrected],
				[IsReject]							=	[CaptureItemTable].[IsReject],
				[AdjustmentReason]					=	[CaptureItemTable].[AdjustmentReason],
				[FraudCheckResult]					=	[FraudInfo].[FraudCheckResult],
				[FraudCheckReason]					=	[FraudInfo].[FraudCheckReason],
				[AuditRevision]						=	[CaptureItemTable].[AuditRevision],
				[TSetSource]						=	[TSetInformation].[AltSource],
				[TSetCaptureDate]					=	[TSetInformation].[CaptureDate],
				[TSetCollectingLocation]			=	[TSetInformation].[CollectingLocation],
				[TSetSubmissionDateTime]			=	[TSetInformation].[TSetSubmissionDateTime],
				[NoPayReason]						=	ISNULL([UpdatedItemInfo].[NoPayReason],[TI].[NoPayReason]),
				[Narrative]							=	ISNULL([UpdatedItemInfo].[Narrative],[TI].[Narrative]),
				[AlternateSortCode]					=	ISNULL([UpdatedItemInfo].[AlternateSortCode],[TI].[AlternateSortCode]),
				[AlternateAccount]					=	ISNULL([UpdatedItemInfo].[AlternateAccount],[TI].[AlternateAccount]),
				[PayDecision]						=	ISNULL([UpdatedItemInfo].[PayDecision],[TI].[PayDecision]),
				[PayReason]							=	ISNULL([UpdatedItemInfo].[PayReason],[TI].[PayReason]),
				[SettlementPeriodId]				=	ISNULL([UpdatedItemInfo].[SettlementPeriodId],[TI].[SettlementPeriodId]),
				[SwitchedSortCode]					=	ISNULL([UpdatedItemInfo].[SwSortCode],[TI].[SwitchedSortCode]),
				[SwitchedAccount]					=	ISNULL([UpdatedItemInfo].[SwAccountNumber],[TI].[SwitchedAccount]),
				[ChannelRiskType]					=	[TSetInformation].[ChannelRiskType],
				[DebitReference]					=	[CaptureItemTable].[DebitReference],
				[IsAmountCorrected]					=	[CaptureItemTable].[IsAmountCorrected],
				[cf_ImageDateTime]					=	[CaptureItemTable].[cf_ImageDateTime]
			FROM
			@tv_TransitionItems TI
			LEFT JOIN 
			@tvp_ItemUpdateInfo UpdatedItemInfo
			ON TI.UniqueItemIdentifier = UpdatedItemInfo.CrDbTransactionItemId
			LEFT JOIN 
			@tvp_CaptureItem CaptureItemTable
			ON TI.UniqueItemIdentifier =  CaptureItemTable.FCMIdentifier
			LEFT JOIN 
			@tvp_FraudInfo FraudInfo
			ON FraudInfo.ItemId = TI.UniqueItemIdentifier
			LEFT JOIN 
			@tvp_TxSet TSetInformation
			ON TSetInformation.TransactionSetIdWithVersion = TI.TransactionSetIdWithVersion
			
			-- For given uniqueitemidentifier take latest revision from TransitionItems table and join with
			-- temp table TransitionItems and fill the null data
			UPDATE TVTI
			SET TVTI.[TransitionItemsSKID] = ISNULL(TVTI.[TransitionItemsSKID], TI.[TransitionItemsSKID]),
				TVTI.[ExtractId] = ISNULL(TVTI.[ExtractId], TI.[ExtractId]),
			    TVTI.[UniqueItemIdentifier] = ISNULL(TVTI.[UniqueItemIdentifier], TI.[UniqueItemIdentifier]),
			    TVTI.[Gender] = ISNULL(TVTI.[Gender], TI.[Gender]),
			    TVTI.[EntityState] = ISNULL(TVTI.[EntityState], TI.[EntityState]),
			    TVTI.[TransactionSetId] = ISNULL(TVTI.[TransactionSetId], TI.[TransactionSetId]),
			    TVTI.[TransactionSetIdWithVersion] = ISNULL(TVTI.[TransactionSetIdWithVersion], TI.[TransactionSetIdWithVersion]),
			    TVTI.[TsetEntityState] = ISNULL(TVTI.[TsetEntityState], TI.[TsetEntityState]),
			    TVTI.[IsElectronic] = ISNULL(TVTI.[IsElectronic], TI.[IsElectronic]),
			    TVTI.[ItemType] = ISNULL(TVTI.[ItemType], TI.[ItemType]),
			    TVTI.[OnUs] = ISNULL(TVTI.[OnUs], TI.[OnUs]),
			    TVTI.[cf_OnBank] = ISNULL(TVTI.[cf_OnBank], TI.[cf_OnBank]),
			    TVTI.[cf_DeferredPosting] = ISNULL(TVTI.[cf_DeferredPosting], TI.[cf_DeferredPosting]),
			    TVTI.[cf_NPASortCode] = ISNULL(TVTI.[cf_NPASortCode], TI.[cf_NPASortCode]),
			    TVTI.[cf_ChnlInsertReason] = ISNULL(TVTI.[cf_ChnlInsertReason], TI.[cf_ChnlInsertReason]),
			    TVTI.[cf_NoPaySuspectRsn] = ISNULL(TVTI.[cf_NoPaySuspectRsn], TI.[cf_NoPaySuspectRsn]),
			    TVTI.[cf_fCashItem] = ISNULL(TVTI.[cf_fCashItem], TI.[cf_fCashItem]),
			    TVTI.[HighValue] = ISNULL(TVTI.[HighValue], TI.[HighValue]),
			    TVTI.[Sortcode] = ISNULL(TVTI.[Sortcode], TI.[Sortcode]),
			    TVTI.[AccountNumber] = ISNULL(TVTI.[AccountNumber], TI.[AccountNumber]),
			    TVTI.[SerialReference] = ISNULL(TVTI.[SerialReference], TI.[SerialReference]),
			    TVTI.[Amount] = ISNULL(TVTI.[Amount], TI.[Amount]),
			    TVTI.[Currency] = ISNULL(TVTI.[Currency], TI.[Currency]),
			    TVTI.[TranCode] = ISNULL(TVTI.[TranCode], TI.[TranCode]),
			    TVTI.[OriginalAmount] = ISNULL(TVTI.[OriginalAmount], TI.[OriginalAmount]),
			    TVTI.[ICSAmount] = ISNULL(TVTI.[ICSAmount], TI.[ICSAmount]),
			    TVTI.[JGAccount] = ISNULL(TVTI.[JGAccount], TI.[JGAccount]),
			    TVTI.[AlternateSortCode] = ISNULL(TVTI.[AlternateSortCode], TI.[AlternateSortCode]),
			    TVTI.[AlternateAccount] = ISNULL(TVTI.[AlternateAccount], TI.[AlternateAccount]),
			    TVTI.[SwitchedSortCode] = ISNULL(TVTI.[SwitchedSortCode], TI.[SwitchedSortCode]),
			    TVTI.[SwitchedAccount] = ISNULL(TVTI.[SwitchedAccount], TI.[SwitchedAccount]),
			    TVTI.[RepresentFlag] = ISNULL(TVTI.[RepresentFlag], TI.[RepresentFlag]),
			    TVTI.[IsSortCodeDefaulted] = ISNULL(TVTI.[IsSortCodeDefaulted], TI.[IsSortCodeDefaulted]),
			    TVTI.[ISAccountNumberDefaulted] = ISNULL(TVTI.[ISAccountNumberDefaulted], TI.[ISAccountNumberDefaulted]),
			    TVTI.[ISSerialReferenceDefaulted] = ISNULL(TVTI.[ISSerialReferenceDefaulted], TI.[ISSerialReferenceDefaulted]),
			    TVTI.[IsSortCodeRepaired] = ISNULL(TVTI.[IsSortCodeRepaired], TI.[IsSortCodeRepaired]),
			    TVTI.[ISAccountNumberRepaired] = ISNULL(TVTI.[ISAccountNumberRepaired], TI.[ISAccountNumberRepaired]),
			    TVTI.[IsAmountRepaired] = ISNULL(TVTI.[IsAmountRepaired], TI.[IsAmountRepaired]),
			    TVTI.[ISSerialReferenceRepaired] = ISNULL(TVTI.[ISSerialReferenceRepaired], TI.[ISSerialReferenceRepaired]),
			    TVTI.[IsTCCorrected] = ISNULL(TVTI.[IsTCCorrected], TI.[IsTCCorrected]),
			    TVTI.[IsANCorrected] = ISNULL(TVTI.[IsANCorrected], TI.[IsANCorrected]),
			    TVTI.[IsSortCodeCorrected] = ISNULL(TVTI.[IsSortCodeCorrected], TI.[IsSortCodeCorrected]),
			    TVTI.[IsSerialCorrected] = ISNULL(TVTI.[IsSerialCorrected], TI.[IsSerialCorrected]),
			    TVTI.[IsReject] = ISNULL(TVTI.[IsReject], TI.[IsReject]),
			    TVTI.[AdjustmentReason] = ISNULL(TVTI.[AdjustmentReason], TI.[AdjustmentReason]),
			    TVTI.[NoPayReason] = ISNULL(TVTI.[NoPayReason], TI.[NoPayReason]),
			    TVTI.[PayDecision] = ISNULL(TVTI.[PayDecision], TI.[PayDecision]),
			    TVTI.[PayReason] = ISNULL(TVTI.[PayReason], TI.[PayReason]),
			    TVTI.[Narrative] = ISNULL(TVTI.[Narrative], TI.[Narrative]),
			    TVTI.[FraudCheckResult] = ISNULL(TVTI.[FraudCheckResult], TI.[FraudCheckResult]),
			    TVTI.[FraudCheckReason] = ISNULL(TVTI.[FraudCheckReason], TI.[FraudCheckReason]),
			    TVTI.[Day1ResponseStartDateTime] = ISNULL(TVTI.[Day1ResponseStartDateTime], TI.[Day1ResponseStartDateTime]),
			    TVTI.[Day1ResponseEndDateTime] = ISNULL(TVTI.[Day1ResponseEndDateTime], TI.[Day1ResponseEndDateTime]),
			    TVTI.[Day2ResponseWindowStartDateTime] = ISNULL(TVTI.[Day2ResponseWindowStartDateTime], TI.[Day2ResponseWindowStartDateTime]),
			    TVTI.[Day2ResponseWindowEndDateTime] = ISNULL(TVTI.[Day2ResponseWindowEndDateTime], TI.[Day2ResponseWindowEndDateTime]),
			    TVTI.[SettlementPeriodId] = ISNULL(TVTI.[SettlementPeriodId], TI.[SettlementPeriodId]),
			    TVTI.[CollectingParticipantId] = ISNULL(TVTI.[CollectingParticipantId], TI.[CollectingParticipantId]),
			    TVTI.[FrontImageQuality] = ISNULL(TVTI.[FrontImageQuality], TI.[FrontImageQuality]),
			    TVTI.[RearImageQuality] = ISNULL(TVTI.[RearImageQuality], TI.[RearImageQuality]),
			    TVTI.[ChargingParticipantId] = IIF(TVTI.[RepresentFlag]=1 AND @ResetValues=1,TVTI.[ChargingParticipantId], ISNULL(TI.[ChargingParticipantId], TVTI.[ChargingParticipantId])),
			    TVTI.[MessageType] = ISNULL(TVTI.[MessageType], TI.[MessageType]),
			    TVTI.[IntMessageType] = ISNULL(TVTI.[IntMessageType], TI.[IntMessageType]),
			    TVTI.[AgencyPayingParticipantId] = ISNULL(TVTI.[AgencyPayingParticipantId], TI.[AgencyPayingParticipantId]),
			    TVTI.[AgencyBeneficiaryParticipantId] = ISNULL(TVTI.[AgencyBeneficiaryParticipantId], TI.[AgencyBeneficiaryParticipantId]),
			    TVTI.[EISCDPayingParticipantId] = ISNULL(TVTI.[EISCDPayingParticipantId], TI.[EISCDPayingParticipantId]),
			    TVTI.[EISCDBeneficiaryParticipantId] = ISNULL(TVTI.[EISCDBeneficiaryParticipantId], TI.[EISCDBeneficiaryParticipantId]),
			    TVTI.[SettlementParticipantId] = ISNULL(TVTI.[SettlementParticipantId], TI.[SettlementParticipantId]),
			    TVTI.[ItemUpdateId] = ISNULL(TVTI.[ItemUpdateId], TI.[ItemUpdateId]),
			    TVTI.[CaptureItemId] = ISNULL(TVTI.[CaptureItemId], TI.[CaptureItemId]),
			    TVTI.[EntityId] = ISNULL(TVTI.[EntityId], TI.[EntityId]),
			    TVTI.[StateRevision] = ISNULL(TVTI.[StateRevision], TI.[StateRevision]),
			    TVTI.[AuditRevision] = ISNULL(TVTI.[AuditRevision], TI .[AuditRevision]),
			    TVTI.[CoreID] = ISNULL(TVTI.[CoreID], TI.[CoreID]),
			    TVTI.[BeneficiaryName] = ISNULL(TVTI.[BeneficiaryName], TI.[BeneficiaryName]),
			    TVTI.[TSetSource] = ISNULL(TVTI.[TSetSource], TI.[TSetSource]),
			    TVTI.[TSetCaptureDate] = ISNULL(TVTI.[TSetCaptureDate], TI.[TSetCaptureDate]),
			    TVTI.[TSetCollectingLocation] = ISNULL(TVTI.[TSetCollectingLocation], TI.[TSetCollectingLocation]),
			    TVTI.[TSetSubmissionDateTime] = ISNULL(TVTI.[TSetSubmissionDateTime], TI.[TSetSubmissionDateTime]),
			    TVTI.[SwitchRejectionCode] = ISNULL(TVTI.[SwitchRejectionCode], TI.[SwitchRejectionCode]),
				TVTI.[ChannelRiskType] = ISNULL(TVTI.[ChannelRiskType], TI.[ChannelRiskType]),
				TVTI.[DebitReference] = ISNULL(TVTI.[DebitReference], TI.[DebitReference]),
				TVTI.[DuplicateItemId] = ISNULL(TVTI.[DuplicateItemId], TI.[DuplicateItemId]),
				TVTI.[DuplicateItemStatus] = ISNULL(TVTI.[DuplicateItemStatus], TI.[DuplicateItemStatus]),
				TVTI.[DuplicateItemDateFirstSeen] = ISNULL(TVTI.[DuplicateItemDateFirstSeen], TI.[DuplicateItemDateFirstSeen]),
				TVTI.[DuplicateItemOriginalCollectingParticipant] = ISNULL(TVTI.[DuplicateItemOriginalCollectingParticipant], TI.[DuplicateItemOriginalCollectingParticipant]),
				TVTI.[DuplicateItemOriginalCaptureDate] = ISNULL(TVTI.[DuplicateItemOriginalCaptureDate], TI.[DuplicateItemOriginalCaptureDate]),
				TVTI.[DuplicateItemOriginalSource] = ISNULL(TVTI.[DuplicateItemOriginalSource], TI.[DuplicateItemOriginalSource]),
				TVTI.[StoppedItemId] = CASE WHEN TVTI.[StoppedItemStoppedDate] IS NOT NULL THEN TVTI.[TransitionItemsSKID] ELSE TI.[StoppedItemId] END,
				TVTI.[StoppedItemStoppedDate] = ISNULL(TVTI.[StoppedItemStoppedDate], TI.[StoppedItemStoppedDate]),
				TVTI.[StoppedItemStatus] = ISNULL(TVTI.[StoppedItemStatus], TI.[StoppedItemStatus]),
				TVTI.[StoppedItemAmount] = ISNULL(TVTI.[StoppedItemAmount], TI.[StoppedItemAmount]),
				TVTI.[StoppedItemBeneficiary] = ISNULL(TVTI.[StoppedItemBeneficiary], TI.[StoppedItemBeneficiary]),
				TVTI.[StoppedItemStopItemStartRange] = ISNULL(TVTI.[StoppedItemStopItemStartRange], TI.[StoppedItemStopItemStartRange]),
				TVTI.[StoppedItemStopItemEndRange] = ISNULL(TVTI.[StoppedItemStopItemEndRange], TI.[StoppedItemStopItemEndRange]),
				TVTI.[IsAmountCorrected] = ISNULL(TVTI.[IsAmountCorrected], TI.[IsAmountCorrected]),
				TVTI.[cf_ImageDateTime] = ISNULL(TVTI.[cf_ImageDateTime], TI.[cf_ImageDateTime])
			FROM 
				@tv_TransitionItems TVTI
				LEFT JOIN (  /* SELECT *
								FROM   (   
											SELECT * ,
												  ROW_NUMBER() OVER ( PARTITION BY UniqueItemIdentifier
                                                                      ORDER BY StateRevision DESC                                                                                                       
                                                                    ) RKD
                                            FROM   Base.TransitionItems
                                            WHERE  UniqueItemIdentifier IN (   
														   					SELECT UniqueItemIdentifier FROM  @tv_TransitionItems
                                                                           )
                                        ) TransitionItems
								WHERE  RKD = 1*/

								Select top 1 * from Base.TransitionItems
                                            WHERE  UniqueItemIdentifier IN (   
														   					SELECT UniqueItemIdentifier FROM  @tv_TransitionItems
                                                                           )
																		                  
																						  order by StateRevision desc
							) TI 
				ON TI.UniqueItemIdentifier = TVTI. UniqueItemIdentifier
			
			-- Update temp table TransitionItems with TsetEntityState for Tsets from ICNEntityHolder
			UPDATE TVTI	
			SET TVTI.[TsetEntityState] = ISNULL(EntityInfo.[EntityState], TVTI.[TsetEntityState])
			FROM @tv_TransitionItems TVTI
			LEFT JOIN @tvp_ICNEntityHolder EntityInfo
			ON EntityInfo.EntityIdentifier = TVTI.TransactionSetIdWithVersion
			AND EntityType = 'T'

			-- Update temp table TransitionItems with SwitchRejectionCode for Tsets 
			-- For 03MA01 Tsets having ErrorCode in EntityError should be updated for related items
			IF (@IntMessageType = '03MA01')
			BEGIN
				UPDATE TVTI	
				SET TVTI.[SwitchRejectionCode] = ISNULL(EntityInfo.[ErrorCode], TVTI.[SwitchRejectionCode])
				FROM @tv_TransitionItems TVTI
				LEFT JOIN @tvp_ICNEntityHolder EntityInfo
				ON EntityInfo.EntityIdentifier = TVTI.TransactionSetIdWithVersion
				AND EntityType = 'T'
			END

			SELECT
				[TransitionItemsSKID],				
				[ExtractId],							
				[UniqueItemIdentifier],				
				[Gender],							
				[EntityState],						
				[TransactionSetId],					
				[TransactionSetIdWithVersion],		
				[TsetEntityState],					
				[IsElectronic],						
				[ItemType],							
				[OnUs],								
				[cf_OnBank],							
				[cf_DeferredPosting],				
				[cf_NPASortCode],	
				[cf_ChnlInsertReason],--IIF(@ResetValues=1 AND [RepresentFlag]=1 AND [cf_ChnlInsertReason] IS NULL AND Gender='Db' ,'Paper', [cf_ChnlInsertReason]) As [cf_ChnlInsertReason],				
				[cf_NoPaySuspectRsn],				
				[cf_fCashItem],						
				[HighValue],							
				[Sortcode],							
				[AccountNumber],						
				[SerialReference],					
				[Amount],							
				[Currency],							
				[TranCode],							
				[OriginalAmount],					
				[ICSAmount],							
				[JGAccount],							
				[AlternateSortCode],					
				[AlternateAccount],					
				[SwitchedSortCode],					
				[SwitchedAccount],					
				[RepresentFlag],						
				[IsSortCodeDefaulted],				
				[ISAccountNumberDefaulted],			
				[ISSerialReferenceDefaulted],		
				[IsSortCodeRepaired],				
				[ISAccountNumberRepaired],			
				[IsAmountRepaired],					
				[ISSerialReferenceRepaired],			
				[IsTCCorrected],						
				[IsANCorrected],						
				[IsSortCodeCorrected],				
				[IsSerialCorrected],					
				[IsReject],							
				[AdjustmentReason],		
				[NoPayReason],--IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [NoPayReason]) As [NoPayReason],
				[PayDecision],--IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [PayDecision]) As [PayDecision],
				[PayReason],--IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [PayReason]) As [PayReason],
				[Narrative],							
				[FraudCheckResult],--IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [FraudCheckResult]) As [FraudCheckResult],
				[FraudCheckReason],--IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [FraudCheckReason]) As [FraudCheckReason],
				[Day1ResponseStartDateTime],			
				[Day1ResponseEndDateTime],			
				Day2ResponseWindowStartDateTime,--IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [Day2ResponseWindowStartDateTime]) As [Day2ResponseWindowStartDateTime],
				[Day2ResponseWindowEndDateTime],--IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [Day2ResponseWindowEndDateTime]) As [Day2ResponseWindowEndDateTime],
				[SettlementPeriodId],				
				[CollectingParticipantId],			
				[FrontImageQuality],					
				[RearImageQuality],					
				[ChargingParticipantId],				
				[MessageType],						
				[IntMessageType],					
				[AgencyPayingParticipantId],			
				[AgencyBeneficiaryParticipantId],	
				[EISCDPayingParticipantId],			
				[EISCDBeneficiaryParticipantId],		
				[SettlementParticipantId],			
				[ItemUpdateId],						
				[CaptureItemId],						
				[EntityId],							
				[StateRevision],						
				[AuditRevision],						
				[CoreID],							
				[BeneficiaryName],					
				[TSetSource],						
				[TSetCaptureDate],					
				[TSetCollectingLocation],			
				[TSetSubmissionDateTime],			
				[SwitchRejectionCode], --IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [SwitchRejectionCode]) As [SwitchRejectionCode],
				[ChannelRiskType],
				[DebitReference], --IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [DebitReference]) As [DebitReference],
				[IsAmountCorrected],							
				[DuplicateItemId],							
				[DuplicateItemStatus],						
				[DuplicateItemDateFirstSeen],				
				[DuplicateItemOriginalCollectingParticipant],
				[DuplicateItemOriginalCaptureDate],			
				[DuplicateItemOriginalSource],				
				[StoppedItemId],								
				[StoppedItemStoppedDate],					
				[StoppedItemStatus],							
				[StoppedItemAmount],							
				[StoppedItemBeneficiary],					
				[StoppedItemStopItemStartRange],				
				[StoppedItemStopItemEndRange],
				[cf_ImageDateTime]	
			FROM @tv_TransitionItems;


			IF @ResetValues=1
			BEGIN
				UPDATE @tv_TransitionItems 
				SET [SwitchRejectionCode] = null ,
					[DebitReference]=null,
					[NoPayReason]=null,
					[PayReason]=null,
					[PayDecision]=null,
					[FraudCheckResult]=null,
					[Day2ResponseWindowStartDateTime]=null,
					[Day2ResponseWindowEndDateTime]=null,
					[FraudCheckReason]=null
				WHERE [RepresentFlag] =1;

	
				UPDATE @tv_TransitionItems 
				SET cf_ChnlInsertReason = 'Paper' 
				WHERE [RepresentFlag]=1 AND [cf_ChnlInsertReason] IS NULL AND Gender='Db' 

			END
				
			
		END TRY

        BEGIN CATCH
            THROW;
        END CATCH;
    END;