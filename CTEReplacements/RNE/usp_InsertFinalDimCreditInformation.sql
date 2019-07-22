CREATE PROCEDURE [DataImport].[usp_InsertFinalDimCreditInformation]
	@BusinessDateRangeStart BIGINT,
	@BusinessDateRangeEnd	BIGINT
/*****************************************************************************************************************
* Name				: [DataImport].[usp_InsertFinalDimCreditInformation]
* Description		: This stored procedure INSERTs the final details of the Credits into the FinalEntityStates table available in the CreditEntityStateHistory table.
* Type of Procedure : Interpreted stored procedure
* Author			: Pavan Kumar Manneru
* Creation Date		: 24/08/2017
* Last Modified		: N/A
* Parameters		: 2
******************************************************************************************************************
*Parameter Name				Type			Description
*-----------------------------------------------------------------------------------------------------------------
 @BusinessDateRangeStart	BIGINT			Business date start range
 @BusinessDateRangeEnd		BIGINT			Business date end range
******************************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
******************************************************************************************************************
*										History
*-----------------------------------------------------------------------------------------------------------------
* Version	ID		Date			Modified By			Reason
******************************************************************************************************************
* 1.0.0		001		24-Aug-2017		Pavan Kumar			Initial version
* 1.0.1		002		03-Dec-2018		Rahul Khode			Added new column cf_ChnlInsertReason for insert/update
******************************************************************************************************************/
AS
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

	BEGIN TRY

		BEGIN

			SELECT
				CH	.CreditId,
				MAX(CH.MSG01)	AS RejMSG01
			INTO
				#MSG01RejectedItems
			FROM
				Report.dimCreditEntityStateHistory	AS CH
			INNER JOIN
				Staging.CreditEntityStateHistory	AS CDH
			ON
				CH.TransactionSetIdWithVersion = CDH.TransactionSetIdWithVersion
			WHERE
				CH.MSG01 IN ( 25,
								30,
								60	,
								130
							)
			AND CH.EntityType = 'I'
			GROUP BY
				CH.CreditId;

			SELECT
				CreditId,
				AccountNumber,
				Sortcode,
				Reference,
				isMultiDebit,
				DefaultedSortcode,
				ItemType,
				CreditEntryDate,
				CreditHoloverDate,
				OriginalSortcode,
				cf_NoPaySuspectRsn,
				MSG01,
				MSG02,
				MSG03,
				MSG04,
				MSG05,
				MSG06,
				MSG07,
				MSG08,
				MSG09,
				MSG11,
				MSG12,
				MSG13,
				PSTNG,
				cf_DeferredPosting,
				[cf_ICSTransactionID],
				[cf_LocationID],
				[AdjustmentReason],
				[APGDIN],
				[NoPayReason],
				[TranCode],
				[Comments],
				[APGBusinessDate],
				[RejectReason],
				[ReturnReason],
				[TransactionNumber],
				[JGAccount],
				[cf_SourceID],
				[cf_BrandID],
				[EISCDPayingParticipantId],
				[CollectingParticipantId],
				[ICSAmount],
				[KappaFraudResult],
				[KappaFraudReason],
				[cf_ChnlInsertReason],
				[cf_ImageDateTime],
				[cf_NPASortCode],
				[ProcessId],
				[EntityId],
				[FinalInclearingState],
				[FinalOutClearingState],
				[FinalclearingState],
				LEFT([TransactionSetIdWithVersion], 22) AS TransactionSetId,
				[TransactionSetIdWithVersion],
				[DocumentMessageId],
				ROW_NUMBER() OVER (PARTITION BY
									CreditId,
									MessageType
									ORDER BY
									Revision DESC
								)					AS finalItemRKD
			INTO
				#finalItems
			FROM
				Report.dimCreditEntityStateHistory
			WHERE
				EntityId
			BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd
			AND EntityType != 'T';


			CREATE NONCLUSTERED INDEX nci_finalItemRKD
			ON #finalItems (finalItemRKD)
			WHERE finalItemRKD = 1;


			SELECT
				CreditId,
				AccountNumber,
				Sortcode,
				Reference,
				isMultiDebit,
				DefaultedSortcode,
				ItemType,
				CreditEntryDate,
				CreditHoloverDate,
				OriginalSortcode,
				cf_NoPaySuspectRsn,
				MSG01,
				MSG02,
				MSG03,
				MSG04,
				MSG05,
				MSG06,
				MSG07,
				MSG08,
				MSG09,
				MSG11,
				MSG12,
				MSG13,
				PSTNG,
				cf_DeferredPosting,
				[cf_ICSTransactionID],
				[cf_LocationID],
				[AdjustmentReason],
				[APGDIN],
				[NoPayReason],
				[TranCode],
				[Comments],
				[APGBusinessDate],
				[RejectReason],
				[ReturnReason],
				[TransactionNumber],
				[JGAccount],
				[cf_SourceID],
				[cf_BrandID],
				[EISCDPayingParticipantId],
				[CollectingParticipantId],
				[ICSAmount],
				[KappaFraudResult],
				[KappaFraudReason],
				[cf_ChnlInsertReason],
				[cf_ImageDateTime],
				[cf_NPASortCode],
				[ProcessId],
				[EntityId],
				[FinalInclearingState],
				[FinalOutClearingState],
				[FinalclearingState],
				[finalItems].[TransactionSetId],
				[TransactionSetIdWithVersion],
				[DocumentMessageId]
			INTO
				#FinalMSG01Items
			FROM
				#finalItems AS finalItems
			WHERE
				[finalItems].[finalItemRKD] = 1;



			SELECT
				FinalMSG01Items.CreditId,
				AccountNumber,
				Sortcode,
				Reference,
				isMultiDebit,
				DefaultedSortcode,
				ItemType,
				CreditEntryDate,
				CreditHoloverDate,
				OriginalSortcode,
				CASE
					WHEN cf_NoPaySuspectRsn IS NULL
					THEN MAX(cf_NoPaySuspectRsn) OVER (PARTITION BY
														FinalMSG01Items.CreditId
														ORDER BY
														EntityId
															ROWS UNBOUNDED PRECEDING
													)
					ELSE cf_NoPaySuspectRsn
				END								AS cf_NoPaySuspectRsn,
				CASE
					WHEN [cf_ICSTransactionID] IS NULL
					THEN MAX([cf_ICSTransactionID]) OVER (PARTITION BY
															FinalMSG01Items.CreditId
															ORDER BY
															EntityId
															ROWS UNBOUNDED PRECEDING
														)
					ELSE [cf_ICSTransactionID]
				END								AS [cf_ICSTransactionID],
				CASE
					WHEN [cf_LocationID] IS NULL
					THEN MAX([cf_LocationID]) OVER (PARTITION BY
														FinalMSG01Items.CreditId
														ORDER BY
														EntityId
														ROWS UNBOUNDED PRECEDING
												)
					ELSE [cf_LocationID]
				END								AS [cf_LocationID],
				CASE
					WHEN [AdjustmentReason] IS NULL
					THEN MAX([AdjustmentReason]) OVER (PARTITION BY
														FinalMSG01Items.CreditId
														ORDER BY
														EntityId
															ROWS UNBOUNDED PRECEDING
													)
					ELSE [AdjustmentReason]
				END								AS [AdjustmentReason],
				CASE
					WHEN [APGDIN] IS NULL
					THEN MAX([APGDIN]) OVER (PARTITION BY
												FinalMSG01Items.CreditId
												ORDER BY
												EntityId
												ROWS UNBOUNDED PRECEDING
											)
					ELSE [APGDIN]
				END								AS [APGDIN],
				CASE
					WHEN [APGBusinessDate] IS NULL
					THEN MAX([APGBusinessDate]) OVER (PARTITION BY
														FinalMSG01Items.CreditId
														ORDER BY
														EntityId
														ROWS UNBOUNDED PRECEDING
													)
					ELSE [APGBusinessDate]
				END								AS [APGBusinessDate],
				CASE
					WHEN [MSG01RejectedItems].[RejMSG01] IS NOT NULL
					THEN [MSG01RejectedItems].[RejMSG01]
					ELSE FinalMSG01Items.MSG01
				END								AS MSG01,
				CASE
					WHEN [MSG01RejectedItems].[RejMSG01] IS NOT NULL
					THEN 0
					ELSE FinalMSG01Items.MSG02
				END								AS MSG02,
				CASE
					WHEN [MSG01RejectedItems].[RejMSG01] IS NOT NULL
					THEN 0
					ELSE FinalMSG01Items.MSG03
				END								AS MSG03,
				MSG04,
				MSG05,
				MSG06,
				MSG07,
				MSG08,
				MSG09,
				MSG11,
				MSG12,
				MSG13,
				PSTNG,
				CASE
					WHEN cf_DeferredPosting IS NULL
					THEN MAX(cf_DeferredPosting) OVER (PARTITION BY
														FinalMSG01Items.CreditId
														ORDER BY
														EntityId
															ROWS UNBOUNDED PRECEDING
													)
					ELSE cf_DeferredPosting
				END								AS cf_DeferredPosting,
				CASE
					WHEN [NoPayReason] IS NULL
					THEN MAX([NoPayReason]) OVER (PARTITION BY
													FinalMSG01Items.CreditId
													ORDER BY
													EntityId
													ROWS UNBOUNDED PRECEDING
												)
					ELSE [NoPayReason]
				END								AS [NoPayReason],
				CASE
					WHEN [TranCode] IS NULL
					THEN MAX([TranCode]) OVER (PARTITION BY
												FinalMSG01Items.CreditId
												ORDER BY
												EntityId
													ROWS UNBOUNDED PRECEDING
											)
					ELSE [TranCode]
				END								AS [TranCode],
				CASE
					WHEN [Comments] IS NULL
					THEN MAX([Comments]) OVER (PARTITION BY
												FinalMSG01Items.CreditId
												ORDER BY
												EntityId
													ROWS UNBOUNDED PRECEDING
											)
					ELSE [Comments]
				END								AS [Comments],
				CASE
					WHEN [RejectReason] IS NULL
					THEN MAX([RejectReason]) OVER (PARTITION BY
													FinalMSG01Items.CreditId
													ORDER BY
													EntityId
														ROWS UNBOUNDED PRECEDING
												)
					ELSE [RejectReason]
				END								AS [RejectReason],
				CASE
					WHEN [ReturnReason] IS NULL
					THEN MAX([ReturnReason]) OVER (PARTITION BY
													FinalMSG01Items.CreditId
													ORDER BY
													EntityId
														ROWS UNBOUNDED PRECEDING
												)
					ELSE [ReturnReason]
				END								AS [ReturnReason],
				CASE
					WHEN [TransactionNumber] IS NULL
					THEN MAX([TransactionNumber]) OVER (PARTITION BY
															FinalMSG01Items.CreditId
															ORDER BY
															EntityId
															ROWS UNBOUNDED PRECEDING
													)
					ELSE [TransactionNumber]
				END								AS [TransactionNumber],
				CASE
					WHEN [JGAccount] IS NULL
					THEN MAX([JGAccount]) OVER (PARTITION BY
													FinalMSG01Items.CreditId
													ORDER BY
													EntityId
													ROWS UNBOUNDED PRECEDING
											)
					ELSE [JGAccount]
				END								AS [JGAccount],
				CASE
					WHEN [cf_SourceID] IS NULL
					THEN MAX([cf_SourceID]) OVER (PARTITION BY
													FinalMSG01Items.CreditId
													ORDER BY
													EntityId
													ROWS UNBOUNDED PRECEDING
												)
					ELSE [cf_SourceID]
				END								AS [cf_SourceID],
				CASE
					WHEN [cf_BrandID] IS NULL
					THEN MAX([cf_BrandID]) OVER (PARTITION BY
													FinalMSG01Items.CreditId
													ORDER BY
													EntityId
													ROWS UNBOUNDED PRECEDING
												)
					ELSE [cf_BrandID]
				END								AS [cf_BrandID],
				CASE
					WHEN [EISCDPayingParticipantId] IS NULL
					THEN MAX([EISCDPayingParticipantId]) OVER (PARTITION BY
																FinalMSG01Items.CreditId
																ORDER BY
																EntityId
																	ROWS UNBOUNDED PRECEDING
															)
					ELSE [EISCDPayingParticipantId]
				END								AS [EISCDPayingParticipantId],
				[CollectingParticipantId],
				[ICSAmount],
				CASE
					WHEN KappaFraudResult IS NULL
					THEN MAX(KappaFraudResult) OVER (PARTITION BY
														FinalMSG01Items.CreditId
														ORDER BY
														EntityId
														ROWS UNBOUNDED PRECEDING
													)
					ELSE KappaFraudResult
				END								AS [KappaFraudResult],
				CASE
					WHEN KappaFraudReason IS NULL
					THEN MAX(KappaFraudReason) OVER (PARTITION BY
														FinalMSG01Items.CreditId
														ORDER BY
														EntityId
														ROWS UNBOUNDED PRECEDING
													)
					ELSE KappaFraudReason
				END								AS [KappaFraudReason],
				CASE
					WHEN [cf_ChnlInsertReason] IS NULL
					THEN MAX([cf_ChnlInsertReason]) OVER (PARTITION BY
															FinalMSG01Items.CreditId
															ORDER BY
															EntityId
															ROWS UNBOUNDED PRECEDING
														)
					ELSE [cf_ChnlInsertReason]
				END								AS [cf_ChnlInsertReason],
				CASE
					WHEN [cf_ImageDateTime] IS NULL
					THEN MAX([cf_ImageDateTime]) OVER (PARTITION BY
														FinalMSG01Items.CreditId
														ORDER BY
														EntityId
															ROWS UNBOUNDED PRECEDING
													)
					ELSE [cf_ImageDateTime]
				END								AS [cf_ImageDateTime],
				CASE
					WHEN [cf_NPASortCode] IS NULL
					THEN MAX([cf_NPASortCode]) OVER (PARTITION BY
														FinalMSG01Items.CreditId
														ORDER BY
														EntityId
														ROWS UNBOUNDED PRECEDING
													)
					ELSE [cf_NPASortCode]
				END								AS [cf_NPASortCode],
				CASE
					WHEN [ProcessId] IS NULL
					THEN MAX([ProcessId]) OVER (PARTITION BY
													FinalMSG01Items.CreditId
													ORDER BY
													EntityId
													ROWS UNBOUNDED PRECEDING
											)
					ELSE [ProcessId]
				END								AS [ProcessId],
				[EntityId],
				[FinalInclearingState],
				[FinalOutClearingState],
				[FinalclearingState],
				[FinalMSG01Items].[TransactionSetId],
				[TransactionSetIdWithVersion],
				CASE
					WHEN [DocumentMessageId] IS NULL
					THEN MAX([DocumentMessageId]) OVER (PARTITION BY
															FinalMSG01Items.CreditId
															ORDER BY
															EntityId
															ROWS UNBOUNDED PRECEDING
													)
					ELSE [DocumentMessageId]
				END								AS [DocumentMessageId]
			INTO
				#FinalCreditsCTEInitial
			FROM
				#FinalMSG01Items	AS FinalMSG01Items
			LEFT JOIN
				#MSG01RejectedItems AS MSG01RejectedItems
			ON
				FinalMSG01Items.CreditId = MSG01RejectedItems.CreditId;



			SELECT
				CreditId,
				AccountNumber,
				Sortcode,
				Reference,
				isMultiDebit,
				DefaultedSortcode,
				ItemType,
				CreditEntryDate,
				CreditHoloverDate,
				OriginalSortcode,
				cf_NoPaySuspectRsn,
				cf_DeferredPosting,
				[cf_ICSTransactionID],
				[cf_LocationID],
				[AdjustmentReason],
				[APGDIN],
				[NoPayReason],
				[TranCode],
				[Comments],
				[APGBusinessDate],
				[RejectReason],
				[ReturnReason],
				[TransactionNumber],
				[JGAccount],
				[cf_SourceID],
				[cf_BrandID],
				[EISCDPayingParticipantId],
				[CollectingParticipantId],
				[ICSAmount],
				[KappaFraudResult],
				[KappaFraudReason],
				[cf_ChnlInsertReason],
				[cf_ImageDateTime],
				[cf_NPASortCode],
				[ProcessId],
				MAX(MSG01) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS MSG01,
				MAX(MSG02) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS MSG02,
				MAX(MSG03) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS MSG03,
				MAX(MSG04) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS MSG04,
				MAX(MSG05) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS MSG05,
				MAX(MSG06) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS MSG06,
				MAX(MSG07) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS MSG07,
				MAX(MSG08) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS MSG08,
				MAX(MSG09) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS MSG09,
				MAX(MSG11) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS MSG11,
				MAX(MSG12) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS MSG12,
				MAX(MSG13) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS MSG13,
				MAX(PSTNG) OVER (PARTITION BY
									CreditId
									ORDER BY
									CreditId DESC
								)					AS PSTNG,
				MAX([FinalInclearingState]) OVER (PARTITION BY
													CreditId
													ORDER BY
													CreditId DESC
												) AS FinalInclearingState,
				MAX([FinalOutClearingState]) OVER (PARTITION BY
													CreditId
													ORDER BY
													CreditId DESC
												) AS FinalOutClearingState,
				MAX([FinalclearingState]) OVER (PARTITION BY
													CreditId
													ORDER BY
													CreditId DESC
											)	AS FinalclearingState,
				[TransactionSetId],
				[TransactionSetIdWithVersion],
				MAX([DocumentMessageId]) OVER (PARTITION BY
												CreditId
												ORDER BY
												CreditId DESC
											)	AS DocumentMessageId,
				ROW_NUMBER() OVER (PARTITION BY
									CreditId
									ORDER BY
									EntityId DESC
								)				AS Rnk
			INTO
				#FinalCreditsCTE
			FROM
				#FinalCreditsCTEInitial;


			CREATE NONCLUSTERED INDEX nci_Rnk
			ON #FinalCreditsCTE (Rnk)
			WHERE Rnk = 1;



			MERGE Report.dimCreditInformation AS EFC
			USING
				(
					SELECT
						CreditId,
						AccountNumber,
						Sortcode,
						Reference,
						isMultiDebit,
						DefaultedSortcode,
						ItemType,
						CreditEntryDate,
						CreditHoloverDate,
						OriginalSortcode,
						cf_NoPaySuspectRsn,
						MSG01,
						MSG02,
						MSG03,
						MSG04,
						MSG05,
						MSG06,
						MSG07,
						MSG08,
						MSG09,
						MSG11,
						MSG12,
						MSG13,
						PSTNG,
						cf_DeferredPosting,
						[cf_ICSTransactionID],
						[cf_LocationID],
						[AdjustmentReason],
						[APGDIN],
						[NoPayReason],
						[TranCode],
						[Comments],
						[APGBusinessDate],
						[RejectReason],
						[ReturnReason],
						[TransactionNumber],
						[JGAccount],
						[cf_SourceID],
						[cf_BrandID],
						[EISCDPayingParticipantId],
						[CollectingParticipantId],
						[ICSAmount],
						[KappaFraudResult],
						[KappaFraudReason],
						[cf_ChnlInsertReason],
						[cf_ImageDateTime],
						[cf_NPASortCode],
						[ProcessId],
						[FinalInclearingState],
						[FinalOutClearingState],
						[FinalclearingState],
						[TransactionSetId],
						[TransactionSetIdWithVersion],
						[DocumentMessageId]
					FROM
						#FinalCreditsCTE
					WHERE
						Rnk = 1
				) AS NFC
				(CreditId, AccountNumber, Sortcode, Reference, isMultiDebit, DefaultedSortcode, ItemType, CreditEntryDate, CreditHoloverDate, OriginalSortcode, cf_NoPaySuspectRsn, MSG01, MSG02, MSG03, MSG04, MSG05, MSG06, MSG07, MSG08, MSG09, MSG11, MSG12, MSG13, PSTNG, cf_DeferredPosting, [cf_ICSTransactionID], [cf_LocationID], [AdjustmentReason], [APGDIN], [NoPayReason], [TranCode], [Comments], [APGBusinessDate], [RejectReason], [ReturnReason], [TransactionNumber], [JGAccount], [cf_SourceID], [cf_BrandID], [EISCDPayingParticipantId], [CollectingParticipantId], [ICSAmount], [KappaFraudResult], [KappaFraudReason], [cf_ChnlInsertReason], [cf_ImageDateTime], [cf_NPASortCode], [ProcessId], [FinalInclearingState], [FinalOutClearingState], [FinalclearingState], [TransactionSetId], [TransactionSetIdWithVersion], [DocumentMessageId])
			ON EFC.CreditId = NFC.CreditId
			WHEN MATCHED
			THEN UPDATE SET
					EFC.CreditId = NFC.CreditId,
					EFC.AccountNumber = COALESCE(NFC.AccountNumber, EFC.AccountNumber),
					EFC.Sortcode = COALESCE(NFC.Sortcode, EFC.Sortcode),
					EFC.Reference = COALESCE(NFC.Reference, EFC.Reference),
					EFC.isMultiDebit = COALESCE(NFC.isMultiDebit, EFC.isMultiDebit),
					EFC.DefaultedSortcode = COALESCE(NFC.DefaultedSortcode, EFC.DefaultedSortcode),
					EFC.ItemType = COALESCE(NFC.ItemType, EFC.ItemType),
					EFC.CreditEntryDate = COALESCE(NFC.CreditEntryDate, EFC.CreditEntryDate),
					EFC.CreditHoloverDate = COALESCE(NFC.CreditHoloverDate, EFC.CreditHoloverDate),
					EFC.OriginalSortcode = COALESCE(NFC.OriginalSortcode, EFC.OriginalSortcode),
					EFC.cf_NoPaySuspectRsn = COALESCE(NFC.cf_NoPaySuspectRsn, EFC.cf_NoPaySuspectRsn),
					EFC.MSG01 = CASE
									WHEN NFC.MSG01 != 0
									THEN NFC.MSG01
									ELSE EFC.MSG01
								END,
					EFC.MSG02 = CASE
									WHEN NFC.MSG02 != 0
									THEN NFC.MSG02
									ELSE EFC.MSG02
								END,
					EFC.MSG03 = CASE
									WHEN NFC.MSG03 != 0
									THEN NFC.MSG03
									ELSE EFC.MSG03
								END,
					EFC.MSG04 = CASE
									WHEN NFC.MSG04 != 0
									THEN NFC.MSG04
									ELSE EFC.MSG04
								END,
					EFC.MSG05 = CASE
									WHEN NFC.MSG05 != 0
									THEN NFC.MSG05
									ELSE EFC.MSG05
								END,
					EFC.MSG06 = CASE
									WHEN NFC.MSG06 != 0
									THEN NFC.MSG06
									ELSE EFC.MSG06
								END,
					EFC.MSG07 = CASE
									WHEN NFC.MSG07 != 0
									THEN NFC.MSG07
									ELSE EFC.MSG07
								END,
					EFC.MSG08 = CASE
									WHEN NFC.MSG08 != 0
									THEN NFC.MSG08
									ELSE EFC.MSG08
								END,
					EFC.MSG09 = CASE
									WHEN NFC.MSG09 != 0
									THEN NFC.MSG09
									ELSE EFC.MSG09
								END,
					EFC.MSG11 = CASE
									WHEN NFC.MSG11 != 0
									THEN NFC.MSG11
									ELSE EFC.MSG11
								END,
					EFC.MSG12 = CASE
									WHEN NFC.MSG12 != 0
									THEN NFC.MSG12
									ELSE EFC.MSG12
								END,
					EFC.MSG13 = CASE
									WHEN NFC.MSG13 != 0
									THEN NFC.MSG13
									ELSE EFC.MSG13
								END,
					EFC.PSTNG = CASE
									WHEN NFC.PSTNG != 0
									THEN NFC.PSTNG
									ELSE EFC.PSTNG
								END,
					EFC.cf_DeferredPosting = COALESCE(NFC.cf_DeferredPosting, EFC.cf_DeferredPosting),
					EFC.[cf_ICSTransactionID] = COALESCE(NFC.[cf_ICSTransactionID], EFC.[cf_ICSTransactionID]),
					EFC.[cf_LocationID] = COALESCE(NFC.[cf_LocationID], EFC.[cf_LocationID]),
					EFC.[AdjustmentReason] = COALESCE(NFC.[AdjustmentReason], EFC.[AdjustmentReason]),
					EFC.[APGDIN] = COALESCE(NFC.[APGDIN], EFC.[APGDIN]),
					EFC.[NoPayReason] = COALESCE(NFC.[NoPayReason], EFC.[NoPayReason]),
					EFC.[TranCode] = COALESCE(NFC.[TranCode], EFC.[TranCode]),
					EFC.[Comments] = COALESCE(NFC.[Comments], EFC.[Comments]),
					EFC.[APGBusinessDate] = COALESCE(NFC.[APGBusinessDate], EFC.[APGBusinessDate]),
					EFC.[RejectReason] = COALESCE(NFC.[RejectReason], EFC.[RejectReason]),
					EFC.[ReturnReason] = COALESCE(NFC.[ReturnReason], EFC.[ReturnReason]),
					EFC.[TransactionNumber] = COALESCE(NFC.[TransactionNumber], EFC.[TransactionNumber]),
					EFC.[JGAccount] = COALESCE(NFC.[JGAccount], EFC.[JGAccount]),
					EFC.[cf_SourceID] = COALESCE(NFC.[cf_SourceID], EFC.[cf_SourceID]),
					EFC.[cf_BrandID] = COALESCE(NFC.[cf_BrandID], EFC.[cf_BrandID]),
					EFC.[EISCDPayingParticipantId] = COALESCE(NFC.[EISCDPayingParticipantId], EFC.[EISCDPayingParticipantId]),
					EFC.[CollectingParticipantId] = COALESCE(NFC.[CollectingParticipantId], EFC.[CollectingParticipantId]),
					EFC.[ICSAmount] = COALESCE(NFC.[ICSAmount], EFC.[ICSAmount]),
					EFC.[KappaFraudResult] = COALESCE(NFC.[KappaFraudResult], EFC.[KappaFraudResult]),
					EFC.[KappaFraudReason] = COALESCE(NFC.[KappaFraudReason], EFC.[KappaFraudReason]),
					EFC.[cf_ChnlInsertReason] = COALESCE(NFC.[cf_ChnlInsertReason], EFC.[cf_ChnlInsertReason]),
					EFC.[cf_ImageDateTime] = COALESCE(NFC.[cf_ImageDateTime], EFC.[cf_ImageDateTime]),
					EFC.[cf_NPASortCode] = COALESCE(NFC.[cf_NPASortCode], EFC.[cf_NPASortCode]),
					EFC.[ProcessId] = COALESCE(NFC.[ProcessId], EFC.[ProcessId]),
					EFC.[FinalInclearingState] = CASE
													WHEN NFC.[FinalInclearingState] != 0
													THEN NFC.[FinalInclearingState]
													ELSE EFC.[FinalInclearingState]
												END,
					EFC.[FinalOutClearingState] = CASE
													WHEN NFC.[FinalOutClearingState] != 0
													THEN NFC.[FinalOutClearingState]
													ELSE EFC.[FinalOutClearingState]
												END,
					EFC.[FinalclearingState] = CASE
												WHEN	NFC.[FinalclearingState] != 0
													THEN NFC.[FinalclearingState]
													ELSE EFC.[FinalclearingState]
											END,
					EFC.[TransactionSetId] = COALESCE(NFC.[TransactionSetId], EFC.[TransactionSetId]),
					EFC.[TransactionSetIdWithVersion] = COALESCE(NFC.[TransactionSetIdWithVersion], EFC.[TransactionSetIdWithVersion]),
					EFC.[DocumentMessageId] = COALESCE(NFC.[DocumentMessageId], EFC.[DocumentMessageId])
			WHEN NOT MATCHED
			THEN INSERT
					(
						CreditId,
						AccountNumber,
						Sortcode,
						Reference,
						isMultiDebit,
						DefaultedSortcode,
						ItemType,
						CreditEntryDate,
						CreditHoloverDate,
						OriginalSortcode,
						cf_NoPaySuspectRsn,
						MSG01,
						MSG02,
						MSG03,
						MSG04,
						MSG05,
						MSG06,
						MSG07,
						MSG08,
						MSG09,
						MSG11,
						MSG12,
						MSG13,
						PSTNG,
						cf_DeferredPosting,
						[cf_ICSTransactionID],
						[cf_LocationID],
						[AdjustmentReason],
						[APGDIN],
						[NoPayReason],
						[TranCode],
						[Comments],
						[APGBusinessDate],
						[RejectReason],
						[ReturnReason],
						[TransactionNumber],
						[JGAccount],
						[cf_SourceID],
						[cf_BrandID],
						[EISCDPayingParticipantId],
						[CollectingParticipantId],
						[ICSAmount],
						[KappaFraudResult],
						[KappaFraudReason],
						[cf_ChnlInsertReason],
						[cf_ImageDateTime],
						[cf_NPASortCode],
						[ProcessId],
						[FinalInclearingState],
						[FinalOutClearingState],
						[FinalclearingState],
						[TransactionSetId],
						[TransactionSetIdWithVersion],
						[DocumentMessageId]
					)
				VALUES
					(
						NFC.CreditId, NFC.AccountNumber, NFC.Sortcode, NFC.Reference, NFC.isMultiDebit, NFC.DefaultedSortcode, NFC.ItemType, NFC.CreditEntryDate, NFC.CreditHoloverDate, NFC.OriginalSortcode, NFC.cf_NoPaySuspectRsn, NFC.MSG01, NFC.MSG02, NFC.MSG03, NFC.MSG04, NFC.MSG05, NFC.MSG06, NFC.MSG07, NFC.MSG08, NFC.MSG09, NFC.MSG11, NFC.MSG12, NFC.MSG13, NFC.PSTNG, NFC.cf_DeferredPosting, NFC.[cf_ICSTransactionID], NFC.[cf_LocationID], NFC.[AdjustmentReason], NFC.[APGDIN], NFC.[NoPayReason], NFC.[TranCode], NFC.[Comments], NFC.[APGBusinessDate], NFC.[RejectReason], NFC.[ReturnReason], NFC.[TransactionNumber], NFC.[JGAccount], NFC.[cf_SourceID], NFC.[cf_BrandID], NFC.[EISCDPayingParticipantId], NFC.[CollectingParticipantId], NFC.[ICSAmount], NFC.[KappaFraudResult], NFC.[KappaFraudReason], NFC.[cf_ChnlInsertReason], NFC.[cf_ImageDateTime], NFC.[cf_NPASortCode], NFC.[ProcessId], NFC.[FinalInclearingState], NFC.[FinalOutClearingState], NFC.[FinalclearingState], NFC.[TransactionSetId], NFC.[TransactionSetIdWithVersion], NFC.[DocumentMessageId]
					);
		END;
	END TRY
	BEGIN CATCH
		DECLARE @Number INT = ERROR_NUMBER();
		DECLARE @Message VARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @UserName NVARCHAR(128) = CONVERT(sysname, CURRENT_USER);
		DECLARE @Severity INT = ERROR_SEVERITY();
		DECLARE @State INT = ERROR_STATE();
		DECLARE @Type VARCHAR(128)	= 'Stored Procedure';
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Source VARCHAR(128)	= ERROR_PROCEDURE();
		EXEC [Base].[usp_LogException]
			@Number,
			@Message,
			@UserName,
			@Severity,
			@State,
			@Type,
			@Line,
			@Source;
		THROW;
	END CATCH;

GO


GRANT
	EXECUTE
ON [DataImport].[usp_InsertFinalDimCreditInformation]
TO
	[RnEReportDwDataImporter];

GO

EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'DataImport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_InsertFinalDimCreditInformation';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This stored procedure INSERTs the final details of the Credits into the FinalEntityStates table available in the CreditEntityStateHistory table.',
	@level0type = N'SCHEMA',
	@level0name = N'DataImport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_InsertFinalDimCreditInformation';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'RnEReportDataWarehouse',
	@level0type = N'SCHEMA',
	@level0name = N'DataImport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_InsertFinalDimCreditInformation';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Calling Application',
	@value = N'IPSL.RNE.RefreshDataWarehouse.dtsx',
	@level0type = N'SCHEMA',
	@level0name = N'DataImport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_InsertFinalDimCreditInformation';

GO