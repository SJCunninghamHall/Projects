CREATE PROCEDURE [Base].[csp_Load_XML_MOMessage_TSet]
	@TVPTxSet Base.[tv_TxSet] READONLY
/*****************************************************************************************************
* Name				: [Base].[csp_Load_XML_MOMessage_TSet]
* Description		: Stored Procedure to load the TSet node data into the Image Archive
* Type of Procedure : Natively Compiled stored procedure
* Author			: Anton Richards
* Creation Date		: 26/09/2016
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
		
	INSERT INTO [Base].[TXSet]
				   ([DocumentId]
				   ,[InternalTxId]
				   ,[CollectingPId]
				   ,[TXIdDate]
				   ,[Source]
				   ,[Sequence]
				   ,[Version]
				   ,[CollectingParticipantId]
				   ,[CaptureDate]
				   ,[TSetSubmissionDateTime]
				   ,[AltSource]
				   ,[NumberOfItems]
				   ,[EndPointId]
				   ,[CollectingBranchLocation]
				   ,[CollectingLocation]
				   ,[ChannelRiskType]
				   ,[ChannelDescription]
				   ,[CollectionPoint]
				   ,[CollectionBranchRef]
				   ,[FraudCheckOnly]
				   ,[TransactionSetIdWithVersion]
				   ,[TransactionSetId]
				   )
	SELECT		
			[DocumentId]
			,[InternalTXId]
			,[CollectingPId]
			,[TXIdDate]
			,[Source]
			,[Sequence]
			,[Version]
			,[CollectingParticipantId]
			,[CaptureDate]
			,[TSetSubmissionDateTime]
			,[AltSource]
			,[NumberOfItems]
			,[EndPointId]
			,[CollectingBranchLocation]
			,[CollectingLocation]
			,[ChannelRiskType]
			,[ChannelDescription]
			,[CollectionPoint]
			,[CollectionBranchRef]
			,[FraudCheckOnly]
			,[TransactionSetIdWithVersion]
			,[TransactionSetId]
	FROM @TVPTxSet
    
	END TRY
	
	BEGIN CATCH
		THROW;
	END CATCH 


					
END
GO

/*
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'STAR', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_TSet';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', 
	@value = N'This stored procedure will be called by all the TSet related importing stored procedures 
			   to insert the values read from xml into Base.TXSet table', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_TSet';


GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'1.0.0', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_Load_XML_MOMessage_TSet';
*/