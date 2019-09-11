CREATE PROCEDURE [Outclearing].[usp_PostingDataExtract]
	(
		@PostingID	VARCHAR(26),
		@SubType	CHAR(1),
		@RneMoID	BIGINT
	)
/*****************************************************************************************************
* Name							: [Outclearing].[usp_PostingDataExtract]
* Description					: Extract posting data from [Outclearing].[PostingPattern]
* Called By						: IPSL.RNE.OutclearingLoadPostingData.dtsx
* Type of Procedure				: Interpreted stored procedure
* Author						: Akuri Reddy 
* Creation Date					: 15/06/2018
*******************************************************************************************************/
AS
SET NOCOUNT ON;

DECLARE
	@SchemaVersion				VARCHAR(10),
	@Participant				VARCHAR(6),
	@ProcessingDate				VARCHAR(20),
	@FileDate					VARCHAR(20),
	@FileSequenceNumber			VARCHAR(4),
	@FileVersion				VARCHAR(2),
	@Weekday					VARCHAR(2),
	@Environment				VARCHAR(1),
	@Currency					VARCHAR(3),
	@CaptureDateFormat			VARCHAR(23),
	@BusinessDate				VARCHAR(10),
	@NextProcessingDate			VARCHAR(10),
	@NPAChannel					VARCHAR(4),
	@JGAccountTranCodes			VARCHAR(10),
	@AggITP						INT,
	@RCOPattern9SortCode		INT,
	@RCOPattern9AccountNumber	INT;

SELECT
	@SchemaVersion				=
	(
		SELECT
			[ConfigValue]
		FROM
			[Config].[ApplicationConfig]
		WHERE
			ConfigType	= 'PostingRequest'
		AND [ConfigParameter] = 'SchemaVersion'
	),
	@Participant				=
	(
		SELECT
			[ConfigValue]
		FROM
			[Config].[ApplicationConfig]
		WHERE
			ConfigType	= 'PostingRequest'
		AND [ConfigParameter] = 'ParticipantID'
	),
	@ProcessingDate				= CONVERT(	VARCHAR(19),
	(
		SELECT
			CAST(BusinessDate AS DATE)
		FROM
			[Config].[ProcessingDate]
	),							126
										),
	@FileDate					= CONVERT(VARCHAR(19), GETUTCDATE(), 126),
	@FileSequenceNumber			=
	(
		SELECT
			Posting.sfn_pad_string(MOSequence, '0', 4, 0)
		FROM
			Posting.RNEMOQueueDetails
		WHERE
			RNEMOID = @RneMoID
	),
	@FileVersion				= 1,
	@Weekday					= UPPER(LEFT(FORMAT(
												(
													SELECT
															CAST(BusinessDate AS DATE)
													FROM
															[Config].[ProcessingDate]
												), 'ddd'
												), 2)
									),
	@BusinessDate				=
	(
		SELECT
			CONVERT(VARCHAR(10), BusinessDate, 121)
		FROM
			[Config].[ProcessingDate]
	),
	@NextProcessingDate			=
	(
		SELECT
			CONVERT(VARCHAR(10), NextDate, 121)
		FROM
			[Config].[ProcessingDate]
	),
	@Environment				=
	(
		SELECT
			[ConfigValue]
		FROM
			[Config].[ApplicationConfig]
		WHERE
			ConfigType	= 'PostingRequest'
		AND [ConfigParameter] = 'Environment'
	),
	@Currency					=
	(
		SELECT
			[ConfigValue]
		FROM
			[Config].[ApplicationConfig]
		WHERE
			ConfigType	= 'PostingRequest'
		AND [ConfigParameter] = 'Currency'
	),
	@CaptureDateFormat			=
	(
		SELECT
			DtFormat
		FROM
			[Config].[PostingCustomDateFormatting]
		WHERE
			ColumnName	= 'CaptureDate'
	),
	@NPAChannel					=
	(
		SELECT
			[ConfigValue]
		FROM
			[Config].[ApplicationConfig]
		WHERE
			ConfigType	= 'PostingRequest'
		AND [ConfigParameter] = 'NPAChannel'
	),
	@JGAccountTranCodes			=
	(
		SELECT
			[ConfigValue]
		FROM
			[Config].[ApplicationConfig]
		WHERE
			ConfigType	= 'JGAccount'
		AND ConfigParameter = 'EligibleJGAccountTranCodes'
	),
	@AggITP						=
	(
		SELECT
			[ConfigValue]
		FROM
			[Config].[ApplicationConfig]
		WHERE
			ConfigType	= 'PostingRequest'
		AND [ConfigParameter] = 'AggITP'
	),
	@RCOPattern9SortCode		=
	(
		SELECT
			[ConfigValue]
		FROM
			[Config].[ApplicationConfig]
		WHERE
			ConfigType	= 'RCOPattern9'
		AND [ConfigParameter] = 'SortCode'
	),
	@RCOPattern9AccountNumber	=
	(
		SELECT
			[ConfigValue]
		FROM
			[Config].[ApplicationConfig]
		WHERE
			ConfigType	= 'RCOPattern9'
		AND [ConfigParameter] = 'AccountNumber'
	);

	BEGIN	TRY

		BEGIN

			SELECT
				C.CreditId,
				C.Sortcode,
				--C.AccountNumber,
				IIF(
					(
						(ISNULL(LTRIM(RTRIM(C.TranCode)), LTRIM(RTRIM(C.TranCode_New)))) IN
							(
								SELECT
									[value]
								FROM
									STRING_SPLIT(@JGAccountTranCodes, ',')
							)
				AND		C.[JGAccount] IS NOT NULL
					),
					('0' + RIGHT(C.[JGAccount], 7)),
					C.AccountNumber)	AS AccountNumber,
				C.Reference,
				C.Amount,
				C.OriginalAmount_ISO,
				C.OriginalAmount_Dew,
				cf_NPASortcode,
				TranCode,
				DebitReference,
				TransactionSetId,
				EntityState,
				ROW_NUMBER() OVER (PARTITION BY
									CreditId,
									TransactionSetId
									ORDER BY
									InternalId DESC
								)	AS CrRank
			INTO
				#Credits
			FROM
				Outclearing.Credit AS C
			WHERE
				PostingID = @PostingID;

			CREATE NONCLUSTERED INDEX nci_TransactionSetId
			ON #Credits (TransactionSetId)
			WHERE CrRank = 1;

			SELECT
				Cr	.TransactionSetId,
				Cr.CreditId,
				Cr.Sortcode				AS Sortcode_Cr,
				Cr.AccountNumber		AS AccountNumber_Cr,
				Cr.Reference			AS Reference_Cr,
				Cr.Amount				AS Amount_Cr,
				Cr.OriginalAmount_ISO	AS OriginalAmount_ISO_Cr,
				Cr.OriginalAmount_Dew	AS OriginalAmount_Dew_Cr,
				Cr.cf_NPASortcode		AS cf_NPASortcode_Cr,
				Cr.TranCode				AS TranCode_Cr,
				Cr.DebitReference		AS DebitReference_Cr,
				Cr.EntityState			AS EntityState_Cr,
				D.DebitId,
				D.Sortcode,
				D.AccountNumber,
				D.SerialNumber,
				D.Amount,
				D.OriginalAmount_ISO,
				D.OriginalAmount_Dew,
				D.TranCode,
				D.cf_NPASortcode,
				D.SwitchedSortCode,
				D.SwitchedAccount,
				D.DebitReference,
				D.InternalTxId,
				D.ItemType,
				D.EntityState,
				ROW_NUMBER() OVER (PARTITION BY
									Cr.CreditId,
									D.DebitId,
									D.TransactionSetId
									ORDER BY
									D.InternalId DESC
								)	AS DrRank
			INTO
				#CreditsDebits
			FROM
				#Credits			AS Cr
			INNER JOIN
				Outclearing.Debit	AS D
			ON
				D.TransactionSetId = Cr.TransactionSetId
			AND Cr.CrRank = 1
			WHERE
				D.PostingID = @PostingID;


			CREATE NONCLUSTERED INDEX nci_CI_DI_DR
			ON #CreditsDebits (CreditId, DebitId, DrRank)
			WHERE DrRank = 1;

			CREATE NONCLUSTERED INDEX nci_TransactionSetId
			ON #CreditsDebits (TransactionSetId);


			INSERT INTO
				Posting.RNEPostingExtract
				(
					[RneMoID],
					[PostingID],
					----Posting Header---------
					[HeaderSchema],
					[HeaderParticipant],
					[HeaderProcDate],
					[HeaderSequence],
					[HeaderVersion],
					[HeaderFileDate],
					[HeaderWeekDay],
					[HeaderType],
					[HeaderCurrency],
					[HeaderEnvironment],
					----Posting Record------- 
					[EntityIdentifier],
					[PostingIdentifier],
					[ItemIdentifier],
					[RecordSequence],
					[RecordPostType],
					[RecordSubType],
					[RecordSourceMsg],
					[RecordChannel],
					[RecordEntryType],
					[RecordPostSource],
					[RecordRespSource],
					[RecordPostDay],
					[RecordClearDate],
					[RecordSettDate],
					[RecordCaptDate],
					[RecordAmount],
					[RecordTranSetID],
					[RecordReason],
					[RecordOverride],
					[RecordNPASort],
					[RecordSuppInfo],
					[RecordNumCheques],
					[RecordCollPart],
					[RecordCollLoc],
					---------Debit Record-----
					[DebitTransID],
					[DebitSortCode],
					[DebitAccNum],
					[DebitSerNum],
					[DebitTranCode],
					[DebitSwitchSort],
					[DebitSwitchAcc],
					[DebitFullAmt],
					---------Credit Record --------------
					[CreditTransID],
					[CreditSortCode],
					[CreditAccNum],
					[CreditRef],
					[CreditTransCode],
					[CreditOrigAmt],
					[ExtractRecord],
					----------Miscelleneous Records-------
					[OutclearingPatternID],
					[OutclearingTrigEntityState],
					[OutclearingExtractEntityState],
					[TransactionSetIdWithVersion],
					[DebitItemType]
				)
			SELECT
				@RnEMoID																							AS RneMoID,
				@PostingID																							AS PostingID,

																																			----Posting Header---------
				@SchemaVersion																						AS SchemaVersion,
				@Participant																						AS Participant,
				@ProcessingDate																						AS ProcessingDate,
				@FileSequenceNumber																					AS FileSequenceNumber,
				@FileVersion																						AS FileVersion,
				@FileDate																							AS FileDateandTime,
				@Weekday																							AS "Weekday",
				@SubType																							AS FileType,
				@Currency																							AS Currency,
				@Environment																						AS Environment,

																																			----Posting Record------- -Fix given based on 194816 bug

				CASE
					WHEN @AggITP = 0
					AND PP.IsMultiCrdts = 1
					AND PP.PatternID = 1
					THEN crdr.CreditID
					ELSE PP.ItemIdentifier
				END																									AS EntityIdentifier,
				NULL																								AS PostingIdentifier,
				CASE
					WHEN @AggITP = 0
					AND PP.IsMultiCrdts = 1
					AND PP.PatternID = 1
					THEN crdr.CreditID
					ELSE IIF(PP.IsPostingOnCredit = 1, crdr.CreditID, crdr.DebitID)
				END																									AS ItemIdentifier,
				RIGHT(CONCAT(	REPLICATE('0', 6), ROW_NUMBER() OVER (ORDER BY
																		@PostingID
																	)
							), 6)																				AS PostingSeq,
				PP.PostingType,
				'Outclearing'																						AS PostingSubType,
				CASE
					WHEN
						(
							PP.PostingType = 'REJ'
					AND		Tx.EntityState = 130
						)
					THEN 'MSG03'
					WHEN
						(
							PP.PostingType = 'REJ'
					AND		Tx.EntityState IN ( 30,
												60	,
												90
											)
						)
					THEN 'MSG01'
					ELSE 'MSG01'
				END																									AS SourceMsg,
				CASE
					WHEN PP.PostingType IN ( 'NPA' )
					AND @NPAChannel IS NOT NULL
					THEN @NPAChannel
					ELSE CONVERT(VARCHAR(4), Tx.AltSource)
				END																									AS Channel,
				CASE
					WHEN PP.PostingType IN ( 'ITP',
											'REJ'
										)
					THEN 'Debit'
					WHEN
						(
							PP.IsPostingOnCredit = 0
					AND		PP.PostingType = 'NPA'
						)
					THEN 'Debit'
					ELSE 'Credit'
				END																									AS CredDebInd,
				CASE
					WHEN @AggITP = 0
					AND PP.IsMultiCrdts = 1
					AND PP.PatternID = 1
					THEN 'Credit'
					ELSE IIF(PP.IsPostingOnCredit = 1, 'Credit', 'Debit')
				END																									AS PostSource,
				CASE
					WHEN @AggITP = 0
					AND PP.IsMultiCrdts = 1
					AND PP.PatternID = 1
					THEN 'Credit'
					ELSE IIF(PP.IsPostingOnCredit = 1, 'Credit', 'Debit')
				END																									AS RespSource,
				1																									AS PostingDay,
				@BusinessDate																						AS ClearingDate,
				@NextProcessingDate																					AS SettlementDate,
				CAST(FORMAT(CAST(Tx.CaptureDate AS DATETIME), @CaptureDateFormat) AS VARCHAR(30))	AS CaptureDateTime,
				IIF(
					@AggITP = 0
				AND PP.PostingType = 'ITP'
				AND PP.PatternID = 1
				AND Tx.IsMultiCrdts = 1,
					crdr.OriginalAmount_ISO_Cr,
					PP.PostingAmount)																				AS Amount,				--Fix given based on 194816 bug	
				crdr.TransactionSetID,
				PP.[REJReasonCode]																					AS [RecordReason],
				'N'																									AS PostingOverrideFlag, --Override always N for all outclearing postings
				IIF(Tx.IsMultiCrdts = 1, crdr.cf_NPASortcode_Cr, crdr.cf_NPASortcode)								AS NPASortCode,
				IIF(PP.IsPostingOnCredit = 1, crdr.DebitReference_Cr, crdr.DebitReference)			AS SupportingInformation,
				CASE
					WHEN PP.PostingType IN ( 'REJ',
											'DCR'
										)
					THEN AllDbts.DrCount
					ELSE IIF(PP.IsPostingOnCredit = 1, ValidDbts.DrCount, NULL)
				END																									AS ChequeCreditsNumber,
				Tx.CollectingParticipantId																			AS CollectingParticipantId,
				Tx.CollectingBranchLocation																			AS CollectingLocation,

																																			---------Debit Record-------Fix given based on 194816 bug
				crdr.DebitId																						AS DebitTransactionID,
				CASE
					WHEN
						(
							@AggITP = 0
					AND		PP.PostingType = 'ITP'
					AND		PP.PatternID = 1
						) --Fix given based on 203206 bug 
					THEN crdr.Sortcode_Cr
					WHEN
						(
							PP.IsPostingOnCredit = 0
					AND		PP.PostingType = 'NPA'
						)
					THEN crdr.Sortcode_Cr
					ELSE crdr.Sortcode
				END																									AS DebitSortCode,
				CASE
					WHEN
						(
							@AggITP = 0
					AND		PP.PostingType = 'ITP'
					AND		PP.PatternID = 1
						) --Fix given based on 203206 bug
					THEN crdr.AccountNumber_Cr
					WHEN
						(
							PP.IsPostingOnCredit = 0
					AND		PP.PostingType = 'NPA'
						)
					THEN crdr.AccountNumber_Cr
					ELSE crdr.AccountNumber
				END																									AS DebitAccountNumber,
				IIF(@AggITP = 0 AND PP.PostingType = 'ITP' AND PP.PatternID = 1, 0, crdr.SerialNumber)		AS DebitSerialNumber,
				IIF(@AggITP = 0 AND PP.PostingType = 'ITP' AND PP.PatternID = 1, crdr.TranCode_Cr, crdr.TranCode) AS DebitTranCode,
				crdr.SwitchedSortCode																				AS SwitchedDebitSortCode,
				crdr.SwitchedAccount																				AS SwitchedDebitAccNbr,
				IIF(
					@AggITP = 0
				AND PP.PostingType = 'ITP'
				AND PP.IsMultiCrdts = 1
				AND PP.PatternID = 1,
					crdr.OriginalAmount_ISO_Cr,
					crdr.Amount)																					AS DebitFullAmt,

																																			---------Credit Record --------------
				crdr.CreditId																						AS CreditTransactionID,
				CASE
					WHEN PP.PostingType = 'RCO'
					AND PatternID = 8 --Fix given based on 196195 bug
					THEN crdr.Sortcode
					WHEN PP.PostingType = 'RCO'
					AND PatternID = 9
					THEN @RCOPattern9SortCode
					ELSE crdr.Sortcode_Cr
				END																									AS CreditSortCode,
				CASE
					WHEN PP.PostingType = 'RCO'
					AND PatternID = 8 --Fix given based on 196195 bug
					THEN crdr.AccountNumber
					WHEN PP.PostingType = 'RCO'
					AND PatternID = 9
					THEN @RCOPattern9AccountNumber
					ELSE crdr.AccountNumber_Cr
				END																									AS CreditAccountNumber,
				crdr.Reference_Cr																					AS CreditReference,
				crdr.TranCode_Cr																					AS CreditTransactionCode,
				crdr.OriginalAmount_ISO_Cr																			AS CreditOriginalAmount,
				1																									AS ExtractRecord,

																																			----------Miscelleneous Records-------
				PP.PatternID																						AS [OutclearingPatternID],
				Tx.EntityState																						AS [OutclearingTrigEntityState],
				PP.EntityState																						AS [OutclearingExtractEntityState],
				Tx.TransactionSetIdWithVersion,
				PP.[DebitItemType]
			FROM
				Outclearing.vw_DerivedPostingType	AS PP
			INNER JOIN
				#CreditsDebits						AS crdr
			ON
				crdr.CreditId = PP.CreditID
			AND crdr.DebitId = PP.DebitID
			AND crdr.DrRank = 1
			INNER JOIN
				Outclearing.TXSet					AS Tx
			ON
				PP.PostingID = Tx.PostingID
			AND Tx.TransactionSetIdWithVersion = PP.TransactionSetIdWithVersion
			LEFT JOIN
				(
					SELECT
						TransactionSetId,
						COUNT(DISTINCT (DebitId)) AS DrCount
					FROM
						CreditsDebits
					WHERE
						(
							EntityState NOT IN ( 30,
												60,
												130
											)
					OR		EntityState IS NULL
						)
					GROUP BY
						TransactionSetId
				)									AS ValidDbts
			ON
				crdr.TransactionSetId = ValidDbts.TransactionSetId
			LEFT JOIN
				(
					SELECT
						TransactionSetId,
						COUNT(DISTINCT (DebitId)) AS DrCount
					FROM
						CreditsDebits
					GROUP BY
						TransactionSetId
				)									AS AllDbts
			ON
				crdr.TransactionSetId = AllDbts.TransactionSetId
			WHERE
				PP.PostingID = @PostingID
			AND
			(
					PP.PostingType IS NOT NULL
			AND		PP.PostingType NOT IN ( 'ERR',
											'NIL'
										)
				)
			AND PP.[EligibleToMo] = 1
			AND ISNULL(IsDay1Exception, 0) = 0;

		END;

	END TRY
	BEGIN CATCH
		DECLARE @Number INT = ERROR_NUMBER();
		DECLARE @Message VARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @UserName NVARCHAR(128) = CONVERT(SYSNAME, ORIGINAL_LOGIN());
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
ON [Outclearing].[usp_PostingDataExtract]
TO
	[RNESVCAccess];

GO
EXECUTE sp_addextendedproperty
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Outclearing',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_PostingDataExtract';
GO

EXECUTE sp_addextendedproperty
	@name = N'MS_Description',
	@value = N'Extract posting data from [Outclearing].[PostingPattern]',
	@level0type = N'SCHEMA',
	@level0name = N'Outclearing',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_PostingDataExtract';
GO

EXECUTE sp_addextendedproperty
	@name = N'Component',
	@value = N'iPSL.ICE.RNE.Database',
	@level0type = N'SCHEMA',
	@level0name = N'Outclearing',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_PostingDataExtract';