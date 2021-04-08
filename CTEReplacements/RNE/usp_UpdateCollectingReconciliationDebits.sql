CREATE PROCEDURE [DataImport].[usp_UpdateCollectingReconciliationDebits]
	(
		@BusinessDate		DATE,
		@PrevBusinessDate	DATE
	)
/*****************************************************************************************************
* Name				: [DataImport].[usp_UpdateCollectingReconciliationDebits] 
* Description		: This stored procedure UPDATEs Collecting reconcilation reports data for Debit items
* Type of Procedure : Interpreted stored procedure
* Author			: Reddy Akuri
* Creation Date		: 10/10/2017
* Last Modified		: N/A
*******************************************************************************************************/
AS -- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
	BEGIN TRY
		BEGIN

			DECLARE @BusinessDateInt	INT = CAST(CONVERT(VARCHAR, @BusinessDate, 112) AS INT);
			DECLARE @PrevBusinessDateInt INT = CAST(CONVERT(VARCHAR, @PrevBusinessDate, 112) AS INT);

			SELECT
				R.DebitId,
				ISNULL(MAX(ICSAmount), 0) AS ICSAmount,
				MAX(MSG01)					AS MSG01,
				MAX([R].[MSG02])			AS MSG02,
				MAX([R].[MSG03])			AS MSG03
			INTO
				#EligibleItems
			FROM
				(
					SELECT
						DebitId,
						ICSAmount,
						ROW_NUMBER() OVER (PARTITION BY
											DebitId
											ORDER BY
											Revision DESC
										) AS Rnk,
						MSG01,
						0					AS MSG02,
						0					AS MSG03
					FROM
						[Report].dimDebitEntityStateHistory
					WHERE
						DateKey = @BusinessDateInt
					AND EntityType = 'I'
					AND MSG01 > 0
					UNION ALL
					SELECT
						DebitId,
						ICSAmount,
						ROW_NUMBER() OVER (PARTITION BY
											DebitId
											ORDER BY
											Revision DESC
										) AS Rnk,
						0					AS MSG01,
						MSG02,
						0					AS MSG03
					FROM
						[Report].dimDebitEntityStateHistory
					WHERE
						DateKey = @BusinessDateInt
					AND MSG02 > 0
					UNION ALL
					SELECT
						DebitId,
						ICSAmount,
						ROW_NUMBER() OVER (PARTITION BY
											DebitId
											ORDER BY
											Revision DESC
										) AS Rnk,
						0					AS MSG01,
						0					AS MSG02,
						MSG03
					FROM
						[Report].dimDebitEntityStateHistory
					WHERE
						DateKey = @BusinessDateInt
					AND EntityType = 'I'
					AND MSG03 > 0
				)									AS R
			LEFT JOIN
				Report.dimChannelCollectionRecon	AS CR
			ON
				CR.ItemTransID = R.DebitId
			AND CR.IsOutclearingOut = 1
			LEFT JOIN
				Report.dimChannelCollectionRecon	AS CR1
			ON
				CR1.ItemTransID = R.DebitId
			AND CR1.IsWithdrawn = 1
			WHERE
				[R].[Rnk] = 1
			AND CR.ItemTransID IS NULL
			AND CR1.ItemTransID IS NULL
			GROUP BY
				R.DebitId;

			SELECT
				I.DebitId,
				I.DateKey,
				DebitEntryDate,
				ROW_NUMBER() OVER (PARTITION BY
									I.DebitId
									ORDER BY
									EntityId DESC
								) AS EntRank
			INTO
				#OutclearingIn
			FROM
				[Report].[dimDebitEntityStateHistory]	AS I
			INNER JOIN
				#EligibleItems							AS EI
			ON
				EI.DebitId = I.DebitId
			WHERE
				I.MSG01 IN ( 20,
							21,
							23	,
							25
						)
			AND EntityType = 'I';

			SELECT
				I.DebitId,
				ROW_NUMBER() OVER (PARTITION BY
									I.DebitId
									ORDER BY
									EntityId DESC
								) AS EntRank,
				EntityState
			INTO
				#MAX_Revision
			FROM
				[Report].[dimDebitEntityStateHistory]	AS I
			INNER JOIN
				#EligibleItems							AS EI
			ON
				EI.DebitId = I.DebitId
			WHERE
				I.DateKey = @BusinessDateInt
			AND EntityType = 'I';

			SELECT
				DR	.DebitId,
				TS.AltSource
			INTO
				#Txns
			FROM
				#EligibleItems				AS DR
			INNER JOIN
				Report.factDebitAmounts		AS FC
			ON
				DR.DebitId = FC.DebitId
			INNER JOIN
				Report.dimTransactionSet	AS TS
			ON
				TS.TransactionSetId = FC.TransactionSetKey
			WHERE
				TS.AltSource IS NOT NULL
			GROUP BY
				DR.DebitId,
				TS.AltSource;

			MERGE Report.dimChannelCollectionRecon AS EFC
			USING
				(
					SELECT
						CR	.DebitId,
						TS.AltSource																								AS Channel,
						--Entity state of MSG01 in 20 or 21 then Outclearing in
						IIF(OI.DebitId IS NOT NULL AND OI.DebitEntryDate = @BusinessDate, 1, 0)							AS IsOutclearingIn,
						--Final entity state for the day in 165
						IIF(MR.DebitId IS NOT NULL AND MR.EntityState = 165, 1, 0)												AS IsHoldover,
						--Final entity state for the day in  130
						IIF(MR.DebitId IS NOT NULL AND MR.EntityState IN ( 30, 60, 130 ), 1, 0)							AS IsWithdrawn,
						--Final entity state for the day in  100
						IIF(OI.DebitId IS NOT NULL AND [CR].[MSG02] = 100 AND MR.EntityState NOT IN ( 30, 60, 130, 165 ), 1, 0) AS IsOutclearingOut,
						FC.OriginalAmount																							AS OriginalAmount,
						FC.Amount																									AS Amount,
						MR.EntityState,
						IIF(([CR].[ICSAmount] = 0 OR [CR].[ICSAmount] IS NULL), 0, 1)											AS IsItemSubmitToSwitch
					FROM
						#EligibleItems			AS CR
					INNER JOIN
						Report.factDebitAmounts AS FC
					ON
						CR.DebitId = FC.DebitId
					INNER JOIN
						#Txns					AS TS
					ON
						TS.DebitId = FC.DebitId
					LEFT JOIN
						#OutclearingIn			AS OI
					ON
						OI.DebitId = CR.DebitId
					AND [OI].[EntRank] = 1
					LEFT JOIN
						#MAX_Revision			AS MR
					ON
						MR.DebitId = CR.DebitId
					AND [MR].[EntRank] = 1
				) AS NFC
				(DebitId, Channel, IsOutclearingIn, IsHoldover, IsWithdrawn, IsOutclearingOut, OriginalAmount, Amount, FinalEntityState, IsItemSubmitToSwitch)
			ON EFC.ItemTransID = NFC.DebitId
			AND EFC.Channel = NFC.Channel
			AND EFC.FullDate = @BusinessDate
			WHEN MATCHED
			THEN UPDATE SET
					IsOutclearingIn = NFC.IsOutclearingIn,
					IsOutclearingOut = NFC.IsOutclearingOut,
					IsHoldover = NFC.IsHoldover,
					IsNextDayHoldover = NFC.IsHoldover,
					IsWithdrawn = NFC.IsWithdrawn,
					OriginalAmount = ISNULL(NFC.OriginalAmount, 0),
					FinalAmount = ISNULL(NFC.Amount, 0),
					FinalEntityState = NFC.FinalEntityState,
					IsItemSubmitToSwitch = NFC.IsItemSubmitToSwitch
			WHEN NOT MATCHED
			THEN INSERT
					(
						ItemTransID,
						FullDate,
						Channel,
						IsOutclearingIn,
						IsHoldover,
						IsNextDayHoldover,
						IsWithdrawn,
						IsOutclearingOut,
						OriginalAmount,
						FinalAmount,
						CrDbInd,
						FinalEntityState,
						IsItemSubmitToSwitch
					)
				VALUES
					(
						NFC.DebitId, @BusinessDate, NFC.Channel, NFC.IsOutclearingIn, NFC.IsHoldover, NFC.IsHoldover, NFC.IsWithdrawn, NFC.IsOutclearingOut, ISNULL(NFC.OriginalAmount, 0), ISNULL(NFC.Amount, 0), 'Db', NFC.FinalEntityState, NFC.IsItemSubmitToSwitch
					);

			-- Update Previous Day Holdover
			UPDATE
				CR
			SET
			CR	.IsPrevDayHoldover = 1
			FROM
				[Report].dimChannelCollectionRecon	AS CR
			INNER JOIN
				(
					SELECT
						ItemTransID
					FROM
						[Report].dimChannelCollectionRecon
					WHERE
						FullDate = @PrevBusinessDate
					AND IsNextDayHoldover = 1
					AND CrDbInd = 'Db'
				)									AS DR
			ON
				DR.ItemTransID = CR.ItemTransID
			WHERE
				CR.FullDate = @BusinessDate
			AND CrDbInd = 'Db';

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
ON [DataImport].[usp_UpdateCollectingReconciliationDebits]
TO
	[RnEReportDwDataImporter];

GO

EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'DataImport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_UpdateCollectingReconciliationDebits';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This stored procedure UPDATEs Collecting reconcilation reports data',
	@level0type = N'SCHEMA',
	@level0name = N'DataImport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_UpdateCollectingReconciliationDebits';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'RnEReportDataWarehouse',
	@level0type = N'SCHEMA',
	@level0name = N'DataImport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_UpdateCollectingReconciliationDebits';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Calling Application',
	@value = N'IPSL.RNE.RefreshDataWarehouse.dtsx',
	@level0type = N'SCHEMA',
	@level0name = N'DataImport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_UpdateCollectingReconciliationDebits';

GO