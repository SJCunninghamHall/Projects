CREATE PROCEDURE [Base].[csp_Load_XML_MOMessage_Shredded_Debit_ItemUpdate_New]
	@DebitHolder [Base].[tv_Debit_New] READONLY,
	@CoreId BIGINT
/*****************************************************************************************************
* Name				: [Base].[csp_Load_XML_MOMessage_Shredded_Debit_ItemUpdate]
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
					
		
--Insert the Credit values into the ItemUpdate table
		INSERT INTO [Base].[ItemUpdate]
			(
				[InternalId] ,           
				[ItemId]  ,
				[Revision],
				[CoreID]
			)
SELECT	
			X.[ItemId]
           ,X.[DebitId]
           ,X.Revision -- First Revision of the Item
		   ,@CoreId	 
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
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit_ItemUpdate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', 
	@value = N'This stored procedure will be called by all the TxSet related importing stored procedures
			   to insert the values read from xml into Base.Debit table', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit_ItemUpdate';


GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'1.0.0', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit_ItemUpdate';
*/