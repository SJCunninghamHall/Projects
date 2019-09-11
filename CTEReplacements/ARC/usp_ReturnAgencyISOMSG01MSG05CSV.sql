CREATE PROCEDURE [Agency].[usp_ReturnAgencyISOMSG01MSG05CSV]
	@AgencyId		INT,
	@BusinessDate	DATE,
	@FileName		VARCHAR(200),
	@TotalItemCount INT = 0
/*****************************************************************************************************
* Name				: [Agency].[usp_ReturnAgencyISOMSG01MSG05CSV]
* Description		: This Stored Procedure returns the MSG01 and MSG05 Items in CSV format for a given AgencyId
* Type of Procedure : Interpreted stored procedure
* Author			: Nageswara Rao
* Creation Date		: 20/08/2018
*******************************************************************************************************/ 
AS
	BEGIN

		SET NOCOUNT ON;

		SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

		BEGIN TRY

			BEGIN TRAN;

			--To derive the business date range for retrieving items from the FinalCredit table
			DECLARE @BusinessDateFrom BIGINT;
			DECLARE @BusinessDateTo BIGINT;
			--Table varible to calculate the number of TSets available for extraction for a given AgencyId
			DECLARE @EligibleISOMSG01Tsets [Agency].[tv_ISOMSG01Tsets];
			DECLARE @HeaderBusinessDate VARCHAR(10);
			--DECLARE @TotalItemCount INT

			DECLARE @ItemsCount INT;
			DECLARE @SubmittedCredItemCount INT;
			DECLARE @SubmittedDebItemCount INT;
			DECLARE @SubmittedCredItemValue NUMERIC(13, 2);
			DECLARE @DispersalValue NUMERIC(13, 2);
			DECLARE @SubmittedDispersalVolume INT;
			DECLARE @RejectedItemCount INT;
			DECLARE @RejectedItemValue NUMERIC(13, 2);
			DECLARE @AdjustedItemCount INT;

			SET @BusinessDateFrom = Base.cfn_Convert_Date_StartRangeKey(@BusinessDate);
			SET @BusinessDateTo = Base.cfn_Convert_Date_EndRangeKey(@BusinessDate);
			SET @HeaderBusinessDate = FORMAT(@BusinessDate, 'yyyyMMdd');

			CREATE TABLE #EntityInfo
				(
					CoreId				BIGINT		NULL,
					EntityIdentifier	VARCHAR(99) NULL,
					EntityState			SMALLINT	NULL,
					EntityType			CHAR(6)		NULL,
					DocumentMessageId	VARCHAR(23) NULL,
					IntMessageType		CHAR(6)		NULL,
					RKD					SMALLINT	NULL,
					INDEX [NCI_Entity_Info_EntityId] NONCLUSTERED ([EntityIdentifier])
				);

			INSERT INTO
				#EntityInfo
			SELECT
				E.CoreId,
				E.EntityIdentifier,
				E.EntityState,
				E.EntityType,
				Doc.DocumentMessageId,
				C.IntMessageType,
				ROW_NUMBER() OVER (PARTITION BY
									E.EntityIdentifier,
									IntMessageType
									ORDER BY
									E.Revision DESC
								) AS RKD
			FROM
				Base.Core			AS C WITH (SNAPSHOT)
			LEFT JOIN
				Base.vw_Document	AS Doc
			ON
				C.XMLMessageId = Doc.XMLMessageId
			JOIN
				Base.Entity			AS E WITH (SNAPSHOT)
			ON
				C.CoreId = E.CoreId
			WHERE
				(
					(
						C.IntMessageType IN ( '01MA02',
												'01MA04',
												'01MA06',
												'05MA03',
												'03MA02'
											)
				AND		E.EntityType = 'I'
					)
			OR
				(
					C.IntMessageType = '01MA06'
			AND		E.EntityType = 'T'
				)
			OR
				(
					C.IntMessageType = '02MA01'
			AND		E.EntityType = 'D'
				)
			OR
				(
					C.IntMessageType = '01MA05'
			AND		E.EntityType = 'I'
			AND		E.EntityState = 82 --Included a condition for ITP Item EntityState
				)
				)
			AND E.EntityId
			BETWEEN @BusinessDateFrom AND @BusinessDateTo;

			INSERT INTO
				#EntityInfo
			SELECT
				[EI].[CoreId],
				FD.DebitId			AS EntityIdentifier,
				[EI].[EntityState],
				[EI].[EntityType],
				[EI].[DocumentMessageId],
				[EI].[IntMessageType],
				ROW_NUMBER() OVER (PARTITION BY
									FD.DebitId
									ORDER BY
									[EI].[CoreId] DESC
								) AS RKD
			FROM
				#EntityInfo			AS EI
			INNER JOIN
				Base.vw_FinalCredit AS FC
			ON
				[EI].[EntityIdentifier] = FC.CreditId
			AND [EI].[IntMessageType] = '05MA03'
			AND [EI].[EntityType] = 'I'
			INNER JOIN
				Base.vw_FinalDebit	AS FD
			ON
				FC.InternalTxId = FD.InternalTxId
			WHERE
				[EI].[IntMessageType] = '05MA03'
			AND [EI].[EntityType] = 'I';

			INSERT INTO
				@EligibleISOMSG01Tsets
				(
					TransactionSetIdWithVersion,
					InternalTxId,
					TransactionSetRank
				)
			SELECT
				EligibleTransactionSets.TransactionSetId,
				InternalTxId,
				1	AS TransactionSetRank
			FROM
				(
					SELECT
						TX	.TransactionSetId,
						TX.InternalTxId,
						ROW_NUMBER() OVER (PARTITION BY
											TX.TransactionSetId
											ORDER BY
											TX.InternalTxId DESC
										) AS RKD
					FROM
						[Base].[TXSet]					AS TX
					INNER JOIN
						Base.Document					AS D
					ON
						D.DocumentId = TX.DocumentId
					INNER JOIN
						Base.Core						AS CO WITH (SNAPSHOT)
					ON
						D.XMLMessageId = CO.XMLMessageId
					INNER JOIN
						Base.FinalCredit				AS FC
					ON
						FC.TransactionSetId = TX.TransactionSetId
					LEFT OUTER JOIN
						ReferenceData.AgencyIdentifiers AS AI WITH (SNAPSHOT)
					ON
						AI.AgencyParticipantId = FC.CollectingParticipantId
					WHERE
						CO.IntMessageType IN (	'01MA01',
												'05MA01'
											)
					AND FC.AgencyBeneficiaryParticipantId = @AgencyId
					AND ISNULL(AI.AgencyId, 0) <> @AgencyId
					AND TX.InternalTxId
					BETWEEN @BusinessDateFrom AND @BusinessDateTo
				) AS EligibleTransactionSets
			WHERE
				[EligibleTransactionSets].[RKD] = 1;

			--SELECT @TotalItemCount = COALESCE(MAX(TransactionSetRank),0) FROM @EligibleISOMSG01Tsets

			IF (@TotalItemCount = 0)
				BEGIN
					SELECT
						[Result].[RowValue]
					FROM
						(
							SELECT
								'Filename,Date,FileVolume,Submitted Credit Volume,Submitted Debit Volume,Submitted Credit Value,Dispersal Value,Submitted Dispersal Volume,Rejected Volume,Rejected Value,Adjusted Volume'	+ REPLICATE(',', 16) AS RowValue,
								1																																																				AS RNO
							UNION ALL
							SELECT
								@FileName	+ ',' + @HeaderBusinessDate + ',' + RIGHT('00000' + CONVERT(VARCHAR, ISNULL(@ItemsCount, 0)), 5) + ',' + RIGHT('00000' + CONVERT(VARCHAR, ISNULL(@SubmittedCredItemCount, 0)), 5) + ',' + RIGHT('00000' + CONVERT(VARCHAR, ISNULL(@SubmittedDebItemCount, 0)), 5) + ',' + CONVERT(VARCHAR, ISNULL(@SubmittedCredItemValue, 0.00)) + ',' + CONVERT(VARCHAR, ISNULL(@DispersalValue, 0.00)) + ',' + RIGHT('00000' + CONVERT(VARCHAR, ISNULL(@SubmittedDispersalVolume, 0)), 5) + ',' + RIGHT('00000' + CONVERT(VARCHAR, ISNULL(@RejectedItemCount, 0)), 5) + ',' + CONVERT(VARCHAR, ISNULL(@RejectedItemValue, 0.00)) + ',' + RIGHT('00000' + CONVERT(VARCHAR, ISNULL(@AdjustedItemCount, 0)), 5) + REPLICATE(',', 16) AS RowValue,
								2																																																																																																																																																																																AS RNO
							UNION ALL
							SELECT
								REPLICATE(',', 25)	AS RowValue,
								3					AS RNO
							UNION ALL
							SELECT
								'Transaction Set ID,Collecting Participant ID,Collecting Branch Location,Collecting Location,Collecting Channel,Gender,Item ID,Item Type,Transaction Code,Reference / Serial,Sort Code,Account Number,Original Amount,Submitted Amount,Cash Amount,Funded Amount,Non-Funded Amount,Beneficiary Name,Represented Flag,Item Rejected?,Rejection Reason Code,Rejection Reason,Amount Adjusted?,Adjustment Reason Code,Adjustment Reason'	AS RowValue,
								4																																																																																																										AS RNO
							UNION ALL
							SELECT
								'No Data Available' AS RowValue,
								5					AS RNO
						) AS Result
					ORDER BY
						[Result].[RNO];
				END;
			ELSE
				BEGIN

					SELECT
						ROW_NUMBER	() OVER (PARTITION BY
											TX.TransactionSetId,
											FD.DebitId
											ORDER BY
											TX.Version DESC,
											TX.InternalTxId ASC,
											FD.ItemId DESC,
											I.ItemID DESC
										)										AS Dup,
						ETSET.TransactionSetIdWithVersion,
						TX.TransactionSetId											AS [Transaction Set ID],
						RIGHT('00' + CAST(TX.[Version] AS VARCHAR(2)), 2)		AS TxSetVrsn,
						TX.CollectingParticipantId									AS [Collecting Participant ID],
						TX.CollectingBranchLocation									AS [Collecting Branch Location],
						TX.CollectingLocation										AS [Collecting Location],
						TX.ChannelRiskType											AS [Collecting Channel],
						(
							SELECT
								COUNT(DebitId)
							FROM
								Base.FinalDebit AS FDB WITH (SNAPSHOT)
							WHERE
								FDB.TransactionSetId = ETSET.TransactionSetIdWithVersion
						)															AS DebitCount,
						'DEBIT'														AS [Gender],
						FD.DebitId													AS [Item ID],
						ITMTYPE.ItemTypeCode										AS [Item Type],
						FD.TranCode													AS [Transaction Code],
						RIGHT('000000' + CAST(FD.Serial AS VARCHAR(6)), 6)			AS [Reference / Serial],
						RIGHT('000000' + CAST(FD.Sortcode AS VARCHAR(6)), 6) AS [Sort Code],
						RIGHT('00000000' + CAST(FD.AccountNumber AS VARCHAR(8)), 8) AS [Account Number],
						CONVERT(VARCHAR, I.OriginalAmount)							AS [Original Amount],
						CONVERT(VARCHAR, FD.Amount)									AS [Submitted Amount],
						NULL														AS [Cash Amount],
						NULL														AS [Funded Amount],
						NULL														AS [Non-Funded Amount],
						NULL														AS [Beneficiary Name],
						IIF(FD.Represent = 1, 'Yes', 'No')				AS [Represented Flag],
						CASE
							WHEN CO.IntMessageType = '05MA01'
							THEN 'NA'
							WHEN
								(
									[AdjRej01MA02ES].[EntityState] = 30
							OR		[AdjRej01MA04ES].[EntityState] = 60
							OR		[AdjRej03MA02ES].[EntityState] = 130
								)
							THEN 'Yes'
							ELSE 'No'
						END															AS [Item Rejected?],
						CASE
							WHEN FD.FinalclearingState = 30
							THEN I.cf_NoPaySuspectRsn
							WHEN FD.FinalclearingState = 60
							THEN REJ60.RejectionReasonDescription
							WHEN FD.FinalclearingState = 130
							THEN REJ130.RejectionReasonDescription
							ELSE ''
						END															AS [Rejection Reason],
						CASE
							WHEN FD.FinalclearingState = 30
							THEN RR.RejectionReasonCode
							WHEN FD.FinalclearingState = 60
							THEN REJ60.RejectionReasonCode
							WHEN FD.FinalclearingState = 130
							THEN REJ130.RejectionReasonCode
							ELSE ''
						END															AS [Rejection Reason Code],
						CASE
							WHEN CO.IntMessageType = '05MA01'
							THEN 'NA'
							WHEN FD.Amount = I.OriginalAmount
							THEN 'No'
							WHEN FD.Amount <> I.OriginalAmount
							THEN 'Yes'
							ELSE 'NA'
						END															AS [Amount Adjusted?],
						FD.AdjustmentReason											AS [Adjustment Reason Code],
						AdjRsnDebit.AdjustmentReason								AS [Adjustment Reason],
						CASE
							WHEN [AdjRej01MA02ES].[EntityState] IN
									(
										SELECT
											EntityState
										FROM
											[ReferenceData].[EntityExtractFilter] WITH (SNAPSHOT)
										WHERE
											[FilterKey] = 'AGYADJ'
									)
							OR	[AdjRej01MA04ES].[EntityState] IN
									(
										SELECT
											EntityState
										FROM
											[ReferenceData].[EntityExtractFilter] WITH (SNAPSHOT)
										WHERE
											[FilterKey] = 'AGYADJ'
									)
							OR	[AdjRej03MA02ES].[EntityState] = 140
							THEN 1
							ELSE NULL
						END															AS [Item Adjusted],
						CASE
							WHEN (
									[SubmittedES].[IntMessageType] = '01MA06'
							AND		[SubmittedES].[EntityState] IN
										(
											SELECT
												EntityState
											FROM
												[ReferenceData].[EntityExtractFilter] WITH (SNAPSHOT)
											WHERE
												[FilterKey] = 'MSG01'
										)
								)
							OR
								(
									[SubmittedES].[IntMessageType] = '01MA05'
							AND		[SubmittedES].[EntityState] IN ( 82 )
								)
							OR
								(
									[SubmittedES].[IntMessageType] = '05MA03'
							AND		[SubmittedES].[EntityState] IN
										(
											SELECT
												EntityState
											FROM
												[ReferenceData].[EntityExtractFilter] WITH (SNAPSHOT)
											WHERE
												[FilterKey] = 'MSG05'
										)
								)
							THEN 1
							ELSE NULL
						END															AS [Item Submitted]
					INTO
						#EligibleItems
					FROM
						@EligibleISOMSG01Tsets				AS ETSET
					INNER JOIN
						[Base].[TXSet]						AS TX
					ON
						ETSET.TransactionSetIdWithVersion = TX.TransactionSetId
					INNER JOIN
						Base.FinalDebit						AS FD
					ON
						TX.TransactionSetId = FD.TransactionSetId
					LEFT OUTER JOIN
						Base.ItemUpdate						AS U WITH (SNAPSHOT)
					ON
						FD.ItemId = U.InternalId
					LEFT JOIN
						Base.Core							AS CO WITH (SNAPSHOT)
					ON
						CO.CoreId = U.CoreId
					LEFT OUTER JOIN
						Base.Item							AS I WITH (SNAPSHOT)
					ON
						FD.DebitId = I.FCMIdentifier
					LEFT JOIN
						Lookup.ItemType						AS ITMTYPE WITH (SNAPSHOT)
					ON
						ITMTYPE.Id = FD.ItemType
					LEFT JOIN
						Base.DebitFraudData					AS DBFRD WITH (SNAPSHOT)
					ON
						DBFRD.ItemId = FD.ItemId
					LEFT JOIN
						ReferenceData.APGAdjustmentReasons	AS AdjRsnDebit WITH (SNAPSHOT)
					ON
						FD.AdjustmentReason = AdjRsnDebit.AdjustmentCode
					LEFT JOIN
						ReferenceData.APGAdjustmentReasons	AS AdjRsnItem WITH (SNAPSHOT)
					ON
						I.AdjustmentReason = AdjRsnItem.AdjustmentCode
					LEFT JOIN
						#EntityInfo							AS AdjRej01MA02ES
					ON
						FD.DebitId = [AdjRej01MA02ES].[EntityIdentifier]
					AND [AdjRej01MA02ES].[RKD] = 1
					AND [AdjRej01MA02ES].[IntMessageType] = '01MA02'
					AND [AdjRej01MA02ES].[EntityType] = 'I'
					LEFT JOIN
						#EntityInfo							AS AdjRej01MA04ES
					ON
						FD.DebitId = [AdjRej01MA04ES].[EntityIdentifier]
					AND [AdjRej01MA04ES].[RKD] = 1
					AND [AdjRej01MA04ES].[IntMessageType] = '01MA04'
					AND [AdjRej01MA04ES].[EntityType] = 'I'
					LEFT JOIN
						#EntityInfo							AS AdjRej03MA02ES
					ON
						FD.DebitId = [AdjRej03MA02ES].[EntityIdentifier]
					AND [AdjRej03MA02ES].[RKD] = 1
					AND [AdjRej03MA02ES].[IntMessageType] = '03MA02'
					AND [AdjRej03MA02ES].[EntityType] = 'I'
					LEFT JOIN
						#EntityInfo							AS SubmittedES
					ON
						FD.DebitId = [SubmittedES].[EntityIdentifier]
					AND [SubmittedES].[RKD] = 1
					AND [SubmittedES].[IntMessageType] IN ( '01MA05',
															'01MA06',
															'05MA03'
														)
					AND [SubmittedES].[EntityType] = 'I'
					LEFT JOIN
						[ReferenceData].[RejectionReasons]	AS RR WITH (SNAPSHOT)
					ON
						I.cf_NoPaySuspectRsn = RR.RejectionReasonDescription
					LEFT JOIN
						[ReferenceData].[RejectionReasons]	AS REJ60 WITH (SNAPSHOT)
					ON
						FD.FinalclearingState = REJ60.RejectionReasonCode
					AND REJ60.RejectionReasonDescription = 'Withdrawn after Fraud'
					LEFT JOIN
						[ReferenceData].[RejectionReasons]	AS REJ130 WITH (SNAPSHOT)
					ON
						FD.FinalclearingState = 130
					AND REJ130.RejectionReasonDescription = 'Withdrawn after ICS CI rejection'
					UNION ALL
					SELECT
						ROW_NUMBER	() OVER (PARTITION BY
											TX.TransactionSetId,
											FC.CreditId
											ORDER BY
											TX.Version DESC,
											TX.InternalTxId ASC,
											FC.ItemId DESC,
											I.ItemID DESC
										)														AS Dup,
						ETSET.TransactionSetIdWithVersion,
						TX.TransactionSetId															AS [Transaction Set ID],
						RIGHT('00' + CAST(TX.[Version] AS VARCHAR(2)), 2)						AS TxSetVrsn,
						TX.CollectingParticipantId													AS [Collecting Participant ID],
						TX.CollectingBranchLocation													AS [Collecting Branch Location],
						TX.CollectingLocation														AS [Collecting Location],
						TX.ChannelRiskType															AS [Collecting Channel],
						NULL																		AS DebitCount,
						'CREDIT'																	AS [Gender],
						FC.CreditId																	AS [Item ID],
						ITMTYPE.ItemTypeCode														AS [Item Type],
						FC.TranCode																	AS [Transaction Code],
						FC.[Reference]																AS [Reference / Serial],
						RIGHT('000000' + CAST(FC.Sortcode AS VARCHAR(6)), 6)			AS [Sort Code],
						RIGHT('00000000' + CAST(FC.AccountNumber AS VARCHAR(8)), 8)					AS [Account Number],
						CONVERT(VARCHAR, I.OriginalAmount)											AS [Original Amount],
						CONVERT(VARCHAR, FC.Amount)													AS [Submitted Amount],
						IIF(CRFRD.CashAmount > FC.Amount, FC.Amount, CRFRD.CashAmount) AS [Cash Amount],
						IIF(CRFRD.FundedAmount > FC.Amount, FC.Amount, CRFRD.FundedAmount)	AS [Funded Amount],
						IIF(CRFRD.NonFundedAmount > FC.Amount, FC.Amount, CRFRD.NonFundedAmount)	AS [Non-Funded Amount],
						CRFRD.BeneficiaryName														AS [Beneficiary Name],
						NULL																		AS [Represented Flag],
						CASE
							WHEN CO.IntMessageType = '05MA01'
							THEN 'NA'
							WHEN
								(
									[AdjRej01MA02ES].[EntityState] = 30
							OR		[AdjRej01MA04ES].[EntityState] = 60
							OR		[AdjRej03MA02ES].[EntityState] = 130
								)
							THEN 'Yes'
							ELSE 'No'
						END																			AS [Item Rejected?],
						CASE
							WHEN FC.FinalclearingState = 30
							THEN I.cf_NoPaySuspectRsn
							WHEN FC.FinalclearingState = 60
							THEN REJ60.RejectionReasonDescription
							WHEN FC.FinalclearingState = 130
							THEN REJ130.RejectionReasonDescription
							ELSE ''
						END																			AS [Rejection Reason],
						CASE
							WHEN FC.FinalclearingState = 30
							THEN RR.RejectionReasonCode
							WHEN FC.FinalclearingState = 60
							THEN REJ60.RejectionReasonCode
							WHEN FC.FinalclearingState = 130
							THEN REJ130.RejectionReasonCode
							ELSE ''
						END																			AS [Rejection Reason Code],
						CASE
							WHEN CO.IntMessageType = '05MA01'
							THEN 'NA'
							WHEN FC.Amount = I.OriginalAmount
							THEN 'No'
							WHEN FC.Amount <> I.OriginalAmount
							THEN 'Yes'
							ELSE 'NA'
						END																			AS [Amount Adjusted?],
						FC.AdjustmentReason															AS [Adjustment Reason Code],
						AdjRsn.AdjustmentReason														AS [Adjustment Reason],
						CASE
							WHEN [AdjRej01MA02ES].[EntityState] IN
									(
										SELECT
											EntityState
										FROM
											[ReferenceData].[EntityExtractFilter] WITH (SNAPSHOT)
										WHERE
											[FilterKey] = 'AGYADJ'
									)
							OR	[AdjRej01MA04ES].[EntityState] IN
									(
										SELECT
											EntityState
										FROM
											[ReferenceData].[EntityExtractFilter] WITH (SNAPSHOT)
										WHERE
											[FilterKey] = 'AGYADJ'
									)
							OR	[AdjRej03MA02ES].[EntityState] = 140
							THEN 1
							ELSE NULL
						END																			AS [Item Adjusted],
						CASE
							WHEN (
									[SubmittedES].[IntMessageType] = '01MA06'
							AND		[SubmittedES].[EntityState] IN
										(
											SELECT
												EntityState
											FROM
												[ReferenceData].[EntityExtractFilter] WITH (SNAPSHOT)
											WHERE
												[FilterKey] = 'MSG01'
										)
								)
							OR
								(
									[SubmittedES].[IntMessageType] = '01MA05'
							AND		[SubmittedES].[EntityState] IN ( 82 )
								)
							OR
								(
									[SubmittedES].[IntMessageType] = '05MA03'
							AND		[SubmittedES].[EntityState] IN
										(
											SELECT
												EntityState
											FROM
												[ReferenceData].[EntityExtractFilter] WITH (SNAPSHOT)
											WHERE
												[FilterKey] = 'MSG05'
										)
								)
							THEN 1
							ELSE NULL
						END																			AS [Item Submitted]
					FROM
						@EligibleISOMSG01Tsets				AS ETSET
					INNER JOIN
						[Base].[TXSet]						AS TX
					ON
						ETSET.TransactionSetIdWithVersion = TX.TransactionSetId
					AND ETSET.InternalTxId = TX.InternalTxId
					INNER JOIN
						Base.FinalCredit					AS FC
					ON
						TX.TransactionSetId = FC.TransactionSetId
					LEFT JOIN
						Lookup.ItemType						AS ITMTYPE WITH (SNAPSHOT)
					ON
						ITMTYPE.Id = FC.ItemType
					LEFT JOIN
						Base.ItemUpdate						AS U WITH (SNAPSHOT)
					ON
						FC.ItemId = U.InternalId
					LEFT JOIN
						Base.Core							AS CO WITH (SNAPSHOT)
					ON
						CO.CoreId = U.CoreId
					LEFT JOIN
						Base.Item							AS I WITH (SNAPSHOT)
					ON
						FC.CreditId = I.FCMIdentifier
					LEFT JOIN
						Base.CreditFraudData				AS CRFRD WITH (SNAPSHOT)
					ON
						CRFRD.ItemId = FC.ItemId
					LEFT JOIN
						ReferenceData.APGAdjustmentReasons	AS AdjRsn WITH (SNAPSHOT)
					ON
						FC.AdjustmentReason = AdjRsn.AdjustmentCode
					LEFT JOIN
						#EntityInfo							AS AdjRej01MA02ES
					ON
						FC.CreditId = [AdjRej01MA02ES].[EntityIdentifier]
					AND [AdjRej01MA02ES].[RKD] = 1
					AND [AdjRej01MA02ES].[IntMessageType] = '01MA02'
					AND [AdjRej01MA02ES].[EntityType] = 'I'
					LEFT JOIN
						#EntityInfo							AS AdjRej01MA04ES
					ON
						FC.CreditId = [AdjRej01MA04ES].[EntityIdentifier]
					AND [AdjRej01MA04ES].[RKD] = 1
					AND [AdjRej01MA04ES].[IntMessageType] = '01MA04'
					AND [AdjRej01MA04ES].[EntityType] = 'I'
					LEFT JOIN
						#EntityInfo							AS AdjRej03MA02ES
					ON
						FC.CreditId = [AdjRej03MA02ES].[EntityIdentifier]
					AND [AdjRej03MA02ES].[RKD] = 1
					AND [AdjRej03MA02ES].[IntMessageType] = '03MA02'
					AND [AdjRej03MA02ES].[EntityType] = 'I'
					LEFT JOIN
						#EntityInfo							AS SubmittedES
					ON
						FC.CreditId = [SubmittedES].[EntityIdentifier]
					AND [SubmittedES].[RKD] = 1
					AND [SubmittedES].[IntMessageType] IN ( '01MA05',
															'01MA06',
															'05MA03'
														)
					AND [SubmittedES].[EntityType] = 'I'
					LEFT OUTER JOIN
						ReferenceData.AgencyIdentifiers		AS AI WITH (SNAPSHOT)
					ON
						AI.AgencyParticipantId = FC.CollectingParticipantId
					LEFT JOIN
						[ReferenceData].[RejectionReasons]	AS RR WITH (SNAPSHOT)
					ON
						I.cf_NoPaySuspectRsn = RR.RejectionReasonDescription
					LEFT JOIN
						[ReferenceData].[RejectionReasons]	AS REJ60 WITH (SNAPSHOT)
					ON
						FC.FinalclearingState = REJ60.RejectionReasonCode
					AND REJ60.RejectionReasonDescription = 'Withdrawn after Fraud'
					LEFT JOIN
						[ReferenceData].[RejectionReasons]	AS REJ130 WITH (SNAPSHOT)
					ON
						FC.FinalclearingState = 130
					AND REJ130.RejectionReasonDescription = 'Withdrawn after ICS CI rejection'
					WHERE
						FC.AgencyBeneficiaryParticipantId = @AgencyId
					AND ISNULL(AI.AgencyId, 0) <> @AgencyId;


					-- Clustered index
					CREATE CLUSTERED INDEX nci_TSIDWV_TSETID
					ON #EligibleItems (TransactionSetIdWithVersion, [Transaction Set ID]);

					-- Create filtered index, which will include the clustered index and intersection (test this)
					CREATE NONCLUSTERED INDEX nci_Dup
					ON #EligibleItems (Dup)
					WHERE Dup = 1;


					SELECT
						COUNT(1)	AS ItemsCount,
						COUNT(	CASE
									WHEN Gender = 'CREDIT'
									AND [Item Submitted] = 1
									THEN 1
									ELSE NULL
								END
							)	AS SubmittedCredItemCount,
						COUNT(	CASE
									WHEN Gender = 'DEBIT'
									AND [Item Submitted] = 1
									THEN 1
									ELSE NULL
								END
							)	AS SubmittedDebItemCount,
						SUM(CASE
									WHEN Gender = 'CREDIT'
									AND [Item Submitted] = 1
									THEN CONVERT(NUMERIC(9, 2), [Submitted Amount])
									ELSE NULL
							END
						)		AS SubmittedCredItemValue,
						0.00		AS DispersalValue,
						0			AS SubmittedDispersalVolume,
						COUNT(	CASE
									WHEN [Item Rejected?] = 'Yes'
									THEN 1
									ELSE NULL
								END
							)	AS RejectedItemCount,
						SUM(CASE
									WHEN [Item Rejected?] = 'Yes'
									THEN CONVERT(NUMERIC(9, 2), [Submitted Amount])
									ELSE NULL
							END
						)		AS RejectedItemValue,
						COUNT(	CASE
									WHEN [Item Adjusted] = 1
									AND [Item Rejected?] = 'No'
									THEN 1
									ELSE NULL
								END
							)	AS AdjustedItemCount
					INTO
						#HeaderRecord
					FROM
						#EligibleItems
					WHERE
						Dup = 1;

					SELECT
						[Result].[RowValue]
					FROM
						(
							SELECT
								'Filename,Date,FileVolume,Submitted Credit Volume,Submitted Debit Volume,Submitted Credit Value,Dispersal Value,Submitted Dispersal Volume,Rejected Volume,Rejected Value,Adjusted Volume'	+ REPLICATE(',', 16) AS RowValue,
								1																																																				AS RNO,
								'1'																																																				AS [Transaction Set ID],
								'1'																																																				AS [Gender],
								'1'																																																				AS [Item Type],
								'1'																																																				AS [Item ID]
							UNION ALL
							SELECT
								(
									SELECT
										@FileName	+ ',' + @HeaderBusinessDate + ',' + RIGHT('00000' + CONVERT(VARCHAR, ISNULL([A].[ItemsCount], 0)), 5) + ',' + RIGHT('00000' + CONVERT(VARCHAR, ISNULL([A].[SubmittedCredItemCount], 0)), 5) + ',' + RIGHT('00000' + CONVERT(VARCHAR, ISNULL([A].[SubmittedDebItemCount], 0)), 5) + ',' + CONVERT(VARCHAR, ISNULL([A].[SubmittedCredItemValue], 0.00)) + ',' + CONVERT(VARCHAR, ISNULL([A].[DispersalValue], 0.00)) + ',' + RIGHT('00000' + CONVERT(VARCHAR, ISNULL([A].[SubmittedDispersalVolume], 0)), 5) + ',' + RIGHT('00000' + CONVERT(VARCHAR, ISNULL([A].[RejectedItemCount], 0)), 5) + ',' + CONVERT(VARCHAR, ISNULL([A].[RejectedItemValue], 0.00)) + ',' + RIGHT('00000' + CONVERT(VARCHAR, ISNULL([A].[AdjustedItemCount], 0)), 5) + REPLICATE(',', 16)
								)	AS RowValue,
								2	AS RNO,
								'2' AS [Transaction Set ID],
								'2' AS [Gender],
								'2' AS [Item Type],
								'2' AS [Item ID]
							FROM
								(
									SELECT	TOP 1
											[ItemsCount],
											[SubmittedCredItemCount],
											[SubmittedDebItemCount],
											[SubmittedCredItemValue],
											[DispersalValue],
											[SubmittedDispersalVolume],
											[RejectedItemCount],
											[RejectedItemValue],
											[AdjustedItemCount]
									FROM
											#HeaderRecord
								) AS A
							UNION ALL
							SELECT
								REPLICATE(',', 25)	AS RowValue,
								3					AS RNO,
								'3'					AS [Transaction Set ID],
								'3'					AS [Gender],
								'3'					AS [Item Type],
								'3'					AS [Item ID]
							UNION ALL
							SELECT
								'Transaction Set ID,Collecting Participant ID,Collecting Branch Location,Collecting Location,Collecting Channel,Gender,Item ID,Item Type,Transaction Code,Reference / Serial,Sort Code,Account Number,Original Amount,Submitted Amount,Cash Amount,Funded Amount,Non-Funded Amount,Beneficiary Name,Represented Flag,Item Rejected?,Rejection Reason Code,Rejection Reason,Amount Adjusted?,Adjustment Reason Code,Adjustment Reason'	AS RowValue,
								4																																																																																																										AS RNO,
								'4'																																																																																																										AS [Transaction Set ID],
								'4'																																																																																																										AS [Gender],
								'4'																																																																																																										AS [Item Type],
								'4'																																																																																																										AS [Item ID]
							UNION ALL
							SELECT
								(
									SELECT
										CONCAT	([Transaction Set ID], ',', [Collecting Participant ID], ',', [Collecting Branch Location], ',', [Collecting Location], ',', [Collecting Channel], ',', [A].[Gender], ',', [Item ID], ',', [Item Type], ',', [Transaction Code], ',', [A].[Reference / Serial], ',', [A].[Sort Code], ',', [A].[Account Number], ',', [A].[Original Amount], ',', [A].[Submitted Amount], ',', [A].[Cash Amount], ',', [A].[Funded Amount], ',', [A].[Non-Funded Amount], ',', [A].[Beneficiary Name], ',', [A].[Represented Flag], ',', [A].[Item Rejected?], ',', [A].[Rejection Reason Code], ',', [A].[Rejection Reason], ',', [A].[Amount Adjusted?], ',', [Adjustment Reason Code], ',', [Adjustment Reason])
								)	AS RowValue,
								5	AS RNO,
								[Transaction Set ID],
								[A].[Gender],
								[Item Type],
								[Item ID]
							FROM
								(
									SELECT
										[Dup],
										[TxSetVrsn],
										[DebitCount],
										[Gender],
										[Reference / Serial],
										[Sort Code],
										[Account Number],
										[Original Amount],
										[Submitted Amount],
										[Cash Amount],
										[Funded Amount],
										[Non-Funded Amount],
										[Beneficiary Name],
										[Represented Flag],
										[Item Rejected?],
										[Rejection Reason],
										[Rejection Reason Code],
										[Amount Adjusted?],
										[Item Adjusted],
										[Item Submitted]
									FROM
										#EligibleItems
									WHERE
										Dup = 1
								) AS A
						) AS Result
					ORDER BY
						[Result].[RNO],
						[Result].[Transaction Set ID],
						[Result].[Gender],
						[Result].[Item Type],
						[Result].[Item ID];
				END;
			IF (XACT_STATE()) = 1
				BEGIN
					COMMIT	TRANSACTION;
				END;
		END TRY
		BEGIN CATCH
			IF (XACT_STATE()) = -1
				BEGIN
					ROLLBACK TRANSACTION;
				END;
		END CATCH;
	END;
GO

GRANT
	EXECUTE
ON [Agency].[usp_ReturnAgencyISOMSG01MSG05CSV]
TO
	AgencyISOMsgExtractor;
GO

EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'STAR',
	@level0type = N'SCHEMA',
	@level0name = N'Agency',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReturnAgencyISOMSG01MSG05CSV';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This Stored Procedure extracts MSG01 and MSG05 items in CSV fomrat for a given AgencyId.',
	@level0type = N'SCHEMA',
	@level0name = N'Agency',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReturnAgencyISOMSG01MSG05CSV';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Agency',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReturnAgencyISOMSG01MSG05CSV';