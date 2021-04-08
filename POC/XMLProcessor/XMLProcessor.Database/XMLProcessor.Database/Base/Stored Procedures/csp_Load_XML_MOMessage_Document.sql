CREATE PROCEDURE [Base].[csp_Load_XML_MOMessage_Document]
	@TVPDocument [Base].[tv_Document_New] READONLY
/*****************************************************************************************************
* Name				: [Base].[[csp_Load_XML_MOMessage_Document]]
* Description		: Stored Procedure to load the Document node into the Image Archive
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
		
        INSERT INTO [Base].[Document] 
					(   [DocumentId] ,
                        [ParticipantId] ,
                        [SubmissionDate] ,
                        [Mechanism] ,
                        [SubmissionCounter] ,
                        [CreatedDate] ,
                        [NumberOfEntries] ,
                        [ReceiverParticipantId] ,
                        [SenderParticipantId] ,
                        [ChargedParticipantId] ,
                        [DocumentType] ,
                        [Signature] ,
                        [XMLMessageId] ,
                        [TestFlag],
						[DocumentMessageID]
                    )
					SELECT
							 [DocumentId]           
							,[ParticipantId]       
							,[SubmissionDate]       
							,[Mechanism]           
							,[SubmissionCounter]     
							,[CreatedDate]         
							,[NumberOfEntries]      
							,[ReceiverParticipantId]
							,[SenderParticipantId]  
							,[ChargedParticipantId] 
							,[DocumentType]        
							,[Signature]
							,[XMLMessageId]				         
							,[TestFlag]             
							,[DocumentMessageID]	
					FROM @TVPDocument
    
	END TRY
	
	BEGIN CATCH
		THROW;
	END CATCH 


					
END

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