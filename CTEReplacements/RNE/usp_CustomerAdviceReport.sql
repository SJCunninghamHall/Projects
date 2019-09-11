CREATE PROCEDURE [RnEWareHouseReports].usp_CustomerAdviceReport
/*****************************************************************************************************************
* Stored Procedure					: [RnEWareHouseReports].[usp_CustomerAdviceReport]
* Author									: Hamid Narikkoden
* Description							: Generates Customer Advice Report
* Creation Date						: 10/05/2018 
* Last Modified						: 18/05/2018
******************************************************************************************************************/
AS
	BEGIN

		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		BEGIN TRY

			BEGIN

				DECLARE
					@ReportId	INT,
					@Date		INT;

				SELECT
					@ReportId	= ReportId
				FROM
					[Report].dimReportMaster AS Rpt
				WHERE
					Rpt.ReportName = 'Report31Day1BranchCustomerAdvices';

				SELECT	TOP 1
						@Date	= DateKey
				FROM
						[Report].dimDate
				WHERE
						isCurrentBusinessDate = 1;

				--if item goes to holdover after 40 then both days Report 31 will have item on both days
				--so if 20/21 check done on the day of the report then previous business date items will be excluded

				SELECT
					Cr	.cf_ICSTransactionID AS ICSTransactionID,
					Cr.CreditId				AS ICSITemID,
					Cr.[Sortcode],
					Cr.[AccountNumber],
					Cr.[Reference],
					Cr.AdjustmentReason		AS AdjustmentCode,
					Cr.APGBusinessDate		AS [PayInDate],
					Cr.[Comments],
					Cr.cf_NoPaySuspectRsn	AS NoPayReason
				INTO
					#EligibleCreditItems
				FROM
					[Report].[dimCreditEntityStateHistory] AS Cr
				WHERE
					DateKey = @Date
				AND EntityState IN ( 20,
									21
								)
				AND EntityType = 'I'
				GROUP BY
					Cr.cf_ICSTransactionID,
					Cr.CreditId,
					Cr.[Sortcode],
					Cr.[AccountNumber],
					Cr.[Reference],
					Cr.AdjustmentReason,
					Cr.APGBusinessDate,
					Cr.[Comments],
					Cr.cf_NoPaySuspectRsn;

				SELECT
					Cr	.ICSTransactionID,
					Cr.ICSITemID,
					Cr.[Sortcode],
					Cr.[AccountNumber],
					Cr.[Reference],
					Cr.AdjustmentCode,
					crAdj.NoPayReason		AS AdjustmentReasonDescription,
					Cr.[PayInDate],
					CrAmnt.[Amount]			AS CurrentAmount,
					CrAmnt.[OriginalAmount] AS OriginalAmount,
					Cr.[Comments],
					Tx.TransactionSetId
				INTO
					#FinalCreditItems
				FROM
					#EligibleCreditItems			AS Cr
				INNER JOIN
					[Report].[factCreditAmounts]	AS CrAmnt
				ON
					Cr.ICSITemID = CrAmnt.CreditId
				INNER JOIN
					[Report].dimTransactionSet		AS Tx
				ON
					Tx.TransactionSetId = CrAmnt.TransactionSetKey
				INNER JOIN
					config.Channel					AS crSrc --Get items related to configured sources menioned in config.channel table i.e., 5000,5100 etc
				ON
					crSrc.ChannelID = Tx.AltSource
				AND crSrc.ReportID = @ReportId
				INNER JOIN
					Config.ReportNoPayReason		AS crAdj -- Gets items that are matching the required adjustment codes
				ON
					crAdj.NoPayReasonCode = Cr.AdjustmentCode
				AND crAdj.ReportID = @ReportId
				AND crAdj.Category = 'Adjustment'
				INNER JOIN
					Config.ReportNoPayReason		AS crNP -- Gets items that are matching the required adjustment codes
				ON
					crNP.NoPayReason = Cr.NoPayReason
				AND crNP.ReportID = @ReportId
				AND crNP.Category = 'NoPay'
				INNER JOIN
					Config.ReportBranchType			AS RpBr -- Gets Branch codes for the report
				ON
					RpBr.ReportId = @ReportId
				INNER JOIN
					Config.[SortCodeBranchType]		AS Br -- Gets items that are matching the required adjustment codes
				ON
					Br.OutclearingBranchType = RpBr.BranchCode
				AND Br.SortCode = Cr.Sortcode
				WHERE
					(EXISTS
					(
						SELECT
							EntityState
						FROM
							Report.dimReportEntityState AS IncSt
						WHERE
							ReportID = @ReportId
						AND ColumnName = 'InclusionState'
						AND ItemIndicator = 'Cr'
						AND EXISTS
							(
								SELECT
									MSG01
								FROM
									Report.dimCreditEntityStateHistory
								WHERE
									CreditId = Cr.ICSITemID
								AND IncSt.EntityState = MSG01
								AND EntityType = 'I'
							)
					)
					)
				AND (NOT EXISTS
					(
						SELECT
							EntityState
						FROM
							Report.dimReportEntityState AS ExSt
						WHERE
							ReportID = @ReportId
						AND ColumnName = 'ExclusionState'
						AND ItemIndicator = 'Cr'
						AND EXISTS
							(
								SELECT
									MSG01
								FROM
									Report.dimCreditEntityStateHistory
								WHERE
									CreditId = Cr.ICSITemID
								AND ExSt.EntityState = MSG01
								AND EntityType = 'I'
							)
					)
					);

				CREATE NONCLUSTERED INDEX nci_TransactionSetId
				ON #FinalCreditItems (TransactionSetId);

				SELECT
					Cr	.[ICSITemID],
					Cr.[ICSTransactionID],
					Cr.[Sortcode],
					Cr.[AccountNumber],
					Cr.[Reference],
					Cr.[AdjustmentCode],
					Cr.[AdjustmentReasonDescription],
					CAST(Cr.[PayInDate] AS DATE)										AS PayInDate,
					RIGHT('000000000000000' + REPLACE(Cr.CurrentAmount, '.', ''), 15) AS CurrentAmount,
					RIGHT('000000000000000' + REPLACE(Cr.OriginalAmount, '.', ''), 15) AS OriginalAmount,
					Cr.[Comments]
				FROM
					#FinalCreditItems				AS Cr
				INNER JOIN
					[Report].[factDebitAmounts]		AS DbAmnt
				ON
					Cr.TransactionSetId = DbAmnt.TransactionSetKey
				INNER JOIN
					[Report].[dimDebitInformation]	AS Db
				ON
					Db.DebitId = DbAmnt.DebitId
				WHERE
					(NOT EXISTS
					(
						SELECT
							EntityState
						FROM
							Report.dimReportEntityState AS ExSt
						WHERE
							ReportID = @ReportId
						AND ColumnName = 'ExclusionState'
						AND ItemIndicator = 'Db'
						AND EXISTS
							(
								SELECT
									MSG01
								FROM
									Report.dimDebitEntityStateHistory
								WHERE
									DebitId = Db.DebitId
								AND ExSt.EntityState = MSG01
								AND EntityType = 'I'
							)
					)
					)
				GROUP BY
					Cr.[ICSITemID],
					Cr.[ICSTransactionID],
					Cr.[Sortcode],
					Cr.[AccountNumber],
					Cr.[Reference],
					Cr.[AdjustmentCode],
					Cr.[AdjustmentReasonDescription],
					Cr.[PayInDate],
					Cr.CurrentAmount,
					Cr.OriginalAmount,
					Cr.[Comments];
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
	END;
GO

GRANT
	EXECUTE
ON [RnEWareHouseReports].[usp_CustomerAdviceReport]
TO
	[RnESsrsDwAccess];
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'RnEReportDataWarehouse',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_CustomerAdviceReport';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Generates Customer Advice Report',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_CustomerAdviceReport';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_CustomerAdviceReport';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Calling Application',
	@value = N'iPSL.RNE.Report31CustomerAdvice.dstx',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_CustomerAdviceReport';
GO
