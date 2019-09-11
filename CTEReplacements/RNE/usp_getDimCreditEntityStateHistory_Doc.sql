CREATE PROCEDURE [RNEReport].[usp_getDimCreditEntityStateHistory_Doc]
	@BusinessDateRangeStart BIGINT,
	@BusinessDateRangeEnd	BIGINT
/*****************************************************************************************************
* Name				: [RNEReport].[usp_getDimCreditEntityStateHistory_Doc]
* Description		: This stored procedure exports the data for dimCreditEntityStateHistory from STAR to RnEReportDataWarehouse.
* Type of Procedure : Interpreted stored procedure 
* Author			: Mahesh Kumar Suragani
* Creation Date		: 13/07/2018
* Last Modified		: N/A
*******************************************************************************************************/
AS
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

	BEGIN

		SELECT
			EntityType						AS EntityType,
			TX2.TransactionSetIdWithVersion AS TransactionSetIdWithVersion,
			DocD2.DocumentMessageId			AS DocumentMessageId,
			CrD2.CreditId					AS EntityIdentifier,
			En.EntityId						AS EntityId,
			En.Revision						AS Revision,
			EntityState						AS EntityState,
			CAST(CASE
					WHEN ISNUMERIC(RIGHT(Co.IntMessageType, 2)) = 1
					THEN RIGHT(Co.IntMessageType, 2)
					ELSE RIGHT(Co.IntMessageType, 1)
				END AS TINYINT)				AS IntMessageTypeSeq,
			Co.IntMessageType				AS IntMessageType,
			CASE
				WHEN MsgType.MessageType = 'PSTNG'
				THEN IntMessageType
				ELSE MsgType.MessageType
			END								AS MessageType
		INTO
			#EntInternal
		FROM
			Base.Core			AS Co
		--EntityType = 'I'
		INNER JOIN
			Lookup.MessageType	AS MsgType
		ON
			Co.MessageType = MsgType.MessageId
		INNER JOIN
			Base.Entity			AS En
		ON
			En.CoreId = Co.CoreId
		--EntityType = 'D' AND MessageType IN ('MSG02')
		LEFT JOIN
			Base.vw_Document	AS DocD2
		ON
			DocD2.DocumentMessageId = En.EntityIdentifier
		LEFT JOIN
			Base.vw_TXSet		AS TX2
		ON
			TX2.DocumentId = DocD2.DocumentId
		LEFT JOIN
			Base.FinalCredit	AS CrD2
		ON
			CrD2.TransactionSetId = TX2.TransactionSetId
		WHERE
			En.EntityId
		BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd
		AND En.EntityType = 'D';

		CREATE NONCLUSTERED INDEX nci_EntityIdentifier
		ON #EntInternal (EntityIdentifier);

		SELECT
			EntityIdentifier
		INTO
			#UniqueItem
		FROM
			#EntInternal
		GROUP BY
			EntityIdentifier;

		CREATE NONCLUSTERED INDEX nci_EntityIdentifier
		ON #UniqueItem (EntityIdentifier);

		SELECT
			ItemId	,
			FraudReason,
			FraudResult,
			vc.IntMessageType,
			lm.MessageType,
			ROW_NUMBER() OVER (PARTITION BY
								frsr.ItemId,
								vc.IntMessageType
								ORDER BY
								frsr.FraudStatusId DESC
							) AS Rnk
		INTO
			#tempFrdResult
		FROM
			Base.vw_Core			AS vc
		INNER JOIN
			Base.FraudStatus		AS FS
		ON
			vc.CoreId = FS.CoreId
		INNER JOIN
			Base.FraudStatusResults AS frsr
		ON
			FS.FraudStatusId = frsr.FraudStatusId
		INNER JOIN
			#UniqueItem				AS it
		ON
			frsr.ItemId = it.EntityIdentifier
		INNER JOIN
			Lookup.MessageType		AS lm
		ON
			lm.MessageId = vc.MessageType;

		CREATE NONCLUSTERED INDEX nci_EI_MT_RNK
		ON #tempFrdResult (ItemId, MessageType, Rnk);

		SELECT
			i.FCMIdentifier,
			i.cf_NoPaySuspectRsn,
			i.cf_DeferredPosting,
			i.cf_BrandID,
			i.cf_ICSTransactionID,
			i.cf_LocationID,
			i.APGDIN,
			i.Comments,
			i.APGBusinessDate,
			i.RejectReason,
			i.ReturnReason,
			i.TransactionNumber,
			i.DebitReference	AS DebitReference,
			i.cf_SourceID,
			i.JGAccount,
			c.IntMessageType,
			lm.MessageType,
			i.AdjustmentReason,
			i.cf_ChnlInsertReason,
			i.cf_ImageDateTime,
			i.cf_NPASortCode,
			i.Process,
			ROW_NUMBER() OVER (PARTITION BY
								i.FCMIdentifier,
								c.IntMessageType
								ORDER BY
								i.ItemId DESC
							) AS Rnk
		INTO
			#Item
		FROM
			Base.Item			AS i
		INNER JOIN
			Base.Core			AS c
		ON
			i.CoreId = c.CoreId
		INNER JOIN
			#UniqueItem			AS it
		ON
			i.FCMIdentifier = it.EntityIdentifier
		INNER JOIN
			Lookup.MessageType	AS lm
		ON
			lm.MessageId = c.MessageType;

		CREATE NONCLUSTERED INDEX nci_CreditId_Rnk_MessageType
		ON #Item (FCMIdentifier, Rnk, MessageType);

		-- ;WITH ItemsEntitiesCTE
		-- AS
		-- (	
		SELECT
			EntityIdentifier			AS EntityIdentifier,
			EntityType					AS EntityType,
			TransactionSetIdWithVersion AS TransactionSetIdWithVersion,
			DocumentMessageId			AS DocumentMessageId,
			[ENT].[MessageType]			AS MessageType,
			IntMessageType				AS IntMessageType,
			EntityState					AS EntityState,
			EntityId					AS EntityId,
			Revision					AS Revision
		INTO
			#ItemsEntities
		FROM
			(
				SELECT
					EntityIdentifier			AS EntityIdentifier,
					EntityType					AS EntityType,
					TransactionSetIdWithVersion AS TransactionSetIdWithVersion,
					DocumentMessageId			AS DocumentMessageId,
					MessageType					AS MessageType,
					IntMessageType				AS IntMessageType,
					EntityState					AS EntityState,
					EntityId					AS EntityId,
					Revision					AS Revision,
					ROW_NUMBER() OVER (PARTITION BY
										EntityType,
										EntityIdentifier,
										MessageType,
										IntMessageType
										ORDER BY
										Revision DESC,
										EntityId DESC
									)		AS RKD
				FROM
					#EntInternal
				WHERE
					EntityIdentifier IS NOT NULL
			) AS ENT
		WHERE
			[ENT].[RKD] = 1;

		CREATE NONCLUSTERED INDEX nci_EntityIdentifier
		ON #ItemsEntities (EntityIdentifier);
		CREATE NONCLUSTERED INDEX nci_MessageType
		ON #ItemsEntities (MessageType);

		SELECT
			CAST(LEFT(COALESCE(IMC.EntityId, FD.ItemId), 8) AS INT) AS DateKey,
			FD.CreditID												AS CreditId,
			COALESCE(IMC.EntityId, FD.ItemId)						AS EntityId,
			COALESCE(IMC.Revision, 0)							AS Revision,
			U.OperatorId											AS OperatorId,
			ISNULL(FD.AccountNumber, 0)								AS AccountNumber,
			ISNULL(FD.Sortcode, 0)									AS Sortcode,
			FD.Reference											AS Reference,
			CASE
				WHEN MultiDebitInd.CreditID IS NOT NULL
				THEN 1
				ELSE 0
			END														AS isMultiDebit,
			FD.DefaultedSortcode									AS DefaultedSortcode,
			itmtyp.ItemTypeCode										AS ItemType,
			CAST(LEFT(EntryDateCredit.EntryItemId, 8) AS DATE) AS CreditEntryDate,
			CAST(LEFT(HoldoverItemEntry.EntityId, 8) AS DATE)	AS CreditHoldoverEntryDate,
			EntryDateCredit.OriginalSortcode						AS OriginalSortcode,
			I.cf_NoPaySuspectRsn									AS cf_NoPaySuspectRsn,
			CAST(COALESCE(IMC.EntityState, 0) AS SMALLINT) AS EntityState,
			IMC.IntMessageType										AS IntMessageType,
			[IMC].[MessageType]										AS MessageType,
			I.cf_DeferredPosting									AS cf_DeferredPosting,
			I.cf_BrandID											AS cf_BrandID,
			IMC.EntityType											AS EntityType,
			FD.TSetIDWithVersion									AS TransactionSetIdWithVersion,
			IMC.DocumentMessageId									AS DocumentMessageId,
			I.cf_ICSTransactionID									AS cf_ICSTransactionID,
			I.cf_LocationID											AS cf_LocationID,
			CASE
				WHEN [I].[AdjustmentReason] IS NOT NULL
				THEN [I].[AdjustmentReason]
				ELSE [FD].[AdjustmentReason]
			END														AS [AdjustmentReason],
			I.APGDIN												AS APGDIN,
			FD.NoPayReason											AS NoPayReason,
			FD.TranCode												AS TranCode,
			I.Comments												AS Comments,
			I.APGBusinessDate										AS APGBusinessDate,
			I.RejectReason											AS RejectReason,
			I.ReturnReason											AS ReturnReason,
			I.TransactionNumber										AS TransactionNumber,
			FD.EISCDPayingParticipantId								AS EISCDPayingParticipantId,
			I.JGAccount												AS JGAccount,
			I.cf_SourceID											AS cf_SourceID,
			FD.CollectingParticipantId								AS CollectingParticipantId,
			FD.ICSAmount											AS ICSAmount,
			fr.FraudReason											AS KappaFraudReason,
			fr.FraudResult											AS KappaFraudResult,
			I.cf_ChnlInsertReason,
			I.cf_ImageDateTime,
			I.cf_NPASortCode,
			I.Process
		FROM
			#ItemsEntities		AS IMC
		INNER JOIN
			Base.FinalCredit	AS FD
		ON
			FD.CreditID = IMC.EntityIdentifier
		INNER JOIN
			Lookup.ItemType		AS itmtyp
		ON
			FD.ItemType = itmtyp.Id
		LEFT JOIN
			#Item				AS I
		ON
			FD.CreditID = I.FCMIdentifier
		AND [I].[Rnk] = 1
		AND I.MessageType = [IMC].[MessageType]
		LEFT JOIN
			Base.ItemUpdate		AS U
		ON
			FD.ItemUpdateId = U.InternalId
		LEFT JOIN
			#tempFrdResult		AS fr
		ON
			fr.ItemId = IMC.EntityIdentifier
		AND fr.MessageType = [IMC].[MessageType]
		AND [fr].[Rnk] = 1
		LEFT JOIN
			(
				SELECT
					CreditId	AS CreditId
				FROM
					Base.FinalCredit	AS FC
				INNER JOIN
					Base.FinalDebit		AS FD
				ON
					FC.TransactionSetId = FD.TransactionSetId
				WHERE
					(
						FD.FinalOutClearingState != 25
				OR		FD.FinalOutClearingState IS NULL
					)
				GROUP BY
					CreditId
				HAVING
					COUNT(1) > 1
			)					AS MultiDebitInd
		ON
			MultiDebitInd.CreditID = FD.CreditID
		LEFT JOIN
			(
				SELECT
					EntryItemId			AS EntryItemId,
					CreditId			AS CreditId,
					OriginalSortcode	AS OriginalSortcode
				FROM
					(
						SELECT
							ItemId				AS EntryItemId,
							CreditId			AS CreditId,
							Sortcode			AS OriginalSortcode,
							ROW_NUMBER() OVER (PARTITION BY
												CreditId
												ORDER BY
												ItemId ASC
											) AS RKD
						FROM
							Base.Credit
						WHERE
							SortCode IS NOT NULL
					) AS EntryDateCreditInternal
				WHERE
					[EntryDateCreditInternal].[RKD] = 1
			)					AS EntryDateCredit
		ON
			EntryDateCredit.CreditID = FD.CreditID

		-- Holdover Item Date Catpture
		LEFT JOIN
			(
				SELECT
					EntityId							AS EntityId,
					[Day1Entry].[CreditID]				AS CreditID,
					[Day1Entry].[HoldoverDay1EntryRnk]	AS HoldoverDay1EntryRnk
				FROM
					(
						SELECT
							En	.EntityId		AS EntityId,
							EntityType			AS EntityType,
							msg.MessageType		AS MessageType,
							CASE
								WHEN EntityType = 'I'
								THEN EntityIdentifier
								WHEN EntityType = 'T'
								THEN DbT.CreditId
							END					AS CreditID,
							ROW_NUMBER() OVER (PARTITION BY
												CASE
													WHEN EntityType = 'I'
													THEN EntityIdentifier
													WHEN EntityType = 'T'
													THEN DbT.CreditID
												END
												ORDER	BY
												CASE
													WHEN msg.MessageType = 'MSG01'
													THEN En.EntityId
													ELSE 0
												END DESC,
												CASE
													WHEN Co.IntMessageType = '06MA01'
													THEN En.EntityId
													ELSE 0
												END ASC,
												CASE
													WHEN Co.IntMessageType != '06MA01'
													THEN En.EntityId
												END ASC
											) AS HoldoverDay1EntryRnk
						FROM
							Base.Core			AS Co
						INNER JOIN
							Lookup.MessageType	AS msg
						ON
							Co.MessageType = msg.MessageId
						INNER JOIN
							Base.Entity			AS En
						ON
							En.CoreId = Co.CoreId
						LEFT JOIN
							Base.vw_TXSet		AS TXT
						ON
							TXT.TransactionSetIdWithVersion = En.EntityIdentifier
						LEFT JOIN
							Base.Credit			AS DbT
						ON
							TXT.InternalTxId = DbT.InternalTxId
						WHERE
							msg.MessageType IN ( 'MSG01',
												'MSG06'
											)
						AND (CASE
								WHEN EntityType = 'I'
								THEN EntityIdentifier
								WHEN EntityType = 'T'
								THEN DbT.CreditId
							END
							)	IS NOT NULL
						AND En.EntityId
						BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd
					) AS Day1Entry
				WHERE
					HoldoverDay1EntryRnk = 1
			)					AS HoldoverItemEntry
		ON
			[HoldoverItemEntry].[CreditID] = FD.CreditID
		WHERE
			(FD.ItemId
		BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd
			)
		OR	(IMC.EntityId
		BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd
			);

	END;

GO

GRANT
	EXECUTE
ON [RNEReport].[usp_getDimCreditEntityStateHistory_Doc]
TO
	[RNEReportAccess];

GO

EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'RNEReport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_getDimCreditEntityStateHistory_Doc';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This stored procedure exports the data for dimCreditEntityStateHistory from STAR to RnEReportDataWarehouse.',
	@level0type = N'SCHEMA',
	@level0name = N'RNEReport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_getDimCreditEntityStateHistory_Doc';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'STAR',
	@level0type = N'SCHEMA',
	@level0name = N'RNEReport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_getDimCreditEntityStateHistory_Doc';
GO
