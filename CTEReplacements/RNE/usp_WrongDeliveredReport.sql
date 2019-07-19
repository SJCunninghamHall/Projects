/****************************************************************************************
* Stored Procedure:[WAR].[usp_WrongDeliveredReport]
* Description: Create No Pays Wrongly Delivered Report - Contains items that we have received in MSG06(For Debits) and MSG05(for credits) where  
*		       an APG operator has assigned a No Pay Reason as Wrongly Delivered
* Sort Order : Collecting Participant,Collecting Location
* Amendment History
*****************************************************************************************
* Version		Name						Date               Reason
* 1.3.0			Mazar Shaik				    14 Aug 2017        Create No Pays Wrongly Delivered Report
*****************************************************************************************/
CREATE PROCEDURE [WAR].[usp_WrongDeliveredReport]
    @BusinessDate VARCHAR(8)
AS

    BEGIN TRY

        BEGIN

            SET NOCOUNT ON;
            SET XACT_ABORT ON;

			SELECT DISTINCT
				ParticipantID,
				Participantname 
			INTO 
				#ParticipantDetailsCTE
			FROM     
				[Report].[dimParticipantData]

			--Get the distinct TransactionSetKey bcos multiple debit might have single credit
			SELECT DISTINCT       
				TS.TransactionSetId TransactionSetKey ,
				TS.CollectingParticipantId,
				TS.CollectingLocation,
				PD.Participantname
			INTO
				#TransactionCTE
			FROM     
				Report.dimDebitInformation DI
			INNER JOIN 
				[Report].[factDebitAmounts] FD 
			ON 
				FD.DebitId = DI.DebitId
			INNER JOIN 
				Report.vw_DimTransactionSet TS 
			ON 
				TS.TransactionSetId = FD.TransactionSetKey
			INNER JOIN 
				[Report].[factCreditAmounts] FC 
			ON 
				TS.TransactionSetId = FC.TransactionSetKey
			INNER JOIN 
				[Report].dimCreditInformation CI 
			ON 
				CI.CreditId = FC.CreditId
			INNER JOIN 
				ParticipantDetailsCTE PD 
			ON 
				PD.ParticipantID = TS.CollectingParticipantId
			WHERE    
				CI.cf_NoPaySuspectRsn = 'Wrongly Delivered'
			AND 
				DI.SettlementDate = @BusinessDate

			CREATE NONCLUSTERED INDEX nci_TransactionSetKey ON #TransactionCTE(TransactionSetKey)

			SELECT 
				WrongDelivered.[Collecting Participant]
				,WrongDelivered.[Collecting Location]
				,WrongDelivered.UIN
				,WrongDelivered.Sortcode
				,WrongDelivered.AccountNumber
				,WrongDelivered.[Serial/Reference]
				,WrongDelivered.[CR Value]
				,WrongDelivered.[DR Value]
			FROM
				(
					SELECT  
						PD.ParticipantName AS 'Collecting Participant' ,
						TS.CollectingLocation AS 'Collecting Location' ,
						DI.DebitId AS UIN ,
						DI.Sortcode ,
						DI.AccountNumber ,
						CAST(DI.Serial AS VARCHAR(18)) AS 'Serial/Reference' ,
						CAST(0 AS NUMERIC(20,2)) AS 'CR Value' ,
						FD.Amount AS 'DR Value'
					FROM    
						Report.dimDebitEntityStateHistory DI
					INNER JOIN 
						[Report].[factDebitAmounts] FD 
					ON 
						FD.DebitId = DI.DebitId
					INNER JOIN 
						Report.vw_DimTransactionSet TS 
					ON 
						TS.TransactionSetId = FD.TransactionSetKey
					INNER JOIN 
						ParticipantDetailsCTE PD 
					ON 
						PD.ParticipantID = TS.CollectingParticipantId
					WHERE   
						DI.cf_NoPaySuspectRsn = 'Wrongly Delivered'
					AND 
						DI.IntMessageType IN ('06MA02')
					AND 
						DI.SettlementDate = @BusinessDate

					UNION ALL

						SELECT  
							TS.ParticipantName AS 'Collecting Participant' ,
							TS.CollectingLocation AS 'Collecting Location' ,
							CI.CreditId AS UIN ,
							CI.Sortcode ,
							CI.AccountNumber ,
							CI.Reference AS 'Serial/Reference' ,
							FC.Amount AS 'CR Value' ,
							0 AS 'DR Value'
						FROM    
							TransactionCTE TS
						INNER JOIN 
							[Report].[factCreditAmounts] FC 
						ON 
							TS.TransactionSetKey = FC.TransactionSetKey
						INNER JOIN 
							[Report].dimCreditInformation CI 
						ON 
							CI.CreditId = FC.CreditId
						WHERE   
							CI.cf_NoPaySuspectRsn = 'Wrongly Delivered'
				) WrongDelivered 
			ORDER BY 
				[Collecting Participant]
				,[Collecting Location]

        END;
	      
    END TRY
    BEGIN CATCH
        DECLARE @Number INT = ERROR_NUMBER();  
        DECLARE @Message VARCHAR(4000) = ERROR_MESSAGE();  
        DECLARE @UserName NVARCHAR(128) = CONVERT(SYSNAME, CURRENT_USER);  
        DECLARE @Severity INT = ERROR_SEVERITY();  
        DECLARE @State INT = ERROR_STATE();  
        DECLARE @Type VARCHAR(128) = 'Stored Procedure';  
        DECLARE @Line INT = ERROR_LINE();  
        DECLARE @Source VARCHAR(128) = ERROR_PROCEDURE();  
        EXEC [Base].[usp_LogException] @Number, @Message, @UserName, @Severity,
            @State, @Type, @Line, @Source;  
        THROW;
    END CATCH;

GO
	GRANT EXECUTE ON [WAR].[usp_WrongDeliveredReport] TO [RnEWAR]
GO

EXEC sys.sp_addextendedproperty @name = N'Component',
    @value = N'RnEReportDataWarehouse', @level0type = N'SCHEMA',
    @level0name = N'WAR', @level1type = N'PROCEDURE',
    @level1name = N'usp_WrongDeliveredReport';
GO
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
    @value = N'Create No Pays Wrongly Delivered Report - Contains items that we have received in MSG06(For Debits) and MSG05(for credits) 
	         where an APG operator has assigned a No Pay Reason as Wrongly Delivered', 
	@level0type = N'SCHEMA',
    @level0name = N'WAR', @level1type = N'PROCEDURE',
    @level1name = N'usp_WrongDeliveredReport';
GO 
EXEC sys.sp_addextendedproperty @name = N'Version', @value = N'$(Version)',
    @level0type = N'SCHEMA', @level0name = N'WAR', @level1type = N'PROCEDURE',
    @level1name = N'usp_WrongDeliveredReport';
GO
EXEC sys.sp_addextendedproperty 
@name=N'Calling Application'
, @value=N'iPSL.RNE.WARWrongDelivered.dtsx'
, @level0type=N'SCHEMA'
, @level0name=N'WAR'
, @level1type=N'PROCEDURE'
, @level1name=N'usp_WrongDeliveredReport'

GO