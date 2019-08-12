CREATE PROCEDURE [Base].[usp_Process_TransitionItems_NewWithoutTemp]
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
	@BusinessDate			DATE

/*********************************************************************************************************************************************************************
* Name				: [Base].[usp_Process_TransitionItems]
* Description		: This stored procedure builds the data to be inserted into flat table.
* Type of Procedure : Interpreted stored procedure
* Author			: Linton Lazar Thalakotoor
* Creation Date		: 14/09/2018
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
* 1.0.0		001		14/09/2018		Linton				Initial version
* 1.0.1		002		17/09/2018		Lavin Sharma		Changes to implementation - moving Join logic from Insert SP to this one. Rename SP
* 1.0.2		003		20/09/2018		Lavin Sharma		Changes to implementation - Calculation Logic extracted out and removed
* 1.0.3		004		24/09/2018		Lavin Sharma		Changes to only insert Cr or Dr items and not all entities
* 1.0.4		005		24/09/2018		Lavin Sharma		Added Audit revision info
* 1.0.5		006		28/09/2018		Rahul Khode			Modified condition to fix issue related to duplicate entry and populate some columns
* 1.0.6		007		02/10/2018		Rahul Khode			Added logic to insert into TransitionItems in case of ICNEntityHolder and FraudInfo.
														Also added new column SwitchRejectionCode. Fixed issue of TsetEntityState update.
* 1.0.7		008		04/10/2018		Rahul Khode			Rewrited the entire SP
* 1.0.8		009		08/10/2018		Rahul Khode			Added temporary tables and updated logic related to temp tables
* 1.0.9		010		10/10/2018		Rahul Khode			Added logic to update SwitchRejectionCode for items in 03MA01
* 1.1.0		011		18/10/2018		Rahul Khode			Added logic to update Amount and ICSAmount when amount got adjusted
* 1.1.1		012		19/10/2018		Rahul Khode			Added logic to update Day2ResponseWindowStartDateTime and Day2ResponseWindowEndDateTime
* 1.1.2		013		22/10/2018		Rahul Khode			Added logic to update SwitchedSortCode and SwitchedAccount
* 1.1.3		014		29/10/2018		Rahul Khode			Added new column ChannelRiskType and modified logic for ChargingParticipantId to fetch from Document table
* 1.1.4		015     09-Nov-2018   	Rahul Khode			Added new column DebitReference in insert/update statement
* 1.1.5		016     10-Dec-2018   	Akuri Reddy			Added logic to reset fields if it is Represent scenario message
* 1.1.6		017     27-Dec-2018   	Lavin Sharma		Changed logic to pick TsetSource from AltSource instead of source and charging participant from Doc table in 
														asc order instead of descending
* 1.1.7		018     02-Jan-2019   	Rahul Khode			Changed sequence to update ChargingParticipantId in final update statement
* 1.1.8		019		15-Jan-2019		Rahul Khode			Updated SP to populate DuplicateDebit and StoppedItem details
* 1.1.9		020		11-Apr-2019		Linton Lazar		Updated SP to handle CNP posting not getting created for MSG13 debit for represent scenario. Bug fix # 213318
**********************************************************************************************************************************************************************/
AS
    BEGIN

        SET NOCOUNT ON;   
		
        BEGIN TRY

			DECLARE @ResetValues BIT = IIF(@IntMessageType='01MA01',1,0)

			-- Create temp tables for all user defined types
			CREATE TABLE #TransitionItems
			(
				[TransitionItemsSKID]							BIGINT				NOT NULL,
				[ExtractId]										VARCHAR(26)			NULL,
				[UniqueItemIdentifier]							VARCHAR(25)			NULL,
				[Gender]										VARCHAR(3)			NULL,
				[EntityState]									SMALLINT			NULL,
				[TransactionSetId]								VARCHAR(22)			NULL,
				[TransactionSetIdWithVersion]					VARCHAR(24)			NULL,
				[TsetEntityState]								SMALLINT			NULL,
				[IsElectronic]									BIT					NULL,
				[ItemType]										TINYINT				NULL, 
				[OnUs]											BIT					NULL, 
				[cf_OnBank]										TINYINT   			NULL,
				[cf_DeferredPosting]							VARCHAR(3)			NULL,
				[cf_NPASortCode]								VARCHAR(6)			NULL,
				[cf_ChnlInsertReason]							VARCHAR(20)			NULL,
				[cf_NoPaySuspectRsn]							VARCHAR(30)			NULL,
				[cf_fCashItem]									VARCHAR(1)			NULL,
				[HighValue]										BIT					NULL,
				[Sortcode]										INT					NULL,
				[AccountNumber]									INT					NULL, 
				[SerialReference]								VARCHAR(18)			NULL,
				[Amount]										NUMERIC (20, 2)		NULL,
				[Currency]										VARCHAR(10)			NULL,
				[TranCode]										VARCHAR (2)			NULL, 
				[OriginalAmount]								DECIMAL(11,2)		NULL,
				[ICSAmount]										NUMERIC (20, 2)		NULL,
				[JGAccount]										VARCHAR(11)			NULL,
				[AlternateSortCode]								INT					NULL, 
				[AlternateAccount]								INT					NULL, 
				[SwitchedSortCode]								INT					NULL, 
				[SwitchedAccount]								INT					NULL, 
				[RepresentFlag]									BIT					NULL,
				[IsSortCodeDefaulted]							BIT					NULL,
				[ISAccountNumberDefaulted]						BIT					NULL,
				[ISSerialReferenceDefaulted]					BIT					NULL,
				[IsSortCodeRepaired]							BIT					NULL,
				[ISAccountNumberRepaired]						BIT					NULL,
				[IsAmountRepaired]								BIT					NULL,
				[ISSerialReferenceRepaired]						BIT					NULL,
				[IsTCCorrected]									BIT					NULL,
				[IsANCorrected]									BIT					NULL,
				[IsSortCodeCorrected]							BIT					NULL,
				[IsSerialCorrected]								BIT					NULL,
				[IsReject]										BIT					NULL,
				[AdjustmentReason]								TINYINT				NULL,
				[NoPayReason]									VARCHAR(30)			NULL,
				[PayDecision]									BIT					NULL,
				[PayReason]										VARCHAR (4)			NULL,
				[Narrative]										VARCHAR(255)		NULL, 
				[FraudCheckResult]								VARCHAR(15)			NULL,
				[FraudCheckReason]								VARCHAR(4)			NULL,
				[Day1ResponseStartDateTime]						DATETIME2(3)		NULL, 
				[Day1ResponseEndDateTime]						DATETIME2(3)		NULL, 
				[Day2ResponseWindowStartDateTime]				DATETIME2(3)		NULL,
				[Day2ResponseWindowEndDateTime]					DATETIME2(3)		NULL,
				[SettlementPeriodId]							BIGINT				NULL,
				[CollectingParticipantId]						VARCHAR(6)			NULL,
				[FrontImageQuality]								BIT					NULL,
				[RearImageQuality]								BIT					NULL,
				[ChargingParticipantId]							VARCHAR(6)			NULL,
				[MessageType]									VARCHAR(6)			NOT NULL,
				[IntMessageType]								VARCHAR(6)			NULL,
				[AgencyPayingParticipantId]						VARCHAR(6)			NULL,
				[AgencyBeneficiaryParticipantId]				VARCHAR(6)			NULL,
				[EISCDPayingParticipantId]						VARCHAR(6)			NULL,
				[EISCDBeneficiaryParticipantId]					VARCHAR(6)			NULL,
				[SettlementParticipantId]						VARCHAR(6)			NULL,
				[ItemUpdateId]									BIGINT				NULL, 
				[CaptureItemId]									BIGINT				NULL, 
				[EntityId]										BIGINT				NULL,
				[StateRevision]									INT					NULL,
				[AuditRevision]									INT					NULL,
				[CoreID]										BIGINT				NULL,
				[BeneficiaryName]								VARCHAR(50)			NULL,
				[TSetSource]									SMALLINT			NULL,
				[TSetCaptureDate]								DATETIME2	(2)		NULL,
				[TSetCollectingLocation]						VARCHAR(10)			NULL,
				[TSetSubmissionDateTime]						DATETIME2	(2)		NULL,
				[SwitchRejectionCode]							VARCHAR(4)			NULL,
				[ChannelRiskType]								VARCHAR(4)			NULL,
				[DebitReference]								VARCHAR(18)			NULL,
				[IsAmountCorrected]								BIT					NULL,
				[DuplicateItemId]								VARCHAR (25)		NULL,
				[DuplicateItemStatus]							CHAR (4)			NULL,
				[DuplicateItemDateFirstSeen]					DATE				NULL,
				[DuplicateItemOriginalCollectingParticipant]	VARCHAR(6)			NULL,
				[DuplicateItemOriginalCaptureDate]				DATE				NULL,
				[DuplicateItemOriginalSource]					SMALLINT			NULL,
				[StoppedItemId]									BIGINT				NULL,
				[StoppedItemStoppedDate]						DATE				NULL,
				[StoppedItemStatus]								CHAR (4)			NULL,
				[StoppedItemAmount]								DECIMAL(14,2)		NULL,
				[StoppedItemBeneficiary]						VARCHAR (50)		NULL,
				[StoppedItemStopItemStartRange]					INT					NULL,
				[StoppedItemStopItemEndRange]					INT					NULL,
				[cf_ImageDateTime]								CHAR(28)			NULL,	
				INDEX [NCI_TransitionItems_UItemId_TsetIdVrsn] NONCLUSTERED ([UniqueItemIdentifier],[TransactionSetIdWithVersion])
			)

			-- Insert into temp table TransitionItems for ICNEntityHolder 			
			INSERT INTO #TransitionItems
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
				CAST(CONCAT(CONVERT(VARCHAR(8), @BusinessDate, 112), REPLICATE('0', 11)) AS BIGINT) + NEXT VALUE FOR [Base].[sqn_MsgID] AS TransitionItemsSKID
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
				[ChargingParticipantId]				=	COALESCE((SELECT ChargedParticipantId FROM [Base].[Document] WHERE DocumentId = (SELECT TOP 1 DocumentId FROM [Base].[TXSet] T WHERE T.TransactionSetIdWithVersion = [FinalCredits].[TSetIDWithVersion] ORDER BY T.InternalTXId ASC)), [FinalCredits].[ChargingParticipantId]),
				[AgencyPayingParticipantId]			=	[FinalCredits].[AgencyPayingParticipantId],
				[AgencyBeneficiaryParticipantId]	=	[FinalCredits].[AgencyBeneficiaryParticipantId],
				[EISCDBeneficiaryParticipantId]		=	[FinalCredits].[EISCDBeneficiaryParticipantId],
				[SettlementParticipantId]			=	[FinalCredits].[SettlementParticipantId],
				[ItemUpdateId]						=	[FinalCredits].[ItemUpdateId],
				[CaptureItemId]						=	[FinalCredits].[CaptureItemId],
				[EntityId]							=	[FinalCredits].[EntityId],
				[BeneficiaryName]					=	[CreditFraudData].[BeneficiaryName]
			FROM #TransitionItems TI
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
				[Day2ResponseWindowStartDateTime]	=	COALESCE([ShreddedDebits].[Day2ResponseStartDatetime], [FinalDebits].[ResponseDate]),
				[Day2ResponseWindowEndDateTime]		=	COALESCE([ShreddedDebits].[Day2ResponseEndDateTime], [FinalDebits].[ResponseTime]), 
				[SettlementPeriodId]				=	[FinalDebits].[SettlementPeriodId],
				[CollectingParticipantId]			=	[FinalDebits].[CollectingParticipantId],
				[FrontImageQuality]					=	[ShreddedDebits].[FrontImageQuality],
				[RearImageQuality]					=	[ShreddedDebits].[RearImageQuality],
				[ChargingParticipantId]				=	COALESCE((SELECT ChargedParticipantId FROM [Base].[Document] WHERE DocumentId = (SELECT TOP 1 DocumentId FROM [Base].[TXSet] T WHERE T.TransactionSetIdWithVersion = [FinalDebits].[TSetIDWithVersion] ORDER BY T.InternalTXId ASC)), [FinalDebits].[ChargingParticipantId]),
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
			FROM #TransitionItems TI
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
				[Amount]							=	COALESCE([UpdatedItemInfo].[Amount],[TI].[Amount]),
				[OriginalAmount]					=	[CaptureItemTable].[OriginalAmount],
				[ICSAmount]							=	COALESCE([UpdatedItemInfo].[ICSAmount],[CaptureItemTable].[ICSAmount]),
				[Day2ResponseWindowStartDateTime]	=	COALESCE([UpdatedItemInfo].[ResponseDate], [TI].[Day2ResponseWindowStartDateTime]),
				[Day2ResponseWindowEndDateTime]		=	COALESCE([UpdatedItemInfo].[ResponseTime], [TI].[Day2ResponseWindowEndDateTime]), 
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
				[NoPayReason]						=	COALESCE([UpdatedItemInfo].[NoPayReason],[TI].[NoPayReason]),
				[Narrative]							=	COALESCE([UpdatedItemInfo].[Narrative],[TI].[Narrative]),
				[AlternateSortCode]					=	COALESCE([UpdatedItemInfo].[AlternateSortCode],[TI].[AlternateSortCode]),
				[AlternateAccount]					=	COALESCE([UpdatedItemInfo].[AlternateAccount],[TI].[AlternateAccount]),
				[PayDecision]						=	COALESCE([UpdatedItemInfo].[PayDecision],[TI].[PayDecision]),
				[PayReason]							=	COALESCE([UpdatedItemInfo].[PayReason],[TI].[PayReason]),
				[SettlementPeriodId]				=	COALESCE([UpdatedItemInfo].[SettlementPeriodId],[TI].[SettlementPeriodId]),
				[SwitchedSortCode]					=	COALESCE([UpdatedItemInfo].[SwSortCode],[TI].[SwitchedSortCode]),
				[SwitchedAccount]					=	COALESCE([UpdatedItemInfo].[SwAccountNumber],[TI].[SwitchedAccount]),
				[ChannelRiskType]					=	[TSetInformation].[ChannelRiskType],
				[DebitReference]					=	[CaptureItemTable].[DebitReference],
				[IsAmountCorrected]					=	[CaptureItemTable].[IsAmountCorrected],
				[cf_ImageDateTime]					=	[CaptureItemTable].[cf_ImageDateTime]
			FROM
			#TransitionItems TI
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
			SET TVTI.[TransitionItemsSKID] = COALESCE(TVTI.[TransitionItemsSKID], TI.[TransitionItemsSKID]),
				TVTI.[ExtractId] = COALESCE(TVTI.[ExtractId], TI.[ExtractId]),
			    TVTI.[UniqueItemIdentifier] = COALESCE(TVTI.[UniqueItemIdentifier], TI.[UniqueItemIdentifier]),
			    TVTI.[Gender] = COALESCE(TVTI.[Gender], TI.[Gender]),
			    TVTI.[EntityState] = COALESCE(TVTI.[EntityState], TI.[EntityState]),
			    TVTI.[TransactionSetId] = COALESCE(TVTI.[TransactionSetId], TI.[TransactionSetId]),
			    TVTI.[TransactionSetIdWithVersion] = COALESCE(TVTI.[TransactionSetIdWithVersion], TI.[TransactionSetIdWithVersion]),
			    TVTI.[TsetEntityState] = COALESCE(TVTI.[TsetEntityState], TI.[TsetEntityState]),
			    TVTI.[IsElectronic] = COALESCE(TVTI.[IsElectronic], TI.[IsElectronic]),
			    TVTI.[ItemType] = COALESCE(TVTI.[ItemType], TI.[ItemType]),
			    TVTI.[OnUs] = COALESCE(TVTI.[OnUs], TI.[OnUs]),
			    TVTI.[cf_OnBank] = COALESCE(TVTI.[cf_OnBank], TI.[cf_OnBank]),
			    TVTI.[cf_DeferredPosting] = COALESCE(TVTI.[cf_DeferredPosting], TI.[cf_DeferredPosting]),
			    TVTI.[cf_NPASortCode] = COALESCE(TVTI.[cf_NPASortCode], TI.[cf_NPASortCode]),
			    TVTI.[cf_ChnlInsertReason] = COALESCE(TVTI.[cf_ChnlInsertReason], TI.[cf_ChnlInsertReason]),
			    TVTI.[cf_NoPaySuspectRsn] = COALESCE(TVTI.[cf_NoPaySuspectRsn], TI.[cf_NoPaySuspectRsn]),
			    TVTI.[cf_fCashItem] = COALESCE(TVTI.[cf_fCashItem], TI.[cf_fCashItem]),
			    TVTI.[HighValue] = COALESCE(TVTI.[HighValue], TI.[HighValue]),
			    TVTI.[Sortcode] = COALESCE(TVTI.[Sortcode], TI.[Sortcode]),
			    TVTI.[AccountNumber] = COALESCE(TVTI.[AccountNumber], TI.[AccountNumber]),
			    TVTI.[SerialReference] = COALESCE(TVTI.[SerialReference], TI.[SerialReference]),
			    TVTI.[Amount] = COALESCE(TVTI.[Amount], TI.[Amount]),
			    TVTI.[Currency] = COALESCE(TVTI.[Currency], TI.[Currency]),
			    TVTI.[TranCode] = COALESCE(TVTI.[TranCode], TI.[TranCode]),
			    TVTI.[OriginalAmount] = COALESCE(TVTI.[OriginalAmount], TI.[OriginalAmount]),
			    TVTI.[ICSAmount] = COALESCE(TVTI.[ICSAmount], TI.[ICSAmount]),
			    TVTI.[JGAccount] = COALESCE(TVTI.[JGAccount], TI.[JGAccount]),
			    TVTI.[AlternateSortCode] = COALESCE(TVTI.[AlternateSortCode], TI.[AlternateSortCode]),
			    TVTI.[AlternateAccount] = COALESCE(TVTI.[AlternateAccount], TI.[AlternateAccount]),
			    TVTI.[SwitchedSortCode] = COALESCE(TVTI.[SwitchedSortCode], TI.[SwitchedSortCode]),
			    TVTI.[SwitchedAccount] = COALESCE(TVTI.[SwitchedAccount], TI.[SwitchedAccount]),
			    TVTI.[RepresentFlag] = COALESCE(TVTI.[RepresentFlag], TI.[RepresentFlag]),
			    TVTI.[IsSortCodeDefaulted] = COALESCE(TVTI.[IsSortCodeDefaulted], TI.[IsSortCodeDefaulted]),
			    TVTI.[ISAccountNumberDefaulted] = COALESCE(TVTI.[ISAccountNumberDefaulted], TI.[ISAccountNumberDefaulted]),
			    TVTI.[ISSerialReferenceDefaulted] = COALESCE(TVTI.[ISSerialReferenceDefaulted], TI.[ISSerialReferenceDefaulted]),
			    TVTI.[IsSortCodeRepaired] = COALESCE(TVTI.[IsSortCodeRepaired], TI.[IsSortCodeRepaired]),
			    TVTI.[ISAccountNumberRepaired] = COALESCE(TVTI.[ISAccountNumberRepaired], TI.[ISAccountNumberRepaired]),
			    TVTI.[IsAmountRepaired] = COALESCE(TVTI.[IsAmountRepaired], TI.[IsAmountRepaired]),
			    TVTI.[ISSerialReferenceRepaired] = COALESCE(TVTI.[ISSerialReferenceRepaired], TI.[ISSerialReferenceRepaired]),
			    TVTI.[IsTCCorrected] = COALESCE(TVTI.[IsTCCorrected], TI.[IsTCCorrected]),
			    TVTI.[IsANCorrected] = COALESCE(TVTI.[IsANCorrected], TI.[IsANCorrected]),
			    TVTI.[IsSortCodeCorrected] = COALESCE(TVTI.[IsSortCodeCorrected], TI.[IsSortCodeCorrected]),
			    TVTI.[IsSerialCorrected] = COALESCE(TVTI.[IsSerialCorrected], TI.[IsSerialCorrected]),
			    TVTI.[IsReject] = COALESCE(TVTI.[IsReject], TI.[IsReject]),
			    TVTI.[AdjustmentReason] = COALESCE(TVTI.[AdjustmentReason], TI.[AdjustmentReason]),
			    TVTI.[NoPayReason] = COALESCE(TVTI.[NoPayReason], TI.[NoPayReason]),
			    TVTI.[PayDecision] = COALESCE(TVTI.[PayDecision], TI.[PayDecision]),
			    TVTI.[PayReason] = COALESCE(TVTI.[PayReason], TI.[PayReason]),
			    TVTI.[Narrative] = COALESCE(TVTI.[Narrative], TI.[Narrative]),
			    TVTI.[FraudCheckResult] = COALESCE(TVTI.[FraudCheckResult], TI.[FraudCheckResult]),
			    TVTI.[FraudCheckReason] = COALESCE(TVTI.[FraudCheckReason], TI.[FraudCheckReason]),
			    TVTI.[Day1ResponseStartDateTime] = COALESCE(TVTI.[Day1ResponseStartDateTime], TI.[Day1ResponseStartDateTime]),
			    TVTI.[Day1ResponseEndDateTime] = COALESCE(TVTI.[Day1ResponseEndDateTime], TI.[Day1ResponseEndDateTime]),
			    TVTI.[Day2ResponseWindowStartDateTime] = COALESCE(TVTI.[Day2ResponseWindowStartDateTime], TI.[Day2ResponseWindowStartDateTime]),
			    TVTI.[Day2ResponseWindowEndDateTime] = COALESCE(TVTI.[Day2ResponseWindowEndDateTime], TI.[Day2ResponseWindowEndDateTime]),
			    TVTI.[SettlementPeriodId] = COALESCE(TVTI.[SettlementPeriodId], TI.[SettlementPeriodId]),
			    TVTI.[CollectingParticipantId] = COALESCE(TVTI.[CollectingParticipantId], TI.[CollectingParticipantId]),
			    TVTI.[FrontImageQuality] = COALESCE(TVTI.[FrontImageQuality], TI.[FrontImageQuality]),
			    TVTI.[RearImageQuality] = COALESCE(TVTI.[RearImageQuality], TI.[RearImageQuality]),
			    TVTI.[ChargingParticipantId] = IIF(TVTI.[RepresentFlag]=1 AND @ResetValues=1,TVTI.[ChargingParticipantId], COALESCE(TI.[ChargingParticipantId], TVTI.[ChargingParticipantId])),
			    TVTI.[MessageType] = COALESCE(TVTI.[MessageType], TI.[MessageType]),
			    TVTI.[IntMessageType] = COALESCE(TVTI.[IntMessageType], TI.[IntMessageType]),
			    TVTI.[AgencyPayingParticipantId] = COALESCE(TVTI.[AgencyPayingParticipantId], TI.[AgencyPayingParticipantId]),
			    TVTI.[AgencyBeneficiaryParticipantId] = COALESCE(TVTI.[AgencyBeneficiaryParticipantId], TI.[AgencyBeneficiaryParticipantId]),
			    TVTI.[EISCDPayingParticipantId] = COALESCE(TVTI.[EISCDPayingParticipantId], TI.[EISCDPayingParticipantId]),
			    TVTI.[EISCDBeneficiaryParticipantId] = COALESCE(TVTI.[EISCDBeneficiaryParticipantId], TI.[EISCDBeneficiaryParticipantId]),
			    TVTI.[SettlementParticipantId] = COALESCE(TVTI.[SettlementParticipantId], TI.[SettlementParticipantId]),
			    TVTI.[ItemUpdateId] = COALESCE(TVTI.[ItemUpdateId], TI.[ItemUpdateId]),
			    TVTI.[CaptureItemId] = COALESCE(TVTI.[CaptureItemId], TI.[CaptureItemId]),
			    TVTI.[EntityId] = COALESCE(TVTI.[EntityId], TI.[EntityId]),
			    TVTI.[StateRevision] = COALESCE(TVTI.[StateRevision], TI.[StateRevision]),
			    TVTI.[AuditRevision] = COALESCE(TVTI.[AuditRevision], TI .[AuditRevision]),
			    TVTI.[CoreID] = COALESCE(TVTI.[CoreID], TI.[CoreID]),
			    TVTI.[BeneficiaryName] = COALESCE(TVTI.[BeneficiaryName], TI.[BeneficiaryName]),
			    TVTI.[TSetSource] = COALESCE(TVTI.[TSetSource], TI.[TSetSource]),
			    TVTI.[TSetCaptureDate] = COALESCE(TVTI.[TSetCaptureDate], TI.[TSetCaptureDate]),
			    TVTI.[TSetCollectingLocation] = COALESCE(TVTI.[TSetCollectingLocation], TI.[TSetCollectingLocation]),
			    TVTI.[TSetSubmissionDateTime] = COALESCE(TVTI.[TSetSubmissionDateTime], TI.[TSetSubmissionDateTime]),
			    TVTI.[SwitchRejectionCode] = COALESCE(TVTI.[SwitchRejectionCode], TI.[SwitchRejectionCode]),
				TVTI.[ChannelRiskType] = COALESCE(TVTI.[ChannelRiskType], TI.[ChannelRiskType]),
				TVTI.[DebitReference] = COALESCE(TVTI.[DebitReference], TI.[DebitReference]),
				TVTI.[DuplicateItemId] = COALESCE(TVTI.[DuplicateItemId], TI.[DuplicateItemId]),
				TVTI.[DuplicateItemStatus] = COALESCE(TVTI.[DuplicateItemStatus], TI.[DuplicateItemStatus]),
				TVTI.[DuplicateItemDateFirstSeen] = COALESCE(TVTI.[DuplicateItemDateFirstSeen], TI.[DuplicateItemDateFirstSeen]),
				TVTI.[DuplicateItemOriginalCollectingParticipant] = COALESCE(TVTI.[DuplicateItemOriginalCollectingParticipant], TI.[DuplicateItemOriginalCollectingParticipant]),
				TVTI.[DuplicateItemOriginalCaptureDate] = COALESCE(TVTI.[DuplicateItemOriginalCaptureDate], TI.[DuplicateItemOriginalCaptureDate]),
				TVTI.[DuplicateItemOriginalSource] = COALESCE(TVTI.[DuplicateItemOriginalSource], TI.[DuplicateItemOriginalSource]),
				TVTI.[StoppedItemId] = CASE WHEN TVTI.[StoppedItemStoppedDate] IS NOT NULL THEN TVTI.[TransitionItemsSKID] ELSE TI.[StoppedItemId] END,
				TVTI.[StoppedItemStoppedDate] = COALESCE(TVTI.[StoppedItemStoppedDate], TI.[StoppedItemStoppedDate]),
				TVTI.[StoppedItemStatus] = COALESCE(TVTI.[StoppedItemStatus], TI.[StoppedItemStatus]),
				TVTI.[StoppedItemAmount] = COALESCE(TVTI.[StoppedItemAmount], TI.[StoppedItemAmount]),
				TVTI.[StoppedItemBeneficiary] = COALESCE(TVTI.[StoppedItemBeneficiary], TI.[StoppedItemBeneficiary]),
				TVTI.[StoppedItemStopItemStartRange] = COALESCE(TVTI.[StoppedItemStopItemStartRange], TI.[StoppedItemStopItemStartRange]),
				TVTI.[StoppedItemStopItemEndRange] = COALESCE(TVTI.[StoppedItemStopItemEndRange], TI.[StoppedItemStopItemEndRange]),
				TVTI.[IsAmountCorrected] = COALESCE(TVTI.[IsAmountCorrected], TI.[IsAmountCorrected]),
				TVTI.[cf_ImageDateTime] = COALESCE(TVTI.[cf_ImageDateTime], TI.[cf_ImageDateTime])
			FROM 
				#TransitionItems TVTI
				LEFT JOIN (   SELECT *
								FROM   (   
											SELECT * ,
												  ROW_NUMBER() OVER ( PARTITION BY UniqueItemIdentifier
                                                                      ORDER BY StateRevision DESC                                                                                                       
                                                                    ) RKD
                                            FROM   Base.TransitionItems
                                            WHERE  UniqueItemIdentifier IN (   
														   					SELECT UniqueItemIdentifier FROM  #TransitionItems
                                                                           )
                                        ) TransitionItems
								WHERE  RKD = 1
							) TI 
				ON TI.UniqueItemIdentifier = TVTI. UniqueItemIdentifier
			
			-- Update temp table TransitionItems with TsetEntityState for Tsets from ICNEntityHolder
			UPDATE TVTI	
			SET TVTI.[TsetEntityState] = COALESCE(EntityInfo.[EntityState], TVTI.[TsetEntityState])
			FROM #TransitionItems TVTI
			LEFT JOIN @tvp_ICNEntityHolder EntityInfo
			ON EntityInfo.EntityIdentifier = TVTI.TransactionSetIdWithVersion
			AND EntityType = 'T'

			-- Update temp table TransitionItems with SwitchRejectionCode for Tsets 
			-- For 03MA01 Tsets having ErrorCode in EntityError should be updated for related items
			IF (@IntMessageType = '03MA01')
			BEGIN
				UPDATE TVTI	
				SET TVTI.[SwitchRejectionCode] = COALESCE(EntityInfo.[ErrorCode], TVTI.[SwitchRejectionCode])
				FROM #TransitionItems TVTI
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
				IIF(@ResetValues=1 AND [RepresentFlag]=1 AND [cf_ChnlInsertReason] IS NULL AND Gender='Db' ,'Paper', [cf_ChnlInsertReason]) As [cf_ChnlInsertReason],				
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
				IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [NoPayReason]) As [NoPayReason],
				IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [PayDecision]) As [PayDecision],
				IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [PayReason]) As [PayReason],
				[Narrative],							
				IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [FraudCheckResult]) As [FraudCheckResult],
				IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [FraudCheckReason]) As [FraudCheckReason],
				[Day1ResponseStartDateTime],			
				[Day1ResponseEndDateTime],			
				IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [Day2ResponseWindowStartDateTime]) As [Day2ResponseWindowStartDateTime],
				IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [Day2ResponseWindowEndDateTime]) As [Day2ResponseWindowEndDateTime],
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
				IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [SwitchRejectionCode]) As [SwitchRejectionCode],
				[ChannelRiskType],
				IIF(@ResetValues=1 AND [RepresentFlag]=1,NULL, [DebitReference]) As [DebitReference],
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
			FROM #TransitionItems

		
			
		END TRY

        BEGIN CATCH
            THROW;
        END CATCH;
    END;