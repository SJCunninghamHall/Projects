/****** Object:  StoredProcedure [Base].[usp_BankAdvisedVsAPGProcessedTotals]    Script Date: 15/06/2017 ******/
-- =============================================
-- Author:		Mazar Shaik
-- Create Date: 22/10/2017
-- Description:	Bank Advised Vs APG Processed Totals
--*********************************************************************************************************
--* Amendment History
--*--------------------------------------------------------------------------------------------------------
--* Version 				UserID          Date                    Reason
--*********************************************************************************************************
--* 1.0.0					Mazar			22/10/2017				Initial Version
-- =============================================
-- =============================================
CREATE PROCEDURE [Base].[usp_BankAdvisedVsAPGProcessedTotals]
	@BusinessDate	VARCHAR(8)
AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
			DECLARE @ErrorMessage VARCHAR(4000);
			DECLARE @UserName VARCHAR(50);
			DECLARE @ErrorNumber VARCHAR(50);
			DECLARE @ErrorState VARCHAR(5);
			DECLARE @ErrorProcedure VARCHAR(50);
			DECLARE @ErrorLine VARCHAR(5);
			DECLARE @ErrorSeverity INT;

			BEGIN

				SELECT
					SCC.Channel					AS Source,
					SUM(APG.ChannelCreditCount) AS ProcessedCreditCount,
					SUM(APG.ChannelCreditTotal) AS ProcessedCreditTotal,
					SUM(APG.ChannelDebitCount)	AS ProcessedDebitCount,
					SUM(APG.ChannelDebitTotal)	AS ProcessedDebitTotal
				INTO
					#Processed
				FROM
					Base.APGCaptureData				AS APG
				INNER JOIN
					Config.SourceToChannelDetails	AS SCC
				ON
					APG.InputSourceType = SCC.Source
				WHERE
					APG.APGBusinessdate = @BusinessDate
				GROUP BY
					SCC.Channel;


				CREATE CLUSTERED INDEX ci_Source
				ON #Processed (source);

				SELECT
					SCC.Channel				AS Source,
					SUM(CSV.CreditCount)	AS AdvisedCreditCount,
					SUM(CSV.CreditTotal)	AS AdvisedCreditTotal,
					SUM(CSV.DebitCount)		AS AdvisedDebitCount,
					SUM(CSV.DebitTotal)		AS AdvisedDebitTotal
				INTO
					#Advised
				FROM
					Base.ChannelCSVFileDetails		AS CSV
				INNER JOIN
					Config.SourceToChannelDetails	AS SCC
				ON
					CSV.FinancialInstitutionID = SCC.Source
				WHERE
					CSV.Businessdate = @BusinessDate
				GROUP BY
					SCC.Channel;


				CREATE CLUSTERED INDEX ci_Source
				ON #Advised (source);

				SELECT
					AD	.Source,
					[PD].[ProcessedCreditCount],
					[PD].[ProcessedCreditTotal],
					[PD].[ProcessedDebitCount],
					[PD].[ProcessedDebitTotal],
					[AD].[AdvisedCreditCount],
					[AD].[AdvisedCreditTotal],
					[AD].[AdvisedDebitCount],
					[AD].[AdvisedDebitTotal]
				FROM
					#Advised	AS AD
				INNER JOIN
					#Processed	AS PD
				ON
					AD.Source = PD.Source
				UNION ALL
				SELECT
					AD	.Source,
					NULL	AS ProcessedCreditCount,
					NULL	AS ProcessedCreditTotal,
					NULL	AS ProcessedDebitCount,
					NULL	AS ProcessedDebitTotal,
					[AD].[AdvisedCreditCount],
					[AD].[AdvisedCreditTotal],
					[AD].[AdvisedDebitCount],
					[AD].[AdvisedDebitTotal]
				FROM
					#Advised AS AD
				WHERE
					AD.Source NOT IN
						(
							SELECT
								SOURCE
							FROM
								#Processed
						)
				UNION ALL
				SELECT
					PD	.Source,
					[PD].[ProcessedCreditCount],
					[PD].[ProcessedCreditTotal],
					[PD].[ProcessedDebitCount],
					[PD].[ProcessedDebitTotal],
					NULL	AS AdvisedCreditCount,
					NULL	AS AdvisedCreditTotal,
					NULL	AS AdvisedDebitCount,
					NULL	AS AdvisedDebitTotal
				FROM
					#Processed AS PD
				WHERE
					PD.Source NOT IN
						(
							SELECT
								SOURCE
							FROM
								#Advised
						);

			END;
		END TRY
		BEGIN CATCH
			SET @UserName = CONVERT(sysname, ORIGINAL_LOGIN());
			SET @ErrorNumber = ERROR_NUMBER();
			SET @ErrorSeverity = ERROR_SEVERITY();
			SET @ErrorState = ERROR_STATE();
			SET @ErrorProcedure = ERROR_PROCEDURE();
			SET @ErrorLine = ERROR_LINE();
			SET @ErrorMessage = ERROR_MESSAGE();
			EXEC Base.usp_LogError
				@UserName,
				@ErrorNumber,
				@ErrorSeverity,
				@ErrorState,
				@ErrorProcedure,
				@ErrorLine,
				@ErrorMessage;
			THROW;
		END CATCH;
	END;
GO
GRANT
	EXECUTE
ON [Base].[usp_BankAdvisedVsAPGProcessedTotals]
TO
	[Recon_User]
AS [dbo];
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'Cross Client -Recon DB',
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_BankAdvisedVsAPGProcessedTotals';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Change Channel Recon',
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_BankAdvisedVsAPGProcessedTotals';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_BankAdvisedVsAPGProcessedTotals';
GO