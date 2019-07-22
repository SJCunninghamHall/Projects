CREATE PROCEDURE [Web].[usp_Get_ImageClearingItemDetails_WebService_ByUniqueItemIdentifer]
	@UniqueItemIdentifier	VARCHAR(25),
	@RoleName				VARCHAR(400)	= NULL
/*****************************************************************************************************
* Name				: [Web].[usp_Get_ImageClearingItemDetails_WebService_ByUniqueItemIdentifer]
* Description		: Stored Procedure to get the images for the UniqueItemIdentifer
* Type of Procedure : Interpreted stored procedure
* Author			: Pavan Kumar Manneru
* Creation Date		: 25/10/2016
* Last Modified		: N/A
* Parameters		:
*******************************************************************************************************
*Parameter Name				Type				Description
*------------------------------------------------------------------------------------------------------
@UniqueItemIdentifier		VARCHAR				Unique Item Identifier
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************
*										History
*------------------------------------------------------------------------------------------------------
* Version 					ID          Date                    Reason
*******************************************************************************************************
* 1.0.0						001         25/10/2016   			Initial version
*******************************************************************************************************/
AS
	BEGIN

		BEGIN TRY
			IF @RoleName IS NOT NULL
				BEGIN
					EXECUTE AS USER = @RoleName;
				END;

			SET NOCOUNT ON;

			SELECT
				Db	.ItemId,
				Db.InternalTxId,
				Db.DebitId								AS UniqueItemIdentifier,
				CAST(Db.SerialNumber AS VARCHAR(18))	AS RefSerial,
				Db.Sortcode,
				Db.AccountNumber,
				Db.TranCode,
				Db.Amount,
				Db.Currency,
				'DB'									AS Gender,
				Db.ItemType,
				Db.OnUs,
				Db.Represent							AS Represent,
				Db.RepairedSortcode,
				Db.RepairedAccount,
				Db.DefaultedSortcode,
				Db.DefaultedAccount,
				Db.SwitchedSortCode,
				Db.SwitchedAccount,
				Db.APGDIN,
				NULL									AS MatchedDuplicateId,
				Db.FCMIdentifier,
				Db.CaptureItemId,
				Db.IsDeleted,
				Db.IsAmountCorrected,
				Db.IsANCorrected,
				Db.IsSortCodeCorrected,
				Db.IsSerialCorrected
			INTO
				#ItemsCTE
			FROM
				Base.vw_FinalDebit AS Db
			WHERE
				Db.DebitId = @UniqueItemIdentifier
			UNION ALL
			SELECT
				Cr	.ItemId,
				Cr.InternalTxId,
				Cr.CreditId							AS UniqueItemIdentifier,
				CAST(Cr.Reference AS VARCHAR(18)) AS RefSerial,
				Cr.Sortcode,
				Cr.AccountNumber,
				Cr.TranCode,
				Cr.Amount,
				Cr.Currency,
				'CR'								AS Gender,
				Cr.ItemType,
				Cr.OnUs,
				NULL								AS Represent,
				Cr.RepairedSortcode,
				Cr.RepairedAccount,
				Cr.DefaultedSortcode,
				Cr.DefaultedAccount,
				Cr.SwitchedSortCode,
				Cr.SwitchedAccount,
				Cr.APGDIN,
				NULL								AS MatchedDuplicateId,
				Cr.FCMIdentifier,
				Cr.CaptureItemId,
				Cr.IsDeleted,
				Cr.IsAmountCorrected,
				Cr.IsANCorrected,
				Cr.IsSortCodeCorrected,
				Cr.IsSerialCorrected
			FROM
				Base.vw_FinalCredit AS Cr
			WHERE
				Cr.CreditId = @UniqueItemIdentifier;

			CREATE CLUSTERED INDEX ci_ItemId
			ON #ItemsCTE (ItemId);
			CREATE NONCLUSTERED INDEX nci_Currency
			ON #ItemsCTE (Currency);
			CREATE NONCLUSTERED INDEX nci_ItemType
			ON #ItemsCTE (ItemType);
			CREATE NONCLUSTERED INDEX nci_InternalTxId
			ON #ItemsCTE (InternalTxId);
			CREATE NONCLUSTERED INDEX nci_SortCode
			ON #ItemsCTE (SortCode);
			CREATE NONCLUSTERED INDEX nci_UniqueItemIdentifier
			ON #ItemsCTE (UniqueItemIdentifier);
			CREATE NONCLUSTERED INDEX nci_CaptureItemId
			ON #ItemsCTE (CaptureItemId);
			CREATE NONCLUSTERED INDEX nci_UniqueItemIdentifier
			ON #ItemsCTE (UniqueItemIdentifier);

			SELECT
				0																AS ImagePaperClearingIndicator,
				FLOOR(FinalItms.ItemID / 100000000000)							AS BusinessDate,
				vwTx.CaptureDate												AS CapturedDateTime,
				[FinalItms].[RefSerial]											AS SerialReference,
				FinalItms.SortCode,
				FinalItms.AccountNumber											AS Account,
				FinalItms.TranCode												AS TranCode,
				FinalItms.Amount												AS Amount,
				Ccy.Currency													AS Currency,
				[FinalItms].[Gender]											AS Gender,
				ItmTp.ItemTypeCode												AS ItemType,
				FinalItms.OnUs													AS OnUsItemIndicator,
				CASE
					WHEN ItmTp.ItemTypeCode =
						(
							SELECT
								ItemTypeCode
							FROM
								Lookup.ItemType WITH (SNAPSHOT)
							WHERE
								Id	= 5
						)
					THEN COALESCE(RTPConfig.RTPPaidIndicator, 3)
					ELSE 0
				END																AS RTPPaidIndicator,
				COALESCE(FinalItms.Represent, 0)								AS RePresentedItemIndicator,
				FrdStsRslts.FraudResult											AS FraudCheckResult,
				CASE
					WHEN
						(
							FinalItms.RepairedSortcode = 1
					OR		FinalItms.RepairedAccount = 1
					OR		FinalItms.IsAmountCorrected = 1
					OR		FinalItms.IsANCorrected = 1
					OR		FinalItms.IsSortCodeCorrected = 1
					OR		FinalItms.IsSerialCorrected = 1
						)
					THEN 1
					ELSE 0
				END																AS RepairedItemIndicator,
				CASE
					WHEN
						(
							FinalItms.DefaultedSortcode = 1
					OR		FinalItms.DefaultedAccount = 1
						)
					THEN 1
					ELSE 0
				END																AS DefaultedItemIndicator,
				CASE
					WHEN
						(
							FinalItms.SwitchedSortCode IS NOT NULL
					OR		FinalItms.SwitchedAccount IS NOT NULL
						)
					THEN 1
					ELSE 0
				END																AS SwitchedItemIndicator,
				CASE
					WHEN Sto.Status IS NOT NULL
					THEN 1
					ELSE 0
				END																AS DebitStoppedItemIndicator,
				CASE
					WHEN [FinalItms].[MatchedDuplicateId] IS NOT NULL
					THEN 1
					ELSE 0
				END																AS DebitDuplicateItemIndicator,
				CASE
					WHEN FinalEntityState.ErrorEntityId IS NOT NULL
					THEN 1
					ELSE 0
				END																AS ItemErrorIndicator,
				COALESCE(FinalItms.IsDeleted, 0)								AS IsDeleted,
				FinalEntityState.EntityState									AS EntityState,
				COALESCE(btc.SortCode, vwTx.CollectingLocation)					AS CollectingLocation,
				vwTx.CollectingBranchLocation									AS CollectingBranchLocation,
				vwTx.CollectingParticipantId									AS CollectingParticipantIdentifier,
				CASE
					WHEN [FinalItms].[Gender] = 'DB'
					THEN PayBenPcpt.ParticipantId
					ELSE NULL
				END																AS PayingParticipantIdentifier,
				CASE
					WHEN [FinalItms].[Gender] = 'CR'
					THEN PayBenPcpt.ParticipantId
					ELSE NULL
				END																AS BeneficiaryParticipantIdentifier,
				COALESCE(CAST(Jb.SourceID AS VARCHAR(4)), vwTx.ChannelRiskType) AS SourceID,
				FinalItms.UniqueItemIdentifier,
				vwTx.TransactionSetIdWithVersion								AS TransactionSetId,
				vwDoc.DocumentMessageId											AS DocumentSubmissionIdentifier,
				FinalItms.APGDIN												AS CaptureDIN,
				--All the legacy fields
				NULL															AS BranchIBDEDIN,
				NULL															AS WorkStream,
				NULL															AS PassNumber,
				NULL															AS RecordType,
				NULL															AS ImageIndicator,
				NULL															AS FreeMissingIndicator,
				NULL															AS RejectItemIndicator,
				NULL															AS AdjustmentReason,
				NULL															AS OutsortReason,
				NULL															AS Narrative
			FROM
				#ItemsCTE								AS FinalItms
			--Join currency lookup table for getting the currency value
			LEFT JOIN
				Lookup.Currency							AS Ccy WITH (SNAPSHOT)
			ON
				Ccy.Id = FinalItms.Currency
			--Join ItemType Lookup table for getting the ItemType value
			LEFT JOIN
				Lookup.ItemType							AS ItmTp WITH (SNAPSHOT)
			ON
				ItmTp.Id = FinalItms.ItemType
			--Join the TransactionSet view to get the TransactionSetId and the CaptureDateTime 
			LEFT JOIN
				[Base].[vw_TXSet]						AS vwTx
			ON
				vwTx.InternalTxId = FinalItms.InternalTxId
			--Join the Document view to get the DocumentSubmissionIdentifier
			LEFT JOIN
				[Base].[vw_Document]					AS vwDoc
			ON
				vwTx.DocumentId = vwDoc.DocumentId
			--Join to get the paying participantId when it is Debit otherwise Beneficiary PartcipantId
			LEFT JOIN
				[ReferenceData].[ParticipantSortcodes]	AS PayBenPcpt WITH (SNAPSHOT)
			ON
				PayBenPcpt.Sortcode = FinalItms.SortCode
			--Join the FraudStatusResults to get the fraud related information
			LEFT JOIN
				(
					SELECT
						FraudId,
						ItemId,
						FraudResult
					FROM
						(
							SELECT
								FraudId,
								ItemId,
								FraudResult
							FROM
								[Base].[FraudStatusResults] WITH (SNAPSHOT)
							WHERE
								FraudId IN
									(
										SELECT
											MAX(FraudId)
										FROM
											[Base].[FraudStatusResults] WITH (SNAPSHOT)
										WHERE
											ItemId	= @UniqueItemIdentifier
										GROUP BY
											ItemId
									)
						) AS FinalFrdSts
				)										AS FrdStsRslts
			ON
				FrdStsRslts.ItemId = FinalItms.UniqueItemIdentifier
			--Join the StoppedItem to get the Debit stopped Item indicator
			LEFT JOIN
				Base.StoppedItem						AS Sto WITH (SNAPSHOT)
			ON
				Sto.ItemId = FinalItms.ItemId
			--Join the CaptureItem to get the Deleted flag from APG
			LEFT JOIN
				Base.Batch								AS btc WITH (SNAPSHOT)
			ON
				btc.BatchId = FinalItms.CaptureItemId
			LEFT JOIN
				Base.Job								AS Jb WITH (SNAPSHOT)
			ON
				Jb.JobId = btc.JobId
			--Join to get the latest EntityState of that item
			LEFT JOIN
				(
					SELECT
						EntityId,
						ErrorEntityId,
						EntityIdentifier,
						EntityState
					FROM
						(
							SELECT
								en	.EntityId,
								ener.EntityId		AS ErrorEntityId,
								en.EntityIdentifier,
								en.EntityState,
								ROW_NUMBER() OVER (PARTITION BY
													en.EntityIdentifier
													ORDER BY
													en.Revision DESC
												) AS EntityErrorRank
							FROM
								Base.Entity			AS en WITH (SNAPSHOT)
							LEFT JOIN
								Base.EntityError	AS ener WITH (SNAPSHOT)
							ON
								ener.EntityId = en.EntityId
							WHERE
								en.EntityIdentifier = @UniqueItemIdentifier
						) AS EntityErr
					WHERE
						[EntityErr].[EntityErrorRank] = 1
				)										AS FinalEntityState
			ON
				FinalEntityState.EntityIdentifier = FinalItms.UniqueItemIdentifier
			--Join to get the RTPPaidIndicator
			LEFT JOIN
				[ReferenceData].[RTPPaidEntityStates]	AS RTPConfig WITH (SNAPSHOT)
			ON
				RTPConfig.EntityState = FinalEntityState.EntityState;

			IF @RoleName IS NOT NULL
				BEGIN
					REVERT;
				END;

		END TRY
		BEGIN CATCH
			THROW;
		END CATCH;

	END;
GO

GRANT
	EXECUTE
ON [Web].[usp_Get_ImageClearingItemDetails_WebService_ByUniqueItemIdentifer]
TO
	WebItemRetrieval;
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'STAR',
	@level0type = N'SCHEMA',
	@level0name = N'Web',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Get_ImageClearingItemDetails_WebService_ByUniqueItemIdentifer';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Stored Procedure to get the items for the UniqueItemIdentifer',
	@level0type = N'SCHEMA',
	@level0name = N'Web',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Get_ImageClearingItemDetails_WebService_ByUniqueItemIdentifer';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Web',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Get_ImageClearingItemDetails_WebService_ByUniqueItemIdentifer';
