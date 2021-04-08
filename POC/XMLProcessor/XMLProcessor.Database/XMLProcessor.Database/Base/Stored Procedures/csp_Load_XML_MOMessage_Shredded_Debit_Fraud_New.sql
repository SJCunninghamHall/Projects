CREATE PROCEDURE [Base].[csp_Load_XML_MOMessage_Shredded_Debit_Fraud_New]
	@DebitHolder [Base].[tv_Debit_New] READONLY
/*****************************************************************************************************
* Name				: [Base].[csp_Load_XML_MOMessage_Shredded_Debit_Fraud]
* Description		: This stored procedure will be called by all the TxSet related importing stored procedures
					  to insert the values read from xml into Base.DebitFraudData table
* Type of Procedure : Natively Compiled stored procedure
* Author			: Anton Richards
* Creation Date		: 28/09/2016
* Last Modified		: N/A
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************/
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER 
AS BEGIN ATOMIC WITH (
      TRANSACTION ISOLATION LEVEL = SNAPSHOT,
      LANGUAGE = 'English')

	BEGIN TRY				

		--Insert the Debit values into the Debit table

INSERT INTO [Base].[DebitFraudData]
           ([ItemId]
           ,[DateOfFirstCheque]
           ,[DateOfLastCheque]
           ,[NumberOfCounterparties]
           ,[NumberOfGoodCheques]
           ,[NumberOfFraudCheques]
           ,[LargestAmount]
           ,[LargestAmountCurrency]
           ,[RiskIndicator]
           ,[SuspiciousCheque]
		   )
     Select
	        x.ItemId			,
			x.DateOfFirstChq 	,
			x.DateOfLastChq 					    ,
			x.NbOfCounterparties 				    ,
			x.NbOfGoodCheques 					    ,
			x.NbOfFraudCheques 	 ,
			x.HighestAmt 		 ,
			x.[LargestAmountCurrency],
			x.RiskIndicator,
			x.RiskInd		 

				 FROM @DebitHolder x
				 WHERE 
		( 
			x.DateOfFirstChq IS NOT NULL OR 
			x.DateOfLastChq IS NOT NULL OR
			x.NbOfCounterparties IS NOT NULL OR
			x.NbOfGoodCheques IS NOT NULL OR
			x.NbOfFraudCheques IS NOT NULL OR
			x.HighestAmt IS NOT NULL OR
			x.RiskIndicator IS NOT NULL
		)

END TRY
	
	BEGIN CATCH
		THROW;
	END CATCH

END
GO

/*
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'Short_Term_Archive', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit_Fraud';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', 
	@value = N'This stored procedure will be called by all the TxSet related importing stored procedures
			   to insert the values read from xml into Base.DebitFraudData table', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit_Fraud';


GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'1.0.0', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit_Fraud';
*/