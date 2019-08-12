CREATE PROCEDURE [Base].[csp_Load_XML_MOMessage_Shredded_Debit_Stopped_New]
	@DebitHolder [Base].[tv_Debit_New] READONLY
/*****************************************************************************************************
* Name				: [Base].[csp_Load_XML_MOMessage_Shredded_Debit_Stopped]
* Description		: Stored Procedure to Load the shreded data to the Stopped table
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

		--Insert the Stopped values into the Stopped table

INSERT INTO [Base].[StoppedItem]
           ([ItemId]
           ,[StoppedDate]
           ,[Status]
           ,[Amount]
           ,[Currency] 
           ,[Beneficiary]
           ,[StopItemStartRange]
           ,[StopItemEndRange])
     SELECT
           x.ItemId			,
			x.StopDate 		    ,
			x.StopStatus 	  ,
			x.StopAmount 	   ,
			x.[StpAmtCurrency],
			x.StopBeneficiary  ,
			x.StopStartRange    ,
			x.StopEndRange 	
          
	FROM @DebitHolder x
	WHERE 
		( 
			x.StopDate IS NOT NULL OR 
			x.StopStatus IS NOT NULL OR
			x.StopAmount IS NOT NULL OR
			x.[StpAmtCurrency] IS NOT NULL OR
			x.StopBeneficiary IS NOT NULL OR
			x.StopStartRange IS NOT NULL OR
			x.StopEndRange IS NOT NULL
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
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit_Stopped';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', 
	@value = N'This stored procedure will be called by all the TxSet related importing stored procedures
			   to insert the values read from xml into Base.StoppedItem table', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit_Stopped';


GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'1.0.0', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit_Stopped';
*/