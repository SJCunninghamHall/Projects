CREATE  PROCEDURE [DataImport].[usp_UpdateCollectingReconciliationCredits] 
(
@BusinessDate DATE,
@PrevBusinessDate DATE
)
/*****************************************************************************************************
* Name				: [DataImport].[usp_UpdateCollectingReconciliationCredits]
* Description		: This stored procedure UPDATEs Collecting reconcilation reports data for Credit items
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
			
			DECLARE @BusinessDateInt INT = CAST(CONVERT(VARCHAR,@BusinessDate,112) AS INT)
			DECLARE @PrevBusinessDateInt INT = CAST(CONVERT(VARCHAR,@PrevBusinessDate,112) AS INT)

			SELECT
				CreditId ,
				ISNULL(MAX(ICSAmount),0)ICSAmount,
				MAX(MSG01) As MSG01,
				MAX(MSG02) As MSG02,
				MAX(MSG03) As MSG03
			INTO
				#EligibleItems
			FROM
				(
					SELECT 
						CreditId ,
						ICSAmount,
						ROW_NUMBER() OVER (PARTITION BY CreditId ORDER BY Revision DESC) Rnk,
						MSG01
						,0 As MSG02
						,0 As MSG03
					FROM
						[Report].[dimCreditEntityStateHistory]
					WHERE 
						DateKey = @BusinessDateInt 
					AND 
						EntityType = 'I' 
					AND 
						MSG01 > 0
					UNION ALL
						SELECT 
							CreditId ,
							ICSAmount,
							ROW_NUMBER() OVER (PARTITION BY CreditId ORDER BY Revision DESC) Rnk,
							0 As MSG01
							,MSG02
							,0 As MSG03
						FROM 
							[Report].[dimCreditEntityStateHistory]
						WHERE 
							DateKey = @BusinessDateInt 
						AND 
							MSG02 > 0
					UNION ALL
						SELECT 
							CreditId ,
							ICSAmount,
							ROW_NUMBER() OVER (PARTITION BY CreditId ORDER BY Revision DESC) Rnk,
							0 As MSG01
							,0 As MSG02
							,MSG03
						FROM 
							[Report].[dimCreditEntityStateHistory]
						WHERE 
							DateKey = @BusinessDateInt 
						AND 
							EntityType = 'I' 
						AND 
							MSG03 > 0
				) R 
			LEFT JOIN 
				Report.dimChannelCollectionRecon CR 
			ON 
				CR.ItemTransID = R.CreditId 
			AND 
				CR.IsOutclearingOut = 1
			LEFT JOIN 
				Report.dimChannelCollectionRecon CR1 
			ON 
				CR1.ItemTransID = R.CreditId 
			AND 
				CR1.IsWithdrawn = 1
			WHERE 
				R.Rnk = 1 
			AND 
				CR.ItemTransID IS NULL 
			AND 
				CR1.ItemTransID IS NULL
			GROUP BY 
				R.CreditId


			CREATE NONCLUSTERED INDEX nci_CreditId ON #EligibleItems(CreditId)


			SELECT 
				I.CreditId,
				I.DateKey,
				CreditEntryDate,				
				ROW_NUMBER() OVER (PARTITION BY I.CreditId ORDER BY EntityId DESC) EntRank
			INTO
				#OutclearingIn
			FROM 
				[Report].[dimCreditEntityStateHistory] I
			INNER JOIN 
				#EligibleItems EI 
			ON 
				EI.CreditId = I.CreditId
			WHERE 
				I.MSG01 IN (20,21,23,25) AND EntityType='I'


			CREATE NONCLUSTERED INDEX nci_CreditId_EntRank ON #OutclearingIn(CreditId, EntRank)


			SELECT  
				I.CreditId, 
				ROW_NUMBER() OVER (PARTITION BY I.CreditId ORDER BY EntityId DESC ) EntRank,
				EntityState
			INTO
				#MAX_Revision
			FROM 
				[Report].[dimCreditEntityStateHistory] I
			INNER JOIN 
				#EligibleItems EI 
			ON 
				EI.CreditId = I.CreditId
			WHERE 
				I.DateKey = @BusinessDateInt 
			AND 
				EntityType='I'


			CREATE NONCLUSTERED INDEX nci_CreditId_EntRank ON #MAX_Revision(CreditId, EntRank)


			SELECT 
				DR.CreditId,
				TS.AltSource
			INTO
				#Txns
			FROM 
				#EligibleItems DR
			INNER JOIN 
				Report.factCreditAmounts FC 
			ON 
				DR.CreditId = FC.CreditId
			INNER JOIN 
				Report.dimTransactionSet TS 
			ON 
				TS.TransactionSetId = FC.TransactionSetKey
			WHERE 
				TS.AltSource IS NOT NULL
			GROUP BY 
				DR.CreditId
				,TS.AltSource

			CREATE NONCLUSTERED INDEX nci_CreditId ON #Txns(CreditId)

			MERGE 
				Report.dimChannelCollectionRecon EFC
            USING
            (  
				SELECT    
					CR.CreditId ,
					TS.AltSource As Channel,					
					--Entity state of MSG01 in 20 or 21 or 23 or 25 then Outclearing in
					IIF(OI.CreditId IS NOT NULL AND OI.CreditEntryDate = @BusinessDate ,1,0) As IsOutclearingIn,
					--Final entity state for the day in 165
					IIF(MR.CreditId IS NOT NULL AND MR.EntityState = 165, 1, 0) AS IsHoldover,
					--Final entity state for the day in  130
					IIF(MR.CreditId IS NOT NULL AND MR.EntityState IN (30,60,130), 1, 0) AS IsWithdrawn,
					--Final entity state for the day in  100
					IIF(OI.CreditId IS NOT NULL AND CR.MSG02=100 AND MR.EntityState NOT IN  (30,60,130,165) ,1 ,0) AS IsOutclearingOut,					
					FC.OriginalAmount As OriginalAmount,
					FC.Amount As Amount,
					MR.EntityState,
					IIF((CR.ICSAmount=0 OR CR.ICSAmount IS NULL) ,0,1) AS IsItemSubmitToSwitch
				FROM 
					#EligibleItems CR				
				INNER JOIN 
					Report.factCreditAmounts FC 
				ON 
					CR.CreditId = FC.CreditId
				INNER JOIN 
					Txns TS 
				ON 
					TS.CreditId = FC.CreditId
				LEFT JOIN 
					#OutclearingIn OI 
				ON 
					OI.CreditId = CR.CreditId 
				AND 
					OI.EntRank = 1
				LEFT JOIN 
					#MAX_Revision MR 
				ON 
					MR.CreditId = CR.CreditId 
				AND 
					MR.EntRank = 1
                ) AS NFC 
					( 
						CreditId, 
						Channel, 
						IsOutclearingIn, 
						IsHoldover,
						IsWithdrawn,
						IsOutclearingOut,
						OriginalAmount, 
						Amount,
						FinalEntityState,
						IsItemSubmitToSwitch
					)
				ON 
					EFC.ItemTransID = NFC.CreditId  
				AND 
					EFC.Channel = NFC.Channel 
				AND 
					EFC.FullDate = @BusinessDate                 
                WHEN MATCHED THEN
                    
					UPDATE SET 
						IsOutclearingIn = NFC.IsOutclearingIn ,
						IsHoldover = NFC.IsHoldover ,
						IsNextDayHoldover = NFC.IsHoldover ,
						IsWithdrawn = NFC.IsWithdrawn ,
						IsOutclearingOut = NFC.IsOutclearingOut ,
						OriginalAmount = ISNULL(NFC.OriginalAmount,0) ,
						FinalAmount = ISNULL(NFC.Amount,0) ,
						FinalEntityState = NFC.FinalEntityState,
						IsItemSubmitToSwitch=NFC.IsItemSubmitToSwitch
                
				WHEN NOT MATCHED THEN
                    INSERT 
						( 
							ItemTransID,
							FullDate,
							Channel ,                             
							IsOutclearingIn ,
							IsHoldover ,
							IsNextDayHoldover,
							IsWithdrawn,
							IsOutclearingOut ,
							OriginalAmount ,
							FinalAmount ,
							CrDbInd,
							FinalEntityState,
							IsItemSubmitToSwitch					
						)
                    VALUES 
						( 
							NFC.CreditId ,
							@BusinessDate,
							NFC.Channel ,
							NFC.IsOutclearingIn ,
							NFC.IsHoldover ,
							NFC.IsHoldover ,
							NFC.IsWithdrawn ,
							NFC.IsOutclearingOut,
							ISNULL(NFC.OriginalAmount,0) ,
							ISNULL(NFC.Amount,0) ,
							'Cr',
							NFC.FinalEntityState,
							NFC.IsItemSubmitToSwitch
						) ;	
						   
			-- Update Previous Day Holdover
			UPDATE 
				CR
			SET 
				CR.IsPrevDayHoldover = 1
			FROM 
				[Report].dimChannelCollectionRecon CR
			INNER JOIN 
			(
				SELECT 
					ItemTransID
				FROM 
					[Report].dimChannelCollectionRecon
				WHERE 
					FullDate = @PrevBusinessDate 
				AND 
					IsNextDayHoldover = 1 
				AND 
					CrDbInd = 'Cr'
			) As DR 
			ON 
				DR.ItemTransID = CR.ItemTransID
			WHERE 
				CR.FullDate = @BusinessDate 
			AND 
				CrDbInd= 'Cr'

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

GRANT EXECUTE ON [DataImport].[usp_UpdateCollectingReconciliationCredits] TO [RnEReportDwDataImporter];

GO

EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)',
    @level0type = N'SCHEMA', @level0name = N'DataImport',
    @level1type = N'PROCEDURE',
    @level1name = N'usp_UpdateCollectingReconciliationCredits';
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'This stored procedure UPDATEs Collecting reconcilation reports data',
    @level0type = N'SCHEMA', @level0name = N'DataImport',
    @level1type = N'PROCEDURE',
    @level1name = N'usp_UpdateCollectingReconciliationCredits';
GO
EXECUTE sp_addextendedproperty @name = N'Component',
    @value = N'RnEReportDataWarehouse', @level0type = N'SCHEMA',
    @level0name = N'DataImport', @level1type = N'PROCEDURE',
    @level1name = N'usp_UpdateCollectingReconciliationCredits';
GO
EXEC sys.sp_addextendedproperty @name = N'Calling Application',
    @value = N'IPSL.RNE.RefreshDataWarehouse.dtsx', @level0type = N'SCHEMA',
    @level0name = N'DataImport', @level1type = N'PROCEDURE',
    @level1name = N'usp_UpdateCollectingReconciliationCredits';

GO