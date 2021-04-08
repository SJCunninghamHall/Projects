CREATE PROCEDURE [Base].[csp_Load_XML_MOMessage_Shredded_Debit_New]
	@DebitHolder [Base].[tv_Debit_New] READONLY
/*****************************************************************************************************
* Name				: [Base].[csp_Load_XML_MOMessage_Shredded_Debit]
* Description		: This stored procedure will be called by all the TxSet related importing stored procedures
					  to insert the values read from xml into Base.Debit table
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

		--Insert the Credit values into the Debit table
					
		
INSERT INTO [Base].[Debit]
           ([ItemId]
		   ,[Revision]
           ,[InternalTxId]
           ,[SerialNumber]
           ,[DebitId]
           ,[ItemType]
           ,[Currency]
           ,[Amount]
           ,[AccountNumber]
           ,[Sortcode]
           ,[TranCode]
           ,[RicherDataRef]
           ,[Day1ResponseStartDateTime]
           ,[Day1ResponseEndDateTime]
           ,[Day2ResponseStartDatetime]
           ,[Day2ResponseEndDateTime]
		   ,[PayReason] 
		   ,[SettlementPeriodId]  
		   ,[FraudStatusCode]     
		   ,[FraudReasonCode]	
           ,[OnUs]
           ,[Represent]
           ,[HighValue]
		   ,[PayDecision] 
           ,[RepairedSortcode]
           ,[RepairedAccount]
           ,[RepairedAmount]
           ,[RepairedSerial]
           ,[RepairedReference]
           ,[DefaultedSortcode]
           ,[DefaultedAccount]
		   ,[DefaultedSerialNumber]
		   ,[SwitchedSortCode]
		   ,[SwitchedAccount] 
           ,[TSetID]
           ,[TSetIDWithVersion]
		   )
SELECT	
			X.[ItemId]
		   ,X.[Revision]
           ,X.[TXId]
           ,X.[SerialNumber]
           ,X.[DebitId]
           ,X.[ItemType]
           ,X.[Currency]
           ,X.[Amount]
           ,X.[AccountNumber]
           ,X.[Sortcode]
           ,X.[TranCode]
           ,X.[RicherDataRef]
           ,X.[Day1ResponseStartDateTime]
           ,X.[Day1ResponseEndDateTime]
           ,X.[Day2ResponseStartDatetime]
           ,X.[Day2ResponseEndDateTime]
		   ,X.[PayReasonCode]
		   ,X.[SettlementPeriodId]
		   ,X.[FraudStatusCode]
		   ,X.[FraudReasonCode]	        
           ,X.[OnUs]
           ,X.[Represent]
           ,X.[HighValue]
		   ,X.[PayDecision] 
           ,X.[RepairedSortcode]
           ,X.[RepairedAccount]
           ,X.[RepairedAmount]
           ,X.[RepairedSerial]
           ,X.[RepairedReference]
           ,X.[DefaultedSortcode]
           ,X.[DefaultedAccount]
		   ,X.[DefaultedSerialNumber]
		   ,X.SwitchedSortCode		
		   ,X.SwitchedAccount
		   ,X.[TransactionSetId]
		   ,X.[TSetIDWithVersion] 	 
			FROM @DebitHolder X

END TRY
	
	BEGIN CATCH
		THROW;
	END CATCH

END
GO

/*
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'Short_Term_Archive', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', 
	@value = N'This stored procedure will be called by all the TxSet related importing stored procedures
			   to insert the values read from xml into Base.Debit table', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit';


GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'1.0.0', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit';
*/