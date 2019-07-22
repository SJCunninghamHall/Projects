CREATE PROCEDURE [Excep].[usp_LoadExceptionAltPostingResponse]
	(
		@ResponseID INT,
		@RneMoID	BIGINT
	)
/*****************************************************************************************************
* Name				: [Excep].[usp_LoadExceptionAltPostingResponse]
* Description		: Loads response data to Excep.PostingResponse for validation
* Called By			: IPSL.RNE.ImportPostingResponseXML.dtsx
* Type of Procedure : Interpreted stored procedure
* Author			: Asish Murali
* Creation Date		: 16/04/2017
* Last Modified		: 
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************/
AS
SET NOCOUNT ON;

	BEGIN TRY

		BEGIN

			SELECT
				[ResponseRecordID]	,
				[ResponseID],
				[RNEMOID],
				ET.ExcepFlag,
				ROW_NUMBER() OVER (PARTITION BY
									PR.[ResponseID],
									PR.ResponseTransID,
									PR.[ResponsePostType],
									PR.[ResponseSequence]
									ORDER BY
									CASE
										WHEN PR.ResponsePostType = 'DEB'
										AND PR.ResponseStatus IN ( 'N' )
										AND RRC.DEWOverrideEntityState IS NOT NULL
										THEN 1
										ELSE 9
									END
								) AS RNK
			INTO
				#ResponseRecord
			FROM
				[Posting].[AltPostingResponse]	AS PR
			INNER JOIN
				[Staging].[TmpAltRespEntity]	AS ET
			ON
				PR.ResponseTransID = ET.ResponseTransID
			AND PR.ResponsePostType = ET.ResponsePostType
			AND PR.ResponseStatus = ET.ResponseStatus
			AND PR.ResponseSequence = ET.ResponseSequence
			LEFT OUTER JOIN
				Config.ResponseReasonCodes		AS RRC
			ON
				PR.ResponseSTReasonCode = RRC.ReasonCode
			AND PR.ResponseStatus = RRC.ResponseStatus
			WHERE
				[ResponseID] = @ResponseID
			AND [RNEMOID] = @RneMoID;


			CREATE NONCLUSTERED INDEX nci_RRID_RID_RNEMOID_RNK
			ON #ResponseRecord (ResponseRecordID, ResponseID, RNEMOID, RNK)
			WHERE RNK = 1;

			SELECT
				PR	.[ResponseRecordID],
				PR.[ResponseID],
				PR.[RNEMOID],
				[ResponseFileID],
				[HeaderSchema],
				PR.[HeaderParticipant],
				PR.[HeaderProcDate],
				[HeaderSequence],
				[HeaderVersion],
				[HeaderSource],
				[HeaderFileDate],
				[HeaderEnvironment],
				PR.[ResponseSequence],
				PR.[ResponseTransID],
				PR.[ResponsePostType],
				[ResponseAccNum],
				[ResponseSortCode],
				[ResponseNPAAccNum],
				[ResponseNPASortCode],
				[ResponseAmount],
				[ResponseRedirInd],
				[ResponseAccSystem],
				PR.[ResponseStatus],
				PR.[ResponseSubType],
				[ResponseStatusCnt],
				[ResponseAggregationCnt],
				[ResponseSTSequence],
				[ResponseSTReasonCode],
				[ResponseSTReasonText],
				[TrailerTransCount]
			FROM
				[Posting].[AltPostingResponse]	AS PR
			INNER JOIN
				#ResponseRecord					AS RR
			ON
				PR.ResponseRecordID = RR.ResponseRecordID
			AND PR.ResponseID = RR.ResponseID
			AND PR.RNEMOID = RR.RNEMOID
			WHERE
				[RR].[RNK] = 1;

		END;
	END TRY
	BEGIN CATCH
		DECLARE @Number INT = ERROR_NUMBER();
		DECLARE @Message VARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @UserName NVARCHAR(128) = CONVERT(sysname, ORIGINAL_LOGIN());
		DECLARE @Severity INT = ERROR_SEVERITY();
		DECLARE @State INT = ERROR_STATE();
		DECLARE @Type VARCHAR(128)	= 'Stored Procedure';
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Source VARCHAR(128)	= ERROR_PROCEDURE();
		EXEC [Base].[usp_LogException]
			@Number,
			@Message,
			@UserName,
			@Severity,
			@State,
			@Type,
			@Line,
			@Source;
		THROW;
	END CATCH;
GO
GRANT
	EXECUTE
ON OBJECT::[Excep].[usp_LoadExceptionAltPostingResponse]
TO
	[RNESVCAccess]
AS [dbo];


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Excep',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_LoadExceptionAltPostingResponse';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This Procedure will load all Response Data to the Excep.PostingAltResponse Table which will be used for validation',
	@level0type = N'SCHEMA',
	@level0name = N'Excep',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_LoadExceptionAltPostingResponse';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'iPSL.ICE.RNE.Database',
	@level0type = N'SCHEMA',
	@level0name = N'Excep',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_LoadExceptionAltPostingResponse';

