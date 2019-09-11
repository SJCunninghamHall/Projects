/****************************************************************************************
* Stored Procedure:[WAR].[usp_ReceivedDefaultItems]
* Description: Create Received Default Items Report-Contains an item that we have received in MSG06 and MSG05 Where the collecting bank
               have applied Default Sortcode for the item and APG operator will amend and input the correct codeline detail for the item.
* Sort Order : Collecting Participant
* Amendment History
***************************************************************************************** 
* Version		Name						Date               Reason
* 1.3.0			Mazar Shaik				    02 Aug 2017        Create Received Default Items
*****************************************************************************************/
CREATE PROCEDURE [WAR].[usp_ReceivedDefaultItems]
	@BusinessDate	VARCHAR(8)
AS
	BEGIN TRY
		BEGIN

			SET NOCOUNT ON;
			SET XACT_ABORT ON;

			SELECT	DISTINCT
					ParticipantID,
					Participantname
			INTO
					#ParticipantDetails
			FROM
					[Report].[dimParticipantData];

			CREATE NONCLUSTERED INDEX nci_ParticipantID
			ON #ParticipantDetails (ParticipantID);

			SELECT
				ReceivedDefaultItems.[Collecting Participant],
				ReceivedDefaultItems.UIN,
				ReceivedDefaultItems.[Correct SortCode],
				ReceivedDefaultItems.[Correct Account Number],
				ReceivedDefaultItems.[Serial Number/Reference],
				ReceivedDefaultItems.[CR Value],
				[ReceivedDefaultItems].[DR Value]
			FROM
				(
					SELECT
						PD	.ParticipantName AS [Collecting Participant],
						CR.CreditId			AS UIN,
						CR.Sortcode			AS [Correct SortCode],
						CR.AccountNumber	AS [Correct Account Number],
						CR.Reference		AS [Serial Number/Reference],
						Tst.Amount			AS [CR Value],
						0					AS [DR Value]
					FROM
						Report.dimDebitInformation	AS DR
					INNER JOIN
						[Report].[factDebitAmounts] AS Amt
					ON
						DR.DebitId = Amt.DebitId
					INNER JOIN
						[Report].factCreditAmounts	AS Tst
					ON
						Tst.TransactionSetKey = Amt.TransactionSetKey
					INNER JOIN
						Report.dimCreditInformation AS CR
					ON
						CR.CreditId = Tst.CreditId
					INNER JOIN
						Report.vw_DimTransactionSet AS DT
					ON
						DT.TransactionSetId = Tst.TransactionSetKey
					INNER JOIN
						ParticipantDetails			AS PD
					ON
						PD.ParticipantID = DT.CollectingParticipantId
					WHERE
						CR.Sortcode != CR.OriginalSortcode
					AND CR.DefaultedSortcode = 1
					AND DR.SettlementDate = @BusinessDate
					GROUP BY
						CR.CreditId,
						CR.Sortcode,
						CR.AccountNumber,
						CR.Reference,
						Tst.Amount,
						PD.ParticipantName
					UNION ALL
					SELECT
						PD	.ParticipantName			AS [Collecting Participant],
						DR.DebitId						AS UIN,
						DR.Sortcode						AS [Correct SortCode],
						DR.AccountNumber				AS [Correct Account Number],
						CONVERT(VARCHAR(10), DR.Serial) AS [Serial Number/Reference],
						0								AS [CR Value],
						Amt.Amount						AS [DR Value]
					FROM
						Report.dimDebitInformation	AS DR
					INNER JOIN
						[Report].[factDebitAmounts] AS Amt
					ON
						DR.DebitId = Amt.DebitId
					INNER JOIN
						Report.vw_DimTransactionSet AS DT
					ON
						DT.TransactionSetId = Amt.TransactionSetKey
					INNER JOIN
						ParticipantDetails			AS PD
					ON
						PD.ParticipantID = DT.CollectingParticipantId
					WHERE
						DR.Sortcode != DR.OriginalSortcode
					AND DR.DefaultedSortcode = 1
					AND DR.SettlementDate = @BusinessDate
				) AS ReceivedDefaultItems
			ORDER BY
				[Collecting Participant];

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
ON [WAR].[usp_ReceivedDefaultItems]
TO
	[RnEWAR];
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'RnEReportDataWarehouse',
	@level0type = N'SCHEMA',
	@level0name = N'WAR',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReceivedDefaultItems';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Create Received Default Items Report-Contains an item that we have received in MSG06 and MSG05 Where the collecting bank 
	         have applied Default Sortcode for the item and APG operator will amend and input the correct codeline detail for the item.',
	@level0type = N'SCHEMA',
	@level0name = N'WAR',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReceivedDefaultItems';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'WAR',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReceivedDefaultItems';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Calling Application',
	@value = N'iPSL.RNE.WARReceivedDefaultItems.dtsx',
	@level0type = N'SCHEMA',
	@level0name = N'WAR',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReceivedDefaultItems';

GO




