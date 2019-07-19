/*****************************************************************************************************
* Name              : [Posting].[usp_PRRM01AltRespSendToMO]
* Description       : This stored proc send the alternate response XML back to MO.
*					  It reads posting data from [Staging].[ResponseEntityAltResponse].
* Author  			: Nick Allbury
*******************************************************************************************************
*Parameter Name				Type							   Description
*------------------------------------------------------------------------------------------------------
 @ResponseID			    variable					       Response ID  
 @FileType					variable						   File Type
********************************************************************************************************
* Amendment History
*------------------------------------------------------------------------------------------------------
* Version 		ID          Date         Name           Reason
*******************************************************************************************************
* 1.0.0			001         03/02/2017 	 Nick		    Initial creation (based on PRRM01)
* 1.0.1			001         03/02/2017 	 Nick		    [Posting].[sfn_AltResponseEntityState] replaced
*                                                       with direct read from [Config].[ResponseEntityMap]
*********************************************************************************************************/
CREATE PROCEDURE [Posting].[usp_PRRM01AltRespSendToMO] (@ResponseID INT, @FileType VARCHAR(50))
AS

BEGIN

	SET NOCOUNT ON;

	BEGIN TRY

		EXEC [Base].[Usp_LogEvent] 1,
								   '[Posting].[usp_PRRM01SendToMO]',
								   'Enter';  
		DECLARE @RNEMOID INT
		DECLARE @Sequence VARCHAR(6)
		DECLARE @FileVersion VARCHAR(2)
		DECLARE @FileID VARCHAR(50)
		DECLARE @EntityDetails XML;
		DECLARE @PostingResponse XML;
		DECLARE @PostingResponseRecord XML;
		DECLARE @PRRM01 XML(Posting.PRRM01);

		BEGIN

			SELECT TOP 1 
				@Sequence = 
					[HeaderSequence]
					,@RNEMOID = RNEMOID
					,@FileVersion = [HeaderVersion]
					,@FileID = REPLACE([ResponseFileID],'.xml','') 
			FROM 
				[Posting].[RNEPostingResponse] 
			WHERE 
				[ResponseID] = @ResponseID  

			SELECT 
				@PostingResponseRecord =
					(
						SELECT
							[ResponseSequence]     "ResponseSequence"
							,[ResponseTransID]      "ItemId"
							,[ResponsePostType]     "PostingType"
							,[ResponseAccNum]       "Account"
							,[ResponseSortCode]     "SortCode"
							,[ResponseNPAAccNum]    "NPAAccount"
							,[ResponseNPASortCode]  "NPASortCode"
							,[ResponseAmount]       "Amount"
							,[ResponseRedirInd]     "RedirectionInd"
							,[ResponseAccSystem]    "AccountingSystem"
							,[ResponseStatus]       "ResponseStatus"
							,[ResponseSubType]      "ResponseSubType"
							,[ResponseStatusCnt]    "StatusCount"
							,[ResponseAggregationCnt] "AggregationCount"
							,[ResponseDDRichDataRef] "ResponseDetail/RicherDataRef"
							,[ResponseDDFraudStatusCode] "ResponseDetail/FraudStatusCode"
							,[ResponseDDFraudReasonCode] "ResponseDetail/FraudReasonCode"
							,[ResponseDDCreditRef] "ResponseDetail/CreditReference"
							,[Posting].[sfn_SelectResponseStatus](@ResponseID,[ResponseSequence])
						FROM  
							Posting.vw_PostingResponseRecord 
						WHERE 
							[ResponseID] = @ResponseID
						ORDER BY 
							[ResponseSequence]  
						FOR XML PATH('PostingResponseRecord') , TYPE
					)

			SELECT @PostingResponse = 
			(
				SELECT 
					[ResponseFileID] "FileId",
					[HeaderSequence] "FileSequenceNumber",
					[HeaderSource] "Source",
					[HeaderFileDate] "FileDateTime",
					[TrailerTransCount] "ExtractItemCount",
					@PostingResponseRecord
				FROM 
					Posting.vw_RNEPostingResponse 
				WHERE 
					[ResponseID] = @ResponseID  
				FOR 
					XML PATH('PostingResponse') , ROOT('PostingUpdate'), TYPE
			)

			SELECT DISTINCT 
				ResponseSequence,
				RP.ResponseTransID,
				EntityState
			INTO
				#RESP
			FROM 
				[Posting].[RNEPostingResponse] rp
			INNER JOIN 
				[Config].[ResponseEntityMap] re
			ON 
				rp.ResponsePostType = re.PostingType
			AND 
				ISNULL(rp.ResponseSubType,'NA') = ISNULL(ISNULL(re.ResponseSubType,rp.ResponseSubType),'NA')
			AND 
				FileType = 'AlternatePostingResponse'
			AND 
				rp.ResponseStatus = re.ResponseStatus	
			WHERE 
				[ResponseID] = @ResponseID
			AND 
				[FileType] = @FileType
			AND 
				CASE 
					WHEN rp.ResponseAggregationCnt > 1 
					THEN '>1' 
					ELSE '1' 
				END = re.AggregationCount

			CREATE NONCLUSTERED INDEX nci_ResponseTransID ON #RESP(ResponseTransID)

			SELECT 
				EntityId
				,RNK
			INTO
				#MAX_CORE
			FROM 
				(
					SELECT
						EntityId
						,ROW_NUMBER() OVER(PARTITION BY EntityIdentifier ORDER BY EntityId DESC) RNK 
					FROM 
						Staging.ResponseEntityAltResponse
				) A 
			WHERE 
				RNK = 1

			CREATE NONCLUSTERED INDEX nci_EntityId ON #MAX_CORE(EntityId)

			SELECT 
				@EntityDetails = 
					(
						SELECT 
							EntityType AS "EntityType",
							CASE 
								WHEN EntityType = 'I' AND DATALENGTH(EntityIdentifier) = 25 THEN EntityIdentifier
								WHEN EntityType = 'D' AND DATALENGTH(EntityIdentifier) = 25 THEN EntityIdentifier
								WHEN EntityType = 'T' AND DATALENGTH(EntityIdentifier) = 25 THEN EntityIdentifier
								ELSE '.....'	 
							END  AS "EntityId",  
							Revision AS "StateRevision",
							RP.EntityState AS "EntityState",
							SourceDateTime AS "SourceDateTime"
						FROM 
							[Staging].[ResponseEntityAltResponse] En 
						INNER JOIN 
							#RESP RP
						ON 
							RP.ResponseTransID = En.EntityIdentifier
						INNER JOIN 
							#MAX_CORE MX 
						ON 
							En.EntityId = MX.EntityId
						FOR 
							XML PATH('Entity'),ROOT('Entities') ,TYPE
					)	

			SELECT 
				@PRRM01 = 
					( 
						SELECT  
							BusinessDate AS "Core/BusinessDate",  
							ExtractId  AS "Core/ExtractId",
							ProcessingParticipantId AS "Core/ProcessingParticipantId",
							ExtMessageType AS "Core/ExtMessageType",
							IntMessageType AS "Core/IntMessageType",
							MessageSource AS "Core/MessageSource",
							MessageDestination AS "Core/MessageDestination",						
							RecordCounts AS "Core/RecordCounts",
							@EntityDetails,
							@PostingResponse
						FROM  
							Posting.vw_RNEPostingResponse_Hdr 
						WHERE 
							[ResponseID] = @ResponseID  
						FOR 
							XML PATH('ICN') , TYPE
					)

			SELECT @PRRM01

			INSERT INTO 
				[Posting].[RNEMOQueueDetails]
				(
					[RNEMOID],
					BusinessDate,
					ExtractId,
					PostingID,
					ProcessingParticipantId,
					ExtMessageType,
					IntMessageType,
					MessageSource,
					MessageDestination,
					RecordCount,
					[Sequence],
					[Version],
					[MessageXML],
					[FileID],
					[DateCreated],
					[Status],
					[CreatedBy]
				)
			SELECT         
				@RNEMOID  AS ID,
				BusinessDate,
				ExtractId,
				PostingId,
				ProcessingParticipantId,
				ExtMessageType,
				IntMessageType,
				MessageSource,
				MessageDestination,
				RecordCounts,
				@Sequence  [Sequence],
				@FileVersion  [Version],
				@PRRM01 AS MessageXML, 
				@FileID,
				GETDATE() AS DateCreated,
				'C' Status,
				CURRENT_USER CreatedBy 
			FROM
				(
					SELECT 
						hdrRec.value('BusinessDate [1]','VARCHAR(26)' ) BusinessDate,
						hdrRec.value('ExtractId [1]','VARCHAR(26)' ) ExtractId,
						hdrRec.value('ExtractId [1]','VARCHAR(26)' ) AS PostingId,
						hdrRec.value('ProcessingParticipantId [1]','VARCHAR(6)' ) ProcessingParticipantId,
						hdrRec.value('ExtMessageType [1]','VARCHAR(6)' ) ExtMessageType,
						hdrRec.value('IntMessageType [1]','VARCHAR(6)' ) IntMessageType,
						hdrRec.value('MessageSource [1]','VARCHAR(6)' ) MessageSource,
						hdrRec.value('MessageDestination [1]','VARCHAR(6)' ) MessageDestination,
						hdrRec.value('RecordCounts [1]','VARCHAR(8)' ) AS RecordCounts
					FROM 
						@PRRM01.nodes('//ICN/Core') Core(hdrRec) 
				) A

			EXEC [Base].[Usp_LogEvent] 2,
								   '[Posting].[usp_PRRM01SendToMO]', 'Sending Message To MO'; 

			DECLARE @DialogHandle UNIQUEIDENTIFIER;
			DECLARE @Request VARCHAR(MAX);
            
			BEGIN DIALOG 
				@DialogHandle
			FROM 
				SERVICE [/RNE/Posting/InitiatorServiceMO]
			TO 
				SERVICE '/MO/Posting/ReceiverService'
			ON 
				CONTRACT [//MO/Posting/Contract]
			WITH 
				ENCRYPTION = OFF;

			SEND ON CONVERSATION 
				@DialogHandle
			MESSAGE TYPE [//RNE/Posting/SendResponseMessageTypeMO] 
				(@PRRM01);
			
		END

		EXEC [Base].[Usp_LogEvent] 1,
								   '[Posting].[usp_PRRM01SendToMO]', 'Exit'; 	
	END TRY	  

	BEGIN CATCH

		DECLARE @Number INT = ERROR_NUMBER();
		DECLARE @Message VARCHAR(MAX) = ERROR_MESSAGE();
		DECLARE @UserName VARCHAR(256) = CONVERT(SYSNAME, CURRENT_USER);
		DECLARE @Severity INT = ERROR_SEVERITY();
		DECLARE @State INT = ERROR_STATE();
		DECLARE @Type VARCHAR(128) = 'Stored Procedure';
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Source VARCHAR(MAX) = ERROR_PROCEDURE();

		EXEC [Base].[Usp_LogException] @Number,
									   @Message,
									   @UserName,
									   @Severity,
									   @State,
									   @Type,
									   @Line,
									   @Source;
		INSERT INTO 
			[Posting].[RNEMOQueueDetails]
			(
				[RNEMOID],
				BusinessDate,
				ExtractId,
				PostingId,
				ProcessingParticipantId,
				ExtMessageType,
				IntMessageType,
				MessageSource,
				MessageDestination,
				RecordCount,
				[Sequence],
				[Version],
				[MessageXML],
				[FileID],
				[DateCreated],
				[Status],
				[CreatedBy]
			)
		SELECT         
			@RNEMOID AS ID,
			BusinessDate,
			ExtractId,
			PostingId,
			ProcessingParticipantId,
			ExtMessageType,
			IntMessageType,
			MessageSource,
			MessageDestination,
			RecordCounts,
			@Sequence  [Sequence],
			@FileVersion  [Version],
			NULL AS MessageXML,
			@FileID, 
			GETDATE() AS DateCreated,
			'E' Status,
			CURRENT_USER CreatedBy 
		FROM
			(
				SELECT 
					hdrRec.value('BusinessDate [1]','VARCHAR(26)' ) BusinessDate,
					hdrRec.value('ExtractId [1]','VARCHAR(26)' ) ExtractId,
					hdrRec.value('ExtractId [1]','VARCHAR(26)' ) AS PostingId,
					hdrRec.value('ProcessingParticipantId [1]','VARCHAR(6)' ) ProcessingParticipantId,
					hdrRec.value('ExtMessageType [1]','VARCHAR(6)' ) ExtMessageType,
					hdrRec.value('IntMessageType [1]','VARCHAR(6)' ) IntMessageType,
					hdrRec.value('MessageSource [1]','VARCHAR(6)' ) MessageSource,
					hdrRec.value('MessageDestination [1]','VARCHAR(6)' ) MessageDestination,
					hdrRec.value('RecordCounts [1]','VARCHAR(8)' ) AS RecordCounts
				FROM 
					@PRRM01.nodes('//ICN/Core') Core(hdrRec) 
			) A;

		THROW;

	END CATCH;

END;

GO

EXEC sys.sp_addextendedproperty @name=N'Component', @value=N'iPSL.ICE.RNE.Database' , @level0type=N'SCHEMA',@level0name=N'Posting', @level1type=N'PROCEDURE',@level1name=N'usp_PRRM01AltRespSendToMO'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Sends the alternate response XML back to MO' , @level0type=N'SCHEMA',@level0name=N'Posting', @level1type=N'PROCEDURE',@level1name=N'usp_PRRM01AltRespSendToMO'
GO

EXEC sys.sp_addextendedproperty @name=N'Version', @value=N'1.0.1' , @level0type=N'SCHEMA',@level0name=N'Posting', @level1type=N'PROCEDURE',@level1name=N'usp_PRRM01AltRespSendToMO'
GO


