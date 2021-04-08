CREATE PROCEDURE [Base].[csp_Load_XML_MOMessage_ICN_Core_New]  
	@TVPCore [Base].[tv_Core_New] READONLY,
    @XMLMessageId BIGINT

/*****************************************************************************************************
* Name				: [Base].[usp_Load_XML_MOMessage_ICN_Core]
* Description		: This stored procedure will load the Core node of iPSL Custom Node of the incoming MO message. 
					  The OPENXML clause will be used along with the XPATH to access the individual elements of the Core Node.
			          The target table for loading the Core node of the message will be [Base].[Core].
* Type of Procedure : Interpreted stored procedure
* Author			: Pavan Kumar Manneru
* Creation Date		: 04/07/2016
* Last Modified		: N/A
* Parameters		: 5
*******************************************************************************************************
*Parameter Name				Type				Description
*------------------------------------------------------------------------------------------------------
 @iDoc						INT					Handle for the loaded XML Message
 @RoutingId					BIGINT				RoutingID
 @BusinessDate				DATE				BusinessDate
 @CoreId					BIGINT				CoreID OUTPUT PARAMETER
 @ExtractId					VARCHAR(26)			ExtractId OUTPUT PARAMETER
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************
*										History
*------------------------------------------------------------------------------------------------------
* Version	ID		Date			Reason
*******************************************************************************************************
* 1.0.0		001     04-Jul-2016   	Initial version
* 1.0.1		002		17-Sep-2018		Updated SP to return @ExtractId as output parameter
*******************************************************************************************************/
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER 
AS BEGIN ATOMIC WITH (
      TRANSACTION ISOLATION LEVEL = SNAPSHOT,
      LANGUAGE = 'English')

	BEGIN TRY

		INSERT INTO [Base].[Core] (   
									[CoreId] ,
									[ExtractId] ,
									[PostingExtractId] ,
									[ParticipantId] ,
									[MessageType] ,
									[IntMessageType] ,
									[Source] ,
									[Destination] ,
									[RecordCount] ,
									[XMLMessageId]
								)	
								Select	[CoreId],
										[ExtractId] ,
										[PostingExtractId] ,
										[ParticipantId] ,
										[MessageType] ,
										[IntMessageType] ,
										[Source] ,
										[Destination] ,
										[RecordCount] ,
										@XMLMessageId
								FROM @TVPCore

	END TRY
	BEGIN CATCH
		;THROW;
	END CATCH;

END;