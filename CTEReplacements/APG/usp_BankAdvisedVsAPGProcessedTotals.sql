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
@BusinessDate VARCHAR(8)
AS
BEGIN 
  SET NOCOUNT ON;
      BEGIN TRY
       DECLARE @ErrorMessage VARCHAR(4000)
	   DECLARE @UserName VARCHAR(50);
       DECLARE @ErrorNumber VARCHAR(50);
	   DECLARE @ErrorState VARCHAR(5);
	   DECLARE @ErrorProcedure VARCHAR(50);
	   DECLARE @ErrorLine VARCHAR(5);
	   DECLARE @ErrorSeverity  INT;
       BEGIN
	      
	       ;WITH Processed(Source,ProcessedCreditCount,ProcessedCreditTotal,ProcessedDebitCount,ProcessedDebitTotal)
           AS
           (
           	   SELECT 
			      SCC.Channel AS Source,
                  SUM(APG.ChannelCreditCount) AS ProcessedCreditCount, 
                  SUM(APG.ChannelCreditTotal) AS ProcessedCreditTotal,
                  SUM(APG.ChannelDebitCount) AS ProcessedDebitCount,
                  SUM(APG.ChannelDebitTotal) AS ProcessedDebitTotal
               FROM Base.APGCaptureData APG			  
           	   INNER JOIN Config.SourceToChannelDetails SCC on APG.InputSourceType = SCC.Source
               WHERE APG.APGBusinessdate = @BusinessDate
               GROUP BY SCC.Channel
           ),
           Advised(Source,AdvisedCreditCount,AdvisedCreditTotal,AdvisedDebitCount,AdvisedDebitTotal)
           AS
           (                  
           		SELECT 
           		   SCC.Channel AS Source,
                   SUM(CSV.CreditCount) AS AdvisedCreditCount,
                   SUM(CSV.CreditTotal) AS AdvisedCreditTotal,
                   SUM(CSV.DebitCount) AS AdvisedDebitCount,
                   SUM(CSV.DebitTotal) AS AdvisedDebitTotal 
                FROM Base.ChannelCSVFileDetails CSV
           		INNER JOIN Config.SourceToChannelDetails SCC on CSV.FinancialInstitutionID = SCC.Source
           	    WHERE CSV.Businessdate = @BusinessDate
                GROUP BY SCC.Channel
           )
           SELECT 
			   AD.Source,
			   ProcessedCreditCount,
			   ProcessedCreditTotal,
			   ProcessedDebitCount,
			   ProcessedDebitTotal,
			   AdvisedCreditCount,
			   AdvisedCreditTotal,
			   AdvisedDebitCount,
			   AdvisedDebitTotal
           FROM Advised AD INNER JOIN Processed PD ON AD.Source = PD.Source
           
           UNION ALL 
           
           SELECT 
			   AD.Source,
			   NULL AS ProcessedCreditCount,
			   NULL AS ProcessedCreditTotal,
			   NULL AS ProcessedDebitCount,
			   NULL AS ProcessedDebitTotal,
			   AdvisedCreditCount,
			   AdvisedCreditTotal,
			   AdvisedDebitCount,
			   AdvisedDebitTotal
           FROM Advised AD 
           WHERE AD.Source NOT IN (SELECT SOURCE FROM Processed)
           
           UNION ALL 
           
           SELECT 
			   PD.Source,
			   ProcessedCreditCount,
			   ProcessedCreditTotal,
			   ProcessedDebitCount,
			   ProcessedDebitTotal,
			   NULL AS AdvisedCreditCount,
			   NULL AS AdvisedCreditTotal,
			   NULL AS AdvisedDebitCount,
			   NULL AS AdvisedDebitTotal
           FROM Processed PD
           WHERE PD.Source NOT IN (SELECT SOURCE FROM Advised)

	    END
      END TRY

  BEGIN CATCH	
    SET @UserName = CONVERT(sysname, ORIGINAL_LOGIN());
	SET @ErrorNumber = ERROR_NUMBER();
	SET @ErrorSeverity = ERROR_SEVERITY();
	SET @ErrorState =ERROR_STATE();
	SET @ErrorProcedure = ERROR_PROCEDURE(); 
    SET @ErrorLine = ERROR_LINE();
	SET @ErrorMessage = ERROR_MESSAGE();
    EXEC Base.usp_LogError @UserName, @ErrorNumber,@ErrorSeverity, @ErrorState,@ErrorProcedure,@ErrorLine,@ErrorMessage;	
	THROW
END CATCH;
END
GO
GRANT EXECUTE ON [Base].[usp_BankAdvisedVsAPGProcessedTotals]  to [Recon_User] as [dbo]
GO
EXEC sys.sp_addextendedproperty @name = N'Component',
    @value = N'Cross Client -Recon DB', @level0type = N'SCHEMA',
    @level0name = N'Base', @level1type = N'PROCEDURE',
    @level1name = N'usp_BankAdvisedVsAPGProcessedTotals';
GO
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
    @value = N'Change Channel Recon',
    @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE',
    @level1name = N'usp_BankAdvisedVsAPGProcessedTotals';
GO 
EXEC sys.sp_addextendedproperty @name = N'Version', @value = N'$(Version)',
    @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE',
    @level1name = N'usp_BankAdvisedVsAPGProcessedTotals';
GO