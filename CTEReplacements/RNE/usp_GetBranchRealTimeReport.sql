CREATE PROCEDURE [RNE].[usp_GetBranchRealTimeReport]
(
	@StartDateRangeKey BIGINT,
	@EndDateRangeKey BIGINT
	,@AdjustmentCodes XML
)
/*****************************************************************************************************************
* Stored Procedure	: [RnEWareHouseReports].[usp_GetBranchRealTimeReport]
* Author			: Hamid Narikkoden
* Description		: Generates Branch Real Time Report
* Creation Date		: 22/06/2018
* Last Modified		: 
******************************************************************************************************************/
AS
	BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        BEGIN TRY

				DECLARE @AdjustmentReasons TABLE
				(
					Code VARCHAR(6),
					Description VARCHAR(255)
				)

				INSERT INTO 
					@AdjustmentReasons
				SELECT 
					 AL.A.value('./ReasonCode[1]','VARCHAR(6)') AS  Code
					,AL.A.value('./Description[1]','VARCHAR(255)') AS  Description
				FROM 
					@AdjustmentCodes.nodes('/ROOT/AdjustmentReasons/AdjustmentReason') AS AL(A)			
					
				SELECT	 
					cf_LocationID 
					,AltSource
					,cf_ICSTransactionID
					,[ICSITemID]
					,APGDIN
					,ItType
					,[Sortcode]
					,[AccountNumber]
					,[Reference]
					,TranCode
					,FinalAmount
					,OriginalAmount
					,RejectReason	
					,[AdjustmentCode]
					,PayInDate
					,[Comments]
					,ItmState
					,TransactionSetIdWithVersion
				INTO
					#EligibleItems
				FROM
					(
						SELECT	 
							IT.cf_LocationID 
							,Tx.AltSource
							,IT.cf_ICSTransactionID
							,FC.CreditId AS [ICSITemID]
							,FC.APGDIN
							,'Cr' AS ItType
							,FC.[Sortcode]
							,FC.[AccountNumber]
							,FC.[Reference]
							,FC.TranCode
							,FC.Amount AS FinalAmount
							,FC.OriginalAmount AS OriginalAmount
							,FC.cf_NoPaySuspectRsn AS RejectReason	
							,FC.AdjustmentReason AS [AdjustmentCode]
							,CAST(FC.APGBusinessDate AS DATE) AS PayInDate
							,FC.[Comments]
							,En.EntityState AS ItmState
							,TransactionSetIdWithVersion
							,RANK() OVER (PARTITION BY EN.entityIdentifier ORDER BY En.Revision DESC) AS ItmRnk
						FROM 
							base.vw_FinalCredit FC
						INNER JOIN 
							Base.Item IT 
						ON 
							IT.FCMIdentifier = FC.CreditId
						INNER JOIN
							base.Entity EN 
						ON 
							FC.CreditId = EN.EntityIdentifier 
						AND 
							EN.EntityType = 'I'
						INNER JOIN 
							BASE.vw_TXSet TX 
						ON 
							TX.InternalTxId = FC.InternalTxId
						WHERE 
							TX.AltSource =5200
						AND 
							EN.EntityId BETWEEN @StartDateRangeKey and @EndDateRangeKey
						AND 
							EN.Entitystate < 900
					) Tmp
				WHERE 
					Itmrnk = 1 

				UNION 

					SELECT	 
						cf_LocationID 
						,AltSource
						,cf_ICSTransactionID
						,[ICSITemID]
						,APGDIN
						,ItType
						,[Sortcode]
						,[AccountNumber]
						,[Reference]
						,TranCode
						,FinalAmount
						,OriginalAmount
						,RejectReason	
						,[AdjustmentCode]
						,PayInDate
						,[Comments]
						,ItmState
						,TransactionSetIdWithVersion
					FROM
						(
							SELECT	 
								IT.cf_LocationID 
								,Tx.AltSource
								,IT.cf_ICSTransactionID
								,FC.DebitId AS [ICSITemID]
								,FC.APGDIN
								,'Dr' AS ItType
								,FC.[Sortcode]
								,FC.[AccountNumber]
								,COALESCE(IT.DebitReference, FC.SerialNumber) AS [Reference]
								,FC.TranCode
								,FC.Amount AS FinalAmount
								,FC.OriginalAmount AS OriginalAmount
								,FC.cf_NoPaySuspectRsn AS RejectReason	
								,FC.AdjustmentReason AS [AdjustmentCode]
								,CAST(FC.APGBusinessDate AS DATE) AS PayInDate
								,FC.[Comments]
								,En.EntityState AS ItmState
								,TransactionSetIdWithVersion
								,RANK() OVER (PARTITION BY EN.entityIdentifier ORDER BY En.Revision DESC) AS ItmRnk
							FROM 
								base.vw_FinalDebit FC
							INNER JOIN 
								Base.Item IT 
							ON 
								IT.FCMIdentifier = FC.DebitId
							INNER JOIN 
								base.Entity EN 
							ON 
								FC.DebitId = EN.EntityIdentifier 
							AND 
								EN.EntityType = 'I'
							INNER JOIN 
								BASE.vw_TXSet TX 
							ON 
								TX.InternalTxId = FC.InternalTxId
							WHERE 
								TX.AltSource =5200
							AND 
								EN.EntityId BETWEEN @StartDateRangeKey AND @EndDateRangeKey
							AND 
								EN.Entitystate < 900
						) Tmp
					WHERE
						Itmrnk = 1


				CREATE NONCLUSTERED INDEX nci_TSIWV ON #EligibleItems (TransactionSetIdWithVersion)
				CREATE NONCLUSTERED INDEX nci_AdjCode ON #EligibleItems (AdjustmentCode)

				SELECT	 
					cf_LocationID  AS [Collecting Branch Sort Code]
					,AltSource AS Channel
					,cf_ICSTransactionID AS [ICS Transaction Set ID]
					,[ICSITemID]
					,APGDIN AS [Item DIN]
					,ItType AS [ItemType]
					,[Sortcode]
					,[AccountNumber]
					,[Reference]
					,TranCode
					,FinalAmount
					,OriginalAmount
					,RejectReason	
					,[AdjustmentCode]
					,[Description] AS [Adjustment Description]
					,PayInDate AS [Processing Date]
					,[Comments]
					,ItmState
					,TxSetState
				FROM
					(
						SELECT	 
							IT.cf_LocationID 
							,IT.AltSource
							,IT.cf_ICSTransactionID
							,IT.[ICSITemID]
							,IT.APGDIN
							,IT.ItType
							,RIGHT(REPLICATE('0',6) + CONVERT(VARCHAR(6),IT.[Sortcode]),6) AS  [Sortcode]
							,IT.[AccountNumber]
							,IT.[Reference]
							,IT.TranCode
							,IT.FinalAmount
							,IT.OriginalAmount
							,IT.RejectReason	
							,IT.[AdjustmentCode]
							,AD.[Description] 
							,IT.PayInDate
							,IT.[Comments]
							,ItmState = 
										CASE 
											WHEN ItmState = 20 THEN 'Valid After Clearing' 
											WHEN ItmState = 21 THEN 'Invalid After Clearing' 
											WHEN ItmState = 23 THEN 'Not Valid for Clearing'
											WHEN ItmState = 25 THEN 'Not Eligible for Clearing' 
											WHEN ItmState = 30 THEN 'Withdrawn After Clearing'  
											WHEN ItmState = 40 THEN 'Amended After Clearing'  
											WHEN ItmState = 50 THEN 'Valid After Fraud' 
											WHEN ItmState = 51 THEN 'Invalid After Fraud'  
											WHEN ItmState = 60 THEN 'Withdrawn After Fraud'  
											WHEN ItmState = 70 THEN 'Amended After Fraud'
											WHEN ItmState = 80 THEN 'Valid After Clearing' 
											WHEN ItmState = 81 THEN 'Invalid After Clearing'  
											WHEN ItmState = 82 THEN 'Withdrawn After Clearing'  
											WHEN ItmState = 83 THEN 'Amended After Clearing'  
											WHEN ItmState = 88 THEN 'Valid After Fraud' 
											WHEN ItmState = 89 THEN 'Invalid After Fraud'
											ELSE NULL
										END
							,TxSetState =
										CASE
											WHEN EN.EntityState = 20 THEN 'Tset - Valid After Clearing' 
											WHEN EN.EntityState = 21 THEN 'Tset - Invalid After Clearing'
											WHEN EN.EntityState = 23 THEN 'Tset - Not Valid for Clearing' 
											WHEN EN.EntityState = 25 THEN 'Tset - Not Eligible for Clearing'    
											WHEN EN.EntityState = 30 THEN 'Tset - Withdrawn After Clearing'  
											WHEN EN.EntityState = 40 THEN 'Tset - Amended After Clearing'  
											WHEN EN.EntityState = 50 THEN 'Tset - Valid After Fraud' 
											WHEN EN.EntityState = 51 THEN 'Tset - Invalid After Fraud'  
											WHEN EN.EntityState = 60 THEN 'Tset - Withdrawn After Fraud'  
											WHEN EN.EntityState = 70 THEN 'Tset - Amended After Fraud'
											WHEN EN.EntityState = 80 THEN 'Tset - Valid After Clearing' 
											WHEN EN.EntityState = 81 THEN 'Tset - Invalid After Clearing'  
											WHEN EN.EntityState = 82 THEN 'Tset - Withdrawn After Clearing'  
											WHEN EN.EntityState = 83 THEN 'Tset - Amended After Clearing'  
											WHEN EN.EntityState = 88 THEN 'Tset - Valid After Fraud' 
											WHEN EN.EntityState = 89 THEN 'Tset - Invalid After Fraud'
											ELSE NULL
										END
							,TransactionSetIdWithVersion
							,RANK() OVER (PARTITION BY EN.entityIdentifier ORDER BY En.Revision DESC) AS TsetRnk
						FROM 
							base.Entity EN 
						INNER JOIN 
							#EligibleItems IT 
						ON 
							EN.EntityIdentifier = IT.TransactionSetIdWithVersion
						AND 
							EN.EntityType = 'T'
						LEFT JOIN  
							@AdjustmentReasons AD 
						ON 
							AD.Code = IT.AdjustmentCode
						WHERE 
							EN.Entitystate < 900
					) Tmp
					WHERE 
						TsetRnk = 1
					ORDER BY 
						cf_LocationID
						,cf_ICSTransactionID,ICSITemID						

		END TRY
		BEGIN CATCH	

					THROW;

		END CATCH;
	END

GO

GRANT EXECUTE ON [RNE].[usp_GetBranchRealTimeReport] TO [RNESVCAccess];

GO

EXEC sys.sp_addextendedproperty @name=N'Component', @value=N'STAR' , @level0type=N'SCHEMA',@level0name=N'RNE', @level1type=N'PROCEDURE',@level1name=N'usp_GetBranchRealTimeReport'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Extract ADJ Posting Information from Shorterm Archive' , @level0type=N'SCHEMA',@level0name=N'RNE', @level1type=N'PROCEDURE',@level1name=N'usp_GetBranchRealTimeReport'
GO

EXEC sys.sp_addextendedproperty @name=N'Version', @value=N'1.1.0' , @level0type=N'SCHEMA',@level0name=N'RNE', @level1type=N'PROCEDURE',@level1name=N'usp_GetBranchRealTimeReport'
GO