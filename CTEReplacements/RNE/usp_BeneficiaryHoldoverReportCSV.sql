CREATE PROCEDURE [RnEWareHouseReports].[usp_BeneficiaryHoldoverReportCSV]
/*****************************************************************************************************
* Name				: [RnEWareHouseReports].[usp_BeneficiaryHoldoverReportCSV]
* Description		: Create Beneficiary Items which are all HolOver for Day One.
* Type of Procedure : Interpreted stored procedure
* Author			: Asish
* Creation Date		: 05/10/2018
* Last Modified		: N/A
*******************************************************************************************************/
AS
	BEGIN TRY

		BEGIN

			DECLARE @ReportNo	VARCHAR(15) = 'Report 62';
			DECLARE @BusinessDate DATE;
			DECLARE @Day2Date DATE;
			DECLARE @ReportID INT;

			SET @ReportID =
				(
					SELECT
						ReportID
					FROM
						Report.dimReportMaster
					WHERE
						ReportNo = @ReportNo
				);
			SET @BusinessDate =
				(
					SELECT
						[FullDate]
					FROM
						[Report].[dimDate]
					WHERE
						isCurrentBusinessDate = 1
				);
			SET @Day2Date =
				(
					SELECT
						NextDate
					FROM
						[Report].[dimDate]
					WHERE
						isCurrentBusinessDate = 1
				);

			SELECT
				DI	.DebitId
			INTO
				#REJItems
			FROM
				[Report].[dimDebitInformation]	AS DI
			INNER JOIN
				Report.dimReportEntityState		AS DE
			ON
				DI.MSG03 = DE.EntityState
			AND DE.MessageType = 'MSG03'
			WHERE
				DE.ReportID = @ReportID
			AND ColumnName = 'RTPHoldover';

			CREATE NONCLUSTERED INDEX nci_DebitId
			ON #REJItems (DebitId);

			SELECT
				DebitId						AS "Item Reference",
				DebitEntryDate				AS "Debit Received Date",
				[A].[Day2Date]				AS "RTP Response Receipt Due Date",
				SettlementDate				AS "RTP Actual Response Date",
				Amount						AS "RTP Value",
				CAST(NULL AS VARCHAR(10)) AS "Pay / No Pay Response",
				CAST(NULL AS VARCHAR(30)) AS "No Pay Reason",
				DP.ParticipantName			AS "Brand or Agency"
			FROM
				(
					SELECT	DISTINCT
							DI.DebitId,
							DI.DebitEntryDate,
							DI.SettlementDate,
							@Day2Date	AS Day2Date,
							FD.Amount,
							DI.Sortcode AS DebitSortCode
					FROM
							Report.factDebitAmounts		AS FD
					INNER JOIN
							Report	.dimDebitInformation AS DI
					ON
						FD.DebitId = DI.DebitId
					INNER JOIN
							Report	.factCreditAmounts	AS fc
					ON
						fc.TransactionSetKey = FD.TransactionSetKey
					INNER JOIN
							Report	.dimCreditInformation AS dc
					ON
						fc.CreditId = dc.CreditId
					INNER JOIN
							Report	.dimParticipantData AS dp
					ON
						dp.SortCode = dc.Sortcode
					AND dp.ONUSFlag = 1
					INNER JOIN
							Report	.dimReportEntityState AS DE
					ON
						(
							(
								DI.MSG04 = DE.EntityState
						AND		DE.MessageType = 'MSG04'
						AND		DE.ReportID = @ReportID -- SJC common to both
						AND		ColumnName = 'RTPHoldover' -- SJC common to both
							)
					OR
						(
							DI.MSG01 = DE.EntityState
					AND		DE.MessageType = 'MSG01'
					AND		DE.ReportID = @ReportID -- SJC common to both
					AND		ColumnName = 'RTPHoldover' -- SJC common to both
						)
						)
					LEFT JOIN
							#REJItems					AS RJ
					ON
						RJ.DebitId = DI.DebitId
					WHERE
							RJ.DebitId IS NULL
					AND dp.ONUSFlag = 1
					AND DI.DebitEntryDate = @BusinessDate
				)							AS A
			INNER JOIN
				Report.dimParticipantData	AS DP
			ON
				DP.SortCode = A.DebitSortCode;
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
ON [RnEWareHouseReports].[usp_BeneficiaryHoldoverReportCSV]
TO
	[RnESsrsDwAccess];

GO

EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_BeneficiaryHoldoverReportCSV';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Create Beneficiary Hold Over Report for Day One',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_BeneficiaryHoldoverReportCSV';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'RnEReportDataWarehouse',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_BeneficiaryHoldoverReportCSV';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Calling Application',
	@value = N'iPSL.RNE.HoldoverBeneficiaryItemsReportCSV.dtsx',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_BeneficiaryHoldoverReportCSV';

GO