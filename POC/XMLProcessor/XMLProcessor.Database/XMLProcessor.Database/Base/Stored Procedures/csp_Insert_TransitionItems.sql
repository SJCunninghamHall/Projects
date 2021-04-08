CREATE PROCEDURE [Base].[csp_Insert_TransitionItems]
       @TVPTransitionItems [Base].[tv_TransitionItems] READONLY

/*************************************************************************************************************************
* Name               : [Base].[csp_Insert_TransitionItems]
* Description        : This stored procedure is called by all credit and Debit loaders to ensure that
*                      the TransitionItems table is always updated.
* Type of Procedure  : Interpreted stored procedure
* Author             : Rahul Khode
* Creation Date      : 17/09/2018
* Last Modified      : N/A
* Parameters         : 1
**************************************************************************************************************************
*Parameter Name                    Type                                               Description
*-------------------------------------------------------------------------------------------------------------------------
@TVPTransitionItems [Base].[tv_TransitionItems]        Contains all data to load into TransitionItems
**************************************************************************************************************************
* Returns                   : 
* Important Notes    : N/A 
* Dependencies              : 
**************************************************************************************************************************
*                                                                       History
*-------------------------------------------------------------------------------------------------------------------------
* Version     ID            Date                 Modified By                 Reason
**************************************************************************************************************************
* 1.0.0              001     17-Sep-2018         Rahul Khode                 Initial version
* 1.0.1              002     10-Oct-2018         Rahul Khode                 Added new column SwitchRejectionCode in insert statement
* 1.0.2              003     29-Oct-2018         Rahul Khode                 Added new column ChannelRiskType in insert statement
* 1.0.3              004     09-Nov-2018         Rahul Khode                 Added new column DebitReference in insert statement
* 1.0.4              005           15-Jan-2019          Rahul Khode                      Updated SP to populate DuplicateDebit and StoppedItem column details
**************************************************************************************************************************/
WITH NATIVE_COMPILATION,
         SCHEMABINDING
              ,EXECUTE AS OWNER 
AS
BEGIN ATOMIC WITH ( TRANSACTION ISOLATION LEVEL = SNAPSHOT, 
LANGUAGE = N'English' )
BEGIN TRY                   
	INSERT INTO [Base].[TransitionItems]
	(
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
		[cf_ChnlInsertReason],
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
		[NoPayReason],
		[PayDecision],
		[PayReason],
		[Narrative],
		[FraudCheckResult],
		[FraudCheckReason],
		[Day1ResponseStartDateTime],
		[Day1ResponseEndDateTime],
		[Day2ResponseWindowStartDateTime],
        [Day2ResponseWindowEndDateTime],
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
        [SwitchRejectionCode],
        [ChannelRiskType],
        [DebitReference],
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
	)
    (
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
			[cf_ChnlInsertReason],
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
            [NoPayReason],
            [PayDecision],
            [PayReason],
            [Narrative],
            [FraudCheckResult],
            [FraudCheckReason],
            [Day1ResponseStartDateTime],
            [Day1ResponseEndDateTime],
            [Day2ResponseWindowStartDateTime],
            [Day2ResponseWindowEndDateTime],
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
            [SwitchRejectionCode],
            [ChannelRiskType],
            [DebitReference],
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
    FROM 
		@TVPTransitionItems    
	)
	END TRY
       
	BEGIN CATCH
		THROW;
	END CATCH;
END;
GO