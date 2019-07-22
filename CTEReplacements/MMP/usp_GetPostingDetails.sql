
/****************************************************************************************
* Stored Procedure:[MMP].[usp_GetPostingDetails]
* Description: Create Posting File

* Amendment History
*****************************************************************************************
* Version		  Name							 Date                  Reason
* 1.3.0			Bhavya Bhadauriya				28 Sept 2016        Create Posting File
*****************************************************************************************/
CREATE PROCEDURE [MMP].[usp_GetPostingDetails]
	@BusinessDate	VARCHAR(8)
AS
	BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON;
		DECLARE @ErrorMessage VARCHAR(4000);
		DECLARE @ErrorNumber INT;
		DECLARE @ErrorState INT;
		DECLARE @ErrorProcedure VARCHAR(50);
		DECLARE @ErrorLine INT;
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorLogID TINYINT;
		DECLARE @APGResonTxt VARCHAR(4000);
		DECLARE @NPASortcode VARCHAR(4000);
		DECLARE @APGReasoncode VARCHAR(20);
		DECLARE @IndustryCode VARCHAR(4000);

		BEGIN TRY

			SET @APGReasoncode = 'A001';
			SET @APGResonTxt = '';

			SELECT
				@APGResonTxt	= @APGResonTxt + cf_NoPaySuspectRsn + ','
			FROM
				(
					SELECT	DISTINCT
							I.cf_NoPaySuspectRsn
					FROM
							[Base].[vw_FinalDebit]		AS FD
					INNER JOIN
							[Base]	.[vw_FinalCredit]	AS FC
					ON
						FD.InternalTxId = FC.InternalTxId
					LEFT JOIN
							[Base].Item					AS I
					ON
						FD.CaptureItemID = I.ItemID
					LEFT JOIN
							[MMP].[NoPayReasonCodes]	AS NPR
					ON
						NPR.APGReasoncodeText = I.cf_NoPaySuspectRsn
					WHERE
							(
								(
									FD.APGBusinessDate = @BusinessDate
							AND		FD.ResponseDate IS NULL
								)
						OR		FD.ResponseDate = @BusinessDate
							)
					AND
					(
							NPR.APGReasoncodeText IS NULL
					OR		NPR.APGReasoncode IS NULL
						)
					AND
					(	--Get only no pay items
							FD.PayReason IS NOT NULL
					OR		I.cf_NoPaySuspectRsn IS NOT NULL
						)
				) AS ART;

			SET @NPASortcode = '';

			SELECT
				@NPASortcode	= @NPASortcode + Sortcode + ','
			FROM
				(
					SELECT	DISTINCT
							FC.Sortcode
					FROM
							[Base].[vw_FinalDebit]	AS FD
					INNER JOIN
							[Base]	.[vw_FinalCredit] AS FC
					ON
						FD.InternalTxId = FC.InternalTxId
					LEFT JOIN
							[MMP].[NPASortcodes]	AS NP
					ON
						NP.CBSSortcode = FC.Sortcode
					WHERE
							(
								(
									FD.APGBusinessDate = @BusinessDate
							AND		FD.ResponseDate IS NULL
								)
						OR		FD.ResponseDate = @BusinessDate
							)
					AND NP.CBSSortcode IS NULL
				-- AND FD.PayReason IS NOT NULL
				) AS NPS;

			SET @IndustryCode = '';

			SELECT
				@IndustryCode	= @IndustryCode + PayReason + ','
			FROM
				(
					SELECT	DISTINCT
							FD.PayReason
					FROM
							[Base].[vw_FinalDebit]		AS FD
					INNER JOIN
							[Base]	.[vw_FinalCredit]	AS FC
					ON
						FD.InternalTxId = FC.InternalTxId
					LEFT JOIN
							[MMP].[NoPayReasonCodes]	AS NPR
					ON
						NPR.Industrycode = FD.PayReason
					WHERE
							(
								(
									FD.APGBusinessDate = @BusinessDate
							AND		FD.ResponseDate IS NULL
							AND		FD.PayDecision = 0
								)
						OR
							(
								FD.PayDecision = 0
						AND		FD.ResponseDate = @BusinessDate -- On Day 3 Get MSG13 which had local bank holiday's
							)
							)
					AND NPR.Industrycode IS NULL
				) AS IND;

			IF (
				@APGResonTxt <> ''
			OR		@NPASortcode <> ''
			OR		@IndustryCode <> ''
			)
				BEGIN
					SET @ErrorMessage = 'Missing APG Reasoncode Text:' + ISNULL(@APGResonTxt, '') + '. Missing NPA Sortcode:' + ISNULL(@NPASortcode, '') + '. Missing Industry code:' + ISNULL(@IndustryCode, '');
					RAISERROR(@ErrorMessage, 17, 1);
				END;


			SELECT
				'2'																					AS RecordType,
				'5'																					AS RowNumber,
				CASE
					WHEN (FD.[EntityState] = 21)
					OR
						(
							FD.PayDecision = 0
					AND		FD.PayReason <> ''
						) --FD.PayDecision = No Pay(0) FD.PayReason <> ''(No Pay)
					THEN 0
					WHEN FD.PayDecision = 1
					THEN 1
				END																					AS DecisionIndicator,
				FD.DebitId,
				REPLACE(CONVERT(VARCHAR(10), CONVERT(DATETIME, I.cf_ImageDateTime), 103), '/', '') AS DepositDate,
				''																					AS ClearingText,				-- All blank
				CAST(FC.Sortcode AS VARCHAR(6))														AS CreditSortCode,
				CAST(FC.AccountNumber AS VARCHAR(8))										AS CreditAccountNumber,
				CAST(FLOOR(FD.OriginalAmount * 100) AS VARCHAR(15))									AS TransactionAmount,
				REPLACE(CONVERT(VARCHAR(10), FD.APGBusinessDate, 103), '/', '')		AS ClearingCycleDate,
				FD.TranCode																			AS ClearingItemType,
				CAST(FD.SerialNumber AS VARCHAR(6))													AS SerialNumber,
				''																					AS StatmentRef,					--All blank
				CASE
					WHEN FD.[EntityState] = 21
					THEN (CASE
							WHEN NPR.APGReasoncodeText = 'Adjusted'
							AND FD.AdjustmentReason = 90
							THEN 'A020'
							ELSE NPR.APGReasoncode
						END
						)
					WHEN
						(
							FD.PayDecision = 0
					AND		FD.PayReason <> ''
						)
					THEN FD.[PayReason]
					ELSE ''
				END																					AS ReturnItemCode,				--ToDo:Get value for MSG01/03 as per logic in NoPayAdvice Extract
				CAST(FD.IsOnUs AS VARCHAR(1))														AS OnUsFlag,
				CAST(FD.Sortcode AS VARCHAR(6))														AS ChequeSortCode,
				CAST(FD.AccountNumber AS VARCHAR(8))										AS ChequeAccountNumber,
				NP.RegionalSortCode																	AS NPASortCode, --Need to Update
				(
					SELECT
						[AccountNumber] AS NPAAccountNumber
					FROM
						[MMP].[NPAAccount]
					WHERE
						[IsActive]	= 1
				)																					AS NPAAccountNumber,
				I.[cf_ICSTransactionID]																AS TransactionId,
				FC.CreditId,
				FD.ResponseDate,
				FD.[EntityState],
				''																					AS HDRFTR
			INTO
				#ItemDetails
			FROM
				[Base].[vw_FinalDebit]		AS FD
			INNER JOIN
				[Base].[vw_FinalCredit]		AS FC
			ON
				FD.InternalTxId = FC.InternalTxId
			LEFT JOIN
				[MMP].[NPASortcodes]		AS NP
			ON
				NP.CBSSortcode = FC.Sortcode
			LEFT JOIN
				[Base].Item					AS I
			ON
				FD.CaptureItemID = I.ItemID
			LEFT JOIN
				[MMP].[NoPayReasonCodes]	AS NPR
			ON
				NPR.APGReasoncodeText = I.cf_NoPaySuspectRsn
			WHERE
				(
					FD.APGBusinessDate = @BusinessDate
			AND		FD.ResponseDate IS NULL
				)
			OR	FD.ResponseDate = @BusinessDate;
			-- )

			CREATE CLUSTERED INDEX ci_EntityState
			ON #ItemDetails (EntityState, ResponseDate);

			SELECT
				'1'																	AS RecordType,
				''																	AS RowNumber,
				''																	AS DecisionIndicator,
				''																	AS DebitId,
				''																	AS DepositDate,
				''																	AS ClearingText,
				''																	AS CreditSortCode,
				''																	AS CreditAccountNumber,
				''																	AS TransactionAmount,
				''																	AS ClearingCycleDate,
				''																	AS ClearingItemType,
				''																	AS SerialNumber,
				''																	AS StatmentRef,
				''																	AS ReturnItemCode,
				''																	AS OnUsFlag,
				''																	AS ChequeSortCode,
				''																	AS ChequeAccountNumber,
				''																	AS NPASortCode,
				''																	AS NPAAccountNumber,
				''																	AS TransactionId,
				''																	AS CreditId,
				'AHR,ICS,' + REPLACE(CONVERT(VARCHAR(20), GETDATE(), 103), '/', '') AS HDRFTR
			UNION ALL
			SELECT
				RecordType	,
				RowNumber,
				DecisionIndicator,
				DebitId,
				DepositDate,
				ClearingText,
				CreditSortCode,
				CreditAccountNumber,
				TransactionAmount,
				ClearingCycleDate,
				ClearingItemType,
				SerialNumber,
				StatmentRef,
				@APGReasoncode,
				OnUsFlag,
				ChequeSortCode,
				ChequeAccountNumber,
				NPASortCode,
				NPAAccountNumber,
				TransactionId,
				CreditId,
				HDRFTR
			FROM
				#ItemDetails
			WHERE
				EntityState = 120
			AND ResponseDate = @BusinessDate
			UNION ALL
			SELECT
				RecordType	,
				RowNumber,
				DecisionIndicator,
				DebitId,
				DepositDate,
				ClearingText,
				CreditSortCode,
				CreditAccountNumber,
				TransactionAmount,
				ClearingCycleDate,
				ClearingItemType,
				SerialNumber,
				StatmentRef,
				ReturnItemCode,
				OnUsFlag,
				ChequeSortCode,
				ChequeAccountNumber,
				NPASortCode,
				NPAAccountNumber,
				TransactionId,
				CreditId,
				HDRFTR
			FROM
				#ItemDetails
			WHERE
				EntityState > 120
			OR	EntityState < 120
			UNION ALL
			SELECT
				'3'				AS RecordType,
				''				AS RowNumber,
				''				AS DecisionIndicator,
				''				AS DebitId,
				''				AS DepositDate,
				''				AS ClearingText,
				''				AS CreditSortCode,
				''				AS CreditAccountNumber,
				''				AS TransactionAmount,
				''				AS ClearingCycleDate,
				''				AS ClearingItemType,
				''				AS SerialNumber,
				''				AS StatmentRef,
				''				AS ReturnItemCode,
				''				AS OnUsFlag,
				''				AS ChequeSortCode,
				''				AS ChequeAccountNumber,
				''				AS NPASortCode,
				''				AS NPAAccountNumber,
				''				AS TransactionId,
				''				AS CreditId,
				'EOF,' + LTRIM(STR(
								(
									SELECT
										COUNT(*)
									FROM
										#ItemDetails
								)
								)
							) AS HDRFTR;
		END TRY
		BEGIN CATCH

			IF XACT_STATE() <> 0
				ROLLBACK TRANSACTION;
			SET @ErrorMessage = ERROR_MESSAGE();
			EXECUTE [Base].[usp_LogError]
				@ErrorMessage;
			THROW;
		END CATCH;
	END;
GO
GRANT
	EXECUTE
ON [MMP].[usp_GetPostingDetails]
TO
	[MMPLoader];
GO

EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'MMP',
	@level0type = N'SCHEMA',
	@level0name = N'MMP',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetPostingDetails';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This Stored Procedure will return value that we need in posting file.',
	@level0type = N'SCHEMA',
	@level0name = N'MMP',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetPostingDetails';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'MMP',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetPostingDetails';