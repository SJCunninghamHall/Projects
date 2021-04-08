CREATE PROCEDURE [Base].[csp_Load_XML_MOMessage_Shredded_Credit_Fraud_New]
	@CreditHolder [Base].[tv_Credit_New] READONLY

/*****************************************************************************************************
* Name				: [Base].[[csp_Load_XML_MOMessage_Shredded_Credit_Fraud]]
* Description		: This stored procedure will be called by all the TxSet related importing stored procedures
				      to insert the values read from xml into Base.CreditFraudData table
* Type of Procedure : Natively Compiled stored procedure
* Author			: Anton Richards
* Creation Date		: 27/09/2016
* Last Modified		: N/A
* Parameters		: 1
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************
*Parameter Name			Type						Description
*------------------------------------------------------------------------------------------------------
 @CreditHolder			[Base].[tv_Credit]			Credit Details
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************
*										History
*------------------------------------------------------------------------------------------------------
* Version	ID		Date			Reason
*******************************************************************************************************
* 1.0.0		001     27-Sep-2016   	Initial version
* 1.0.1		002		18-Sep-2018		Updated SP to select colums required to insert into flat table
*******************************************************************************************************/
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER 
AS BEGIN ATOMIC WITH (
      TRANSACTION ISOLATION LEVEL = SNAPSHOT,
      LANGUAGE = 'English')

	BEGIN TRY				


		--Insert the Credit values into the Credit table
		
		INSERT INTO [Base].[CreditFraudData]
				   ([ItemId]
				    ,[BeneficiaryName]
				    ,[ReferenceData]
				    ,[VirtualCredit]
					,[CashAmount] 
					,[CashAmountCurrency] 
					,[FundedAmount] 
					,[FundedAmountCurrency] 
					,[NonFundedAmount] 
					,[NonFundedAmountCurrency] 
					,[NumberOfItems] 
					,[ChequeAtRisk])
				SELECT	
					X.ItemId,
					X.[BeneficiaryName],
					X.[ReferenceData],
					X.[FraudVirtualCredit], 
					X.[CashAmount],
					X.[CashCurrency],
					X.[FundedAmount],
					X.[FundedCurrency],
					X.[NonFundedAmount],
					X.[NonFundedCurrency],
					X.[NumberOfItems],
					X.[ChequeAtRisk] 			  
				 FROM @CreditHolder X
				 WHERE 
					( 
						x.[BeneficiaryName] IS NOT NULL OR 
						x.[ReferenceData] IS NOT NULL OR
						x.[FraudVirtualCredit] IS NOT NULL OR
						x.[NumberOfItems] IS NOT NULL
					)
		
END TRY
	
	BEGIN CATCH
		THROW;
	END CATCH

END