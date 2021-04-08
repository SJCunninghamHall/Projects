CREATE PROCEDURE [Excep].[usp_UpdateStagingTmpAltRespEntity]
	(
		@ResponseID INT,
		@RneMoID	BIGINT,
		@FileType	VARCHAR(50)
	)
/*****************************************************************************************************
* Name				: [Excep].[UpdateStagingTmpAltRespEntity]
* Description		: ?
* Called By			: IPSL.RNE.ImportAlternateResponse.dtsx 
* Type of Procedure : Interpreted stored procedure
* Author			: Asish Murali
* Creation Date		: 16/06/2017
* Last Modified		: 27/09/2017 (NPASortCodeExpected exception logic)
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************/
AS
SET NOCOUNT ON;

BEGIN TRANSACTION;

	BEGIN TRY

		DECLARE @Number INT;
		DECLARE @Message VARCHAR(4000);
		DECLARE @UserName NVARCHAR(128);
		DECLARE @Severity INT;
		DECLARE @State INT;
		DECLARE @Type VARCHAR(128)	= 'Stored Procedure';
		DECLARE @Line INT;
		DECLARE @Source VARCHAR(128)	= 'usp_UpdateStagingTmpAltRespEntity';
		DECLARE @BusinessDate DATE;
		DECLARE @EM299AggText VARCHAR(10);

		SELECT
			@BusinessDate	= CONVERT(DATE, BusinessDate)
		FROM
			Config.ProcessingDate;
		SET @EM299AggText =
			(
				SELECT
					ConfigValue
				FROM
					Config.ApplicationConfig
				WHERE
					ConfigType	= 'EM299ExceptionResponse'
				AND ConfigParameter = 'AggResponseText'
			);

		-- Identify duplicate items in file

		SELECT
			ResponseTransID,
			ResponsePostType
		INTO
			#DuplicateValues
		FROM
			Staging.TmpAltRespEntity
		GROUP BY
			ResponseTransID,
			ResponsePostType
		HAVING
			COUNT(1) > 1;


		CREATE NONCLUSTERED INDEX nci_ResponseTransID_ResponsePostType
		ON #DuplicateValues (ResponseTransID, ResponsePostType);


		-- Set exception flag to force removal of duplicate items from PRRM01
		UPDATE
			ET
		SET
		ExcepFlag	=
				(
					SELECT
						[ExceptionID]
					FROM
						[Config].[ValidateException]
					WHERE
						ExceptionName = 'DuplicateSameFile'
				)
		FROM
			[Staging].[TmpAltRespEntity]	AS ET
		INNER JOIN
			#DuplicateValues				AS DV
		ON
			ET.ResponseTransID = DV.ResponseTransID
		AND ET.ResponsePostType = DV.ResponsePostType;



		SELECT
			SortCode,
			AccountNumber,
			COUNT(1)			AS ItemCount,
			SUM(RecordAmount)	AS RecordAmount
		INTO
			#AggResponse
		FROM
			[Posting].[ExtractResponseDetails]
		WHERE
			ResponseEntityState = 964
		AND AlternateRespEntityState IS NULL
		AND RecordSettDate = @BusinessDate
		GROUP BY
			SortCode,
			AccountNumber;

		CREATE NONCLUSTERED INDEX nci_AccNo_SCode
		ON #AggResponse (AccountNumber, SortCode);

		SELECT
			SUM(ResponseAggregationCnt) AS ResponseItemCount,
			SUM(PR.ResponseAmount)		AS ResponseAmount,
			ResponseAccNum				AS AccountNumber,
			ResponseSortCode			AS SortCode,
			[AG].[ItemCount],
			[AG].[RecordAmount],
			SUM(CASE
						WHEN ResponseAggregationCnt > 1
						OR	PR.ResponseSTReasonText = @EM299AggText
						THEN 1
						ELSE 0
				END
			)						AS AggCount
		INTO
			#AggResp
		FROM
			[Posting].[AltPostingResponse]			AS PR
		INNER JOIN
			#AggResponse							AS AG
		ON
			PR.ResponseAccNum = AG.AccountNumber
		AND PR.ResponseSortCode = AG.SortCode
		INNER JOIN
			Posting.vw_ExtractResponseDetailsLatest AS ER
		ON
			PR.ResponseTransID = ER.ItemIdentifier
		AND PR.ResponsePostType = ER.RecordPostType
		AND ER.ResponseEntityState = 964
		AND PR.ResponseAccNum = ER.AccountNumber
		AND PR.ResponseSortCode = ER.SortCode
		WHERE
			ResponseID	= @ResponseID
		AND RNEMOID = @RneMoID
		AND
		(
				ResponseSTSequence = 1
		OR		ResponseSTSequence IS NULL
			)
		GROUP BY
			ResponseAccNum,
			ResponseSortCode,
			[AG].[ItemCount],
			[AG].[RecordAmount];

		CREATE NONCLUSTERED INDEX nci_AccNo_SCode
		ON #AggResp (AccountNumber, SortCode);

		SELECT
			PR	.ResponseTransID
		INTO
			#INVALID_RTransIds
		FROM
			[Posting].[AltPostingResponse]	AS PR
		LEFT JOIN
			Config.ResponseReasonCodes		AS RRC
		ON
			PR.ResponseSTReasonCode = RRC.ReasonCode
		AND ISNULL(PR.ResponseSubType, 'NA') = ISNULL(RRC.ResponSubType, 'NA')
		WHERE
			RRC.ReasonCode IS NULL
		AND PR.ResponseStatus = 'N'
		AND ResponseID = @ResponseID
		AND RNEMOID = @RneMoID;

		CREATE NONCLUSTERED INDEX nci_ResponseTransID
		ON #INVALID_RTransIds (ResponseTransID);

		UPDATE
			ET
		SET
		ExcepFlag	= ISNULL(
							(
								SELECT	TOP 1
										[ExceptionID]
								FROM
										[Config].[ValidateException]
								WHERE
										(
											(
												ExceptionName = 'NoExtract'
										AND		EP.ItemIdentifier IS NULL
											)
									OR
										(
											ExceptionName = 'NoResponse'
									AND		EP.ResponseFlag IS NULL
									AND		ISNULL(PR.ResponseAggregationCnt, 1) > 1
										)
									OR
										(
											ExceptionName = 'NoAgg'
									AND		ET.IsAggAllowed = 0
									AND		ISNULL(PR.ResponseAggregationCnt, 1) > 1
										)
									OR
										(
											ExceptionName = 'InvalidStatus'
									AND		RE.EntityState IS NULL
										)
									OR
										(
											ExceptionName = 'Acc-SortChg'
									AND		EP.ResponseEntityState = 964
									AND
										(
											PR.ResponseAccNum != EP.AccountNumber
										OR		PR.ResponseSortCode != EP.SortCode
										)
										)
									OR
										(
											ExceptionName = 'AggCnt'
									AND		EP.ResponseEntityState = 964
									AND		EP.AlternateRespEntityState IS NULL
									AND		ISNULL(AG.ResponseItemCount, 1) != ISNULL(ItemCount, 1)
									AND		ET.AltSourceGrpID NOT IN (	3,
																			5
																		)
										)
									OR
										(
											ExceptionName = 'AggCnt'
									AND		EP.ResponseEntityState = 965
									AND		ISNULL(PR.ResponseAggregationCnt, 1) != 1
									AND		ET.AltSourceGrpID NOT IN (	3,
																			5
																		)
										)
									OR
										(
											ExceptionName = 'ExpAgg'
									AND		EP.ResponseEntityState != 964
									AND		ET.IsAggAllowed = 1
									AND		PR.ResponseSTReasonText = @EM299AggText
									AND		ET.AltSourceGrpID = 3
										)
									OR
										(
											ExceptionName = 'ExpAgg'
									AND		EP.ResponseEntityState = 964
									AND		ET.IsAggAllowed = 1
									AND		PR.ResponseSTReasonText != @EM299AggText
									AND		ET.AltSourceGrpID = 3
										)
									OR
										(
											ExceptionName = 'NoAgg'
									AND		EP.ResponseEntityState = 964
									AND		ET.IsAggAllowed != 1
									AND
										(
											PR.ResponseSTReasonText = @EM299AggText
										OR		ISNULL(PR.ResponseAggregationCnt, 1) > 1
										)
										)
									OR
										(
											ExceptionName = 'OneAgg'
									AND		EP.ResponseEntityState = 964
									AND		EP.AlternateRespEntityState IS NULL
									AND		AG.AggCount > 1
										)
									OR
										(
											ExceptionName = 'Amt-Chg'
									AND		EP.ResponseEntityState = 964
									AND		EP.AlternateRespEntityState IS NULL
									AND		PR.ResponseAggregationCnt = 1
									AND		PR.ResponseAmount != EP.RecordAmount
									AND		ET.AltSourceGrpID NOT IN (	3,
																			5
																		)
										)
									OR
										(
											ExceptionName = 'Amt-Chg'
									AND		EP.ResponseEntityState = 964
									AND		EP.AlternateRespEntityState IS NULL
									AND		AG.ResponseAmount != AG.RecordAmount
										)
									OR
										(
											ExceptionName = 'Duplicate'
									AND		ISNULL(EP.ResponseFlag, EP.AltResponseFlag) = 1
									AND		EP.AltResponseFlag = 1
									AND		(CASE ISNULL(ET.ResponseSubType, 'NA')
													WHEN 'R'
													THEN ET.ResponseSubType
													WHEN 'O'
													THEN ET.ResponseSubType
													ELSE ET.ResponseStatus
												END
											) = EP.ResponseStatus
									AND		ISNULL(EP.ExceptionFlag, 0) = 0
									AND		EP.TrigEntityState NOT IN ( 541,
																			543,
																			550,
																			551
																		)
										)
									OR
										(
											ExceptionName = 'NotPending'
									AND		EP.ResponseFlag = 1
									AND		EP.ResponseStatus NOT IN (	'P',
																			'R'
																		)
									AND		EP.TrigEntityState NOT IN ( 541,
																			550,
																			551
																		)
										)
									OR
										(
											ExceptionName = 'InvalidReasonCode'
									AND		IR.ResponseTransID IS NOT NULL
										)
									OR
										(
											ExceptionName = 'NPASortCodeExpected'
									AND		PR.ResponseStatus = 'Y'
									AND		PR.ResponseSubType IS NULL
									AND		EP.NPASortCode IS NULL
										)
									OR
										(
											ExceptionName = 'MultipleQualifier'
									AND		PR.ResponseStatus != 'N'
									AND		ISNULL(PR.ResponseSTReasonCode, '') <> ''
										)
									OR
										(
											ExceptionName = 'InvalidSubType'
									AND		ISNULL(ET.ResponseSubType, 'NA') != ISNULL(RE.ResponseSubType, 'NA')
									AND		ET.ResponseStatus != RE.ResponseStatus
									AND		ET.AltSourceGrpID = RE.AltSourceGrpID
										)
									OR
										(
											ExceptionName = 'InvalidReasonCode'
									AND		ISNULL(ET.ResponseSubType, 'NA') = ISNULL(RE.ResponseSubType, 'NA')
									AND		ET.ResponseStatus = RE.ResponseStatus
									AND		ET.AltSourceGrpID = RE.AltSourceGrpID
									AND
										(
											ET.AltSourceGrpID = 6
										AND		ISNULL(PR.PrevChannel, 0) = 4
										AND		ISNULL(ET.ResponseReasonCode, 'NA') != ISNULL(RE.ReasonCd, 'NA')
										)
										)
									OR
										(
											ExceptionName = 'InvalidStatus'
									AND		ISNULL(ET.ResponseSubType, 'NA') != 'O'
									AND		ET.ResponseStatus = RE.ResponseStatus
									AND		ET.ResponseStatus != 'Y'
									AND		ET.AltSourceGrpID = RE.AltSourceGrpID
									AND		ET.AltSourceGrpID = 6
									AND		ISNULL(ET.ResponseReasonCode, 'NA') != '000007'
										)
									OR
										(
											ExceptionName = 'InvalidStatus'
									AND		ISNULL(ET.ResponseSubType, 'NA') = 'O'
									AND		ET.ResponseStatus = RE.ResponseStatus
									AND		ET.AltSourceGrpID = RE.AltSourceGrpID
									AND		ISNULL(ET.ResponseReasonCode, 'NA') = '000007'
										)
									OR
										(
											ExceptionName = 'PrevChMismatch'
									AND		ISNULL(PR.PrevChannel, 0) != ISNULL(RE.PrevAltSourceGrpID, 0)
									AND		ISNULL(EP.ResponseStatus, 'NA') != 'R'
										)
									OR
										(
											ExceptionName = 'PrevChMismatch'
									AND		ISNULL(PR.PrevChannel, 0) != ISNULL(RE.PrevAltSourceGrpID, 0)
									AND		ET.AltSourceGrpID = 5
										)
									OR
										(
											ExceptionName = 'PrevChMismatch'
									AND		ET.AltSourceGrpID = 3
									AND		ISNULL(PR.PrevChannel, 0) != ISNULL(RE.PrevAltSourceGrpID, 0)
										)
									OR
										(
											ExceptionName = 'SuppresResp'
									AND		ET.AltSourceGrpID = 6
									AND		ISNULL(ET.ResponseSubType, 'NA') != 'O'
										)
										)
							), 0
							)
		FROM
			[Staging].[TmpAltRespEntity]				AS ET
		INNER JOIN
			[Posting].[AltPostingResponse]				AS PR
		ON
			ET.ResponseTransID = PR.ResponseTransID
		AND ET.ResponsePostType = PR.ResponsePostType
		AND ET.ResponseStatus = PR.ResponseStatus
		LEFT JOIN
			[Posting].[vw_ExtractResponseDetailsLatest] AS EP
		ON
			PR.ResponseTransID = EP.ItemIdentifier
		AND EP.RecordPostType = PR.ResponsePostType
		AND ISNULL(EP.ExtractEntityState, 0) = 950
		LEFT JOIN
			#AggResp									AS AG
		ON
			PR.ResponseSortCode = AG.SortCode
		AND PR.ResponseAccNum = AG.AccountNumber
		LEFT JOIN
			Config.AltResponseEntityMap					AS RE
		ON
			ET.ResponsePostType = RE.RespPostType
		AND ISNULL(PR.ResponseSubType, 'NA') = ISNULL(RE.ResponseSubType, 'NA')
		AND PR.ResponseStatus = RE.ResponseStatus
		AND RE.AltSourceGrpID = PR.HeaderFileAltSourceGrpID
		AND RE.EntityType = 'E'
		LEFT JOIN
			#INVALID_RTransIds							AS IR
		ON
			IR.ResponseTransID = PR.ResponseTransID
		AND PR.ResponseStatus = 'N'
		WHERE
			ResponseID	= @ResponseID
		AND RNEMOID = @RneMoID
		AND ISNULL(ET.ExcepFlag, 0) = 0;


		SELECT
			SortCode,
			AccountNumber
		INTO
			#AggAccList
		FROM
			[Posting].[ExtractResponseDetails]	AS ER
		INNER JOIN
			[Staging].[TmpAltRespEntity]		AS ET
		ON
			ER.ItemIdentifier = ET.ResponseTransID
		AND ER.RecordPostType = ET.ResponsePostType
		WHERE
			ResponseEntityState = 964
		AND ISNULL(ET.ExcepFlag, 0) != 0
		GROUP BY
			SortCode,
			AccountNumber;

		CREATE NONCLUSTERED INDEX nci_AccNo_SCode
		ON #AggAccList (AccountNumber, SortCode);

		SELECT
			ItemIdentifier	,
			PR.RecordPostType
		INTO
			#GETAllAggList
		FROM
			[Posting].[ExtractResponseDetails] AS PR
		WHERE
			ResponseEntityState = 964
		AND RecordSettDate = @BusinessDate
		AND PR.AlternateRespEntityState IS NULL
		AND EXISTS
			(
				SELECT
					1
				FROM
					#AggAccList AS PR1
				WHERE
					PR1.AccountNumber = PR.AccountNumber
				AND PR1.SortCode = PR.SortCode
			);


		CREATE NONCLUSTERED INDEX nci_ItemIdentifier_RecordPostType
		ON #GETAllAggList (ItemIdentifier, RecordPostType);


		UPDATE
			ET
		SET
		ExcepFlag	=
				(
					SELECT
						[ExceptionID]
					FROM
						[Config].[ValidateException]
					WHERE
						ExceptionName = 'AggError'
				)
		FROM
			[Staging].[TmpAltRespEntity]	AS ET
		INNER JOIN
			#GETAllAggList					AS GT
		ON
			ET.ResponseTransID = GT.ItemIdentifier
		AND ET.ResponsePostType = GT.RecordPostType
		WHERE
			ISNULL(ET.ExcepFlag, 0) = 0;

		-- Look back at core using account number and sort code to locate and flag any missing NPASortCode for ResponseStatus = 'Y' for aggregated items
		-- The earlier logic deals with non-aggregated items
		DECLARE @ExceptionID INT;
		SET @ExceptionID =
			(
				SELECT
					ExceptionID
				FROM
					[Config].[ValidateException]
				WHERE
					ExceptionName = 'NPASortCodeExpected'
			);

		UPDATE
			TR
		SET
		ExcepFlag	= @ExceptionID
		FROM
			Staging.TmpAltRespEntity	AS TR
		INNER JOIN
			Posting.RNEPostingResponse	AS PR
		ON
			TR.ResponseTransID = PR.ResponseTransID
		INNER JOIN
			(
				SELECT
					AccountNumber,
					SortCode
				FROM
					[Posting].[ExtractResponseDetails] AS ER
				WHERE
					RecordSettDate	= @BusinessDate
				AND ER.ResponseEntityState = 964
				AND ER.NPASortCode IS NULL
				GROUP BY
					AccountNumber,
					SortCode
			)							AS ER
		ON
			PR.ResponseAccNum = ER.AccountNumber
		AND PR.ResponseSortCode = ER.SortCode
		WHERE
			PR.ResponseID = @ResponseID
		AND PR.ResponseStatus = 'Y'
		AND ISNULL(TR.ExcepFlag, 0) = 0;

		IF (XACT_STATE()) = 1
			BEGIN
				COMMIT	TRANSACTION;
			END;

	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0
			ROLLBACK TRANSACTION;

		SELECT
			@Number = ERROR_NUMBER();
		SELECT
			@Message	= ERROR_MESSAGE();
		SELECT
			@UserName	= CONVERT(sysname, ORIGINAL_LOGIN());
		SELECT
			@Severity	= ERROR_SEVERITY();
		SELECT
			@State	= ERROR_STATE();
		SELECT
			@Type	= 'Stored Procedure';
		SELECT
			@Line	= ERROR_LINE();
		SELECT
			@Source = ERROR_PROCEDURE();

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
ON OBJECT::[Excep].[usp_UpdateStagingTmpAltRespEntity]
TO
	[RNESVCAccess];

GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Excep',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_UpdateStagingTmpAltRespEntity';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This Procedure will update Exception Detail on Staging Entity Table',
	@level0type = N'SCHEMA',
	@level0name = N'Excep',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_UpdateStagingTmpAltRespEntity';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'iPSL.ICE.RNE.Database',
	@level0type = N'SCHEMA',
	@level0name = N'Excep',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_UpdateStagingTmpAltRespEntity';

