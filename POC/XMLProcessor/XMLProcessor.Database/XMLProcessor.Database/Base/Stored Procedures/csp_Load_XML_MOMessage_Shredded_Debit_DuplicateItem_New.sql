CREATE PROCEDURE [Base].[csp_Load_XML_MOMessage_Shredded_Debit_DuplicateItem_New]
	@DebitHolder [Base].[tv_Debit_New] READONLY
/*****************************************************************************************************
* Name				: [Base].[csp_Load_XML_MOMessage_Shredded_Debit_DuplicateItem]
* Description		: This stored procedure will be called by all the TxSet related importing stored procedures
					  to insert the values read from xml into Base.DuplicateDebit table
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

		--Insert the Duplicate Debit values into the DuplicateDebit table
INSERT INTO [Base].[DuplicateDebit]
           ([ItemId]
           ,[DuplicateItemId]
           ,[Status]
           ,[DateFirstSeen]
           --,[ParticipantID] NOT YET USED
           ,[OriginalCollectingParticipant]
           ,[OriginalCaptureDate]
           ,[OriginalSource])
    SELECT
           x.ItemId
           ,x.DuplicateItemId
           ,x.DuplicateStatus
           ,x.DateFirstSeen
           ,x.OriginalCollectingParticipant
           ,x.OriginalCaptureDate
           ,x.OriginalSource

	FROM @DebitHolder x
	WHERE 
		( 
			x.DuplicateItemId IS NOT NULL 
		)

END TRY
	
	BEGIN CATCH
		THROW;
	END CATCH

END

/*
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'Short_Term_Archive', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit_DuplicateItem';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', 
	@value = N'This stored procedure will be called by all the TxSet related importing stored procedures
			   to insert the values read from xml into Base.DuplicateDebit table', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit_DuplicateItem';


GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'1.0.0', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_Shredded_Debit_DuplicateItem';
*/