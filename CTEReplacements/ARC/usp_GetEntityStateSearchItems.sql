CREATE PROCEDURE [Web].[usp_GetEntityStateSearchItems]
	@BusinessDate	DATE,
	@SearchType		INT,
	@SortCode		VARCHAR(6)		= NULL,
	@Account		VARCHAR(8)		= NULL,
	@Serial			INT				= NULL,
	@Amount			BIGINT			= NULL,
	@TranCode		CHAR(2)			= NULL,
	@RoleName		VARCHAR(400)	= NULL

/********************************************************************************************************************
* Name				: [Web].[usp_GetEntityStateSearchItems]
* Description		: This Stored Procedure will be used by web service method ICS EntityStateSearch Query to fetch 
                      all the items that have received a default decision by Switch or DEW for a given business date 
					  based on input parameters.Results will be filtered further by any additional parameter value supplied.
* Type of Procedure : Interpreted stored procedure
* Author			: Mahesh Kumar Suragani
* Creation Date		: 12/04/2018
* Last Modified		: N/A
*********************************************************************************************************************/
AS
	BEGIN

		SET NOCOUNT ON;

		IF @RoleName IS NOT NULL
			BEGIN
				EXECUTE AS USER = @RoleName;
			END;

		DECLARE @BusinessDateFrom BIGINT;
		DECLARE @BusinessDateTo BIGINT;
		DECLARE @AmountFilter NUMERIC(20, 2);

		SET @BusinessDateFrom = CONVERT(BIGINT, CONVERT(VARCHAR(20), @BusinessDate, 112)) * 100000000000;
		SET @BusinessDateTo = @BusinessDateFrom + 99999999999;
		SET @AmountFilter = CAST(CAST(@Amount AS NUMERIC(20, 2)) / 100 AS NUMERIC(20, 2));

		SELECT
			FinDeb	.ItemId,
			TXSet.CaptureDate							AS CaptureDateTime,
			FinDeb.Serial								AS SerialNumber,
			FinDeb.Sortcode								AS SortCode,
			RIGHT('00000000' + FinDeb.AccountNumber, 8) AS Account,
			FinDeb.TranCode,
			FinDeb.Amount,
			FinDeb.Currency								AS Currency,
			'DB'										AS ItemGender,
			IT.ItemTypeCode								AS ItemType,
			FinDeb.OnUs									AS OnUsItem,
			CASE
				WHEN FinDeb.PayDecision = 1
				THEN 1
				ELSE 2
			END											AS RTPPaidIndicator,
			FinDeb.PayReason							AS PayDecisionReasonCode,
			CAST(COALESCE(FinDeb.Represent, 0) AS BIT)	AS RePresentedItem,
			En.EntityState								AS CurrentEntityState,
			TXSet.CollectingLocation,
			TXSet.CollectingBranchLocation,
			TXSet.CollectionPoint,
			TXSet.CollectionBranchRef					AS CollectingBranchReference,
			TXSet.CollectingParticipantId				AS CollectingParticipantIdentifier,
			FinDeb.EISCDPayingParticipantId				AS PayingParticipantIdentifier,
			FinDeb.EISCDBeneficiaryParticipantId		AS BeneficiaryParticipantIdentifier,
			TXSet.AltSource								AS Source,
			TXSet.ChannelRiskType,
			FinDeb.DebitId								AS UniqueItemIdentifier,
			TXSet.TransactionSetIdWithVersion			AS TransactionSetIdentifier,
			Core.CoreId									AS CoreId
		INTO
			#FinalItemsOuter
		FROM
			Base.FinalDebit AS FinDeb WITH (SNAPSHOT)
		INNER JOIN
			(
				SELECT
					A.EntityId,
					A.EntityIdentifier,
					A.EntityState,
					A.Revision,
					A.CoreId
				FROM
					Base.Entity AS A WITH (SNAPSHOT)
				JOIN
					(
						SELECT
							MAX(FinalES.Revision)	AS MaxRevision,
							FinalES.EntityIdentifier
						FROM
							Base.Entity								AS En WITH (SNAPSHOT)
						JOIN
							ReferenceData.EntityStateSearchTypes	AS ESST WITH (SNAPSHOT)
						ON
							En.EntityState = ESST.EntityState
						AND ESST.SearchTypeId = @SearchType
						JOIN
							Base.Entity								AS FinalES WITH (SNAPSHOT)
						ON
							En.EntityIdentifier = FinalES.EntityIdentifier
						WHERE
							FinalES.EntityState < 900
						GROUP BY
							FinalES.EntityIdentifier
					)			AS B
				ON
					A.EntityIdentifier = B.EntityIdentifier
				AND [B].[MaxRevision] = A.Revision
			)				AS En
		ON
			En.EntityIdentifier = FinDeb.DebitId
		INNER JOIN
			Base.Debit		AS DB WITH (SNAPSHOT)
		ON
			DB.DebitId = FinDeb.DebitId
		AND DB.ItemId = FinDeb.ItemId
		INNER JOIN
			Base.Core		AS Core WITH (SNAPSHOT)
		ON
			Core.CoreId = En.CoreId
		INNER JOIN
			Base.vw_TXSet	AS TXSet WITH (SNAPSHOT)
		ON
			TXSet.InternalTxId = FinDeb.InternalTxId
		INNER JOIN
			Lookup.ItemType AS IT WITH (SNAPSHOT)
		ON
			IT.Id = FinDeb.ItemType
		WHERE
			FinDeb.ItemId
		BETWEEN @BusinessDateFrom AND @BusinessDateTo
		AND
		(
				@SortCode IS NULL
		OR		FinDeb.Sortcode = @SortCode
			)
		AND
		(
				@Account IS NULL
		OR		FinDeb.AccountNumber = @Account
			)
		AND
		(
				@AmountFilter IS NULL
		OR		FinDeb.Amount = @AmountFilter
			)
		AND
		(
				@TranCode IS NULL
		OR		FinDeb.TranCode = @TranCode
			)
		AND
		(
				@Serial IS NULL
		OR		FinDeb.Serial = @Serial
			);

		CREATE CLUSTERED INDEX ci_UniqueItemIdentifier
		ON #FinalItemsOuter (UniqueItemIdentifier);
		CREATE NONCLUSTERED INDEX nci_CurrentEntityState
		ON #FinalItemsOuter (CurrentEntityState);

		SELECT
			FinalItemsOuter.ItemId,
			FinalItemsOuter.CaptureDateTime,
			FinalItemsOuter.SerialNumber,
			FinalItemsOuter.Sortcode,
			RIGHT('00000000' + [FinalItemsOuter].[Account], 8) AS Account,
			FinalItemsOuter.TranCode,
			FinalItemsOuter.Amount,
			FinalItemsOuter.Currency,
			'DB'												AS ItemGender,
			FinalItemsOuter.ItemType,
			FinalItemsOuter.OnUsItem,
			[FinalItemsOuter].[RTPPaidIndicator],
			FinalItemsOuter.PayDecisionReasonCode,
			[FinalItemsOuter].[RePresentedItem],
			FinalItemsOuter.CurrentEntityState,
			RTP.[Description]									AS EntityStateDescription,
			CASE
				WHEN FSR.FraudResult = 'Not Processed'
				THEN 'NP'
				WHEN FSR.FraudResult = 'OK'
				THEN 'OK'
				WHEN FSR.FraudResult = 'Suspect'
				THEN 'SUS'
				WHEN FSR.FraudResult = 'Fraudulent'
				THEN 'FRD'
				WHEN FSR.FraudResult = 'KG'
				THEN 'KG'
				ELSE FSR.FraudResult
			END													AS FraudStatusCode,
			FinalItemsOuter.CollectingLocation,
			FinalItemsOuter.CollectingBranchLocation,
			FinalItemsOuter.CollectionPoint,
			FinalItemsOuter.CollectingBranchReference,
			FinalItemsOuter.CollectingParticipantIdentifier,
			FinalItemsOuter.PayingParticipantIdentifier,
			FinalItemsOuter.BeneficiaryParticipantIdentifier,
			FinalItemsOuter.Source,
			FinalItemsOuter.ChannelRiskType,
			FinalItemsOuter.UniqueItemIdentifier,
			FinalItemsOuter.TransactionSetIdentifier,
			FinalItemsOuter.CoreId								AS CoreId
		INTO 
			#FinalItms
		FROM
			#FinalItemsOuter						AS FinalItemsOuter WITH (SNAPSHOT)
		LEFT JOIN
			(
				SELECT
					FraudId,
					ItemId,
					FraudResult
				FROM
					(
						SELECT
							FraudId,
							ItemId,
							FraudResult
						FROM
							[Base].[FraudStatusResults] WITH (SNAPSHOT)
						WHERE
							FraudId IN
								(
									SELECT
										MAX(FraudId)
									FROM
										[Base].[FraudStatusResults] WITH (SNAPSHOT)
									WHERE
										ItemId	IN
											(
												SELECT
													UniqueItemIdentifier
												FROM
													#FinalItemsOuter WITH (SNAPSHOT)
											)
									GROUP BY
										ItemId
								)
					) AS FinalFrdSts
			)										AS FSR
		ON
			FSR.ItemId = FinalItemsOuter.UniqueItemIdentifier
		INNER JOIN
			[ReferenceData].[RTPPaidEntityStates]	AS RTP WITH (SNAPSHOT)
		ON
			RTP.EntityState = FinalItemsOuter.CurrentEntityState;


		CREATE CLUSTERED INDEX ci_UniqueItemIdentifier
		ON #FinalItms (UniqueItemIdentifier);
		CREATE NONCLUSTERED INDEX nci_Currency
		ON #FinalItms (Currency);

		SELECT
			FLOOR(FinalItms.ItemID / 100000000000)			AS ProcessingDate,
			FinalItms.CaptureDateTime,
			FLOOR(FinalPosting.InternalId / 100000000000) AS PostingDate,
			FinalItms.SerialNumber,
			FinalItms.SortCode,
			[FinalItms].[Account],
			FinalItms.TranCode,
			FinalItms.Amount,
			CUR.Currency									AS Currency,
			[FinalItms].[ItemGender],
			FinalItms.ItemType,
			FinalItms.OnUsItem,
			[FinalItms].[RTPPaidIndicator],
			FinalItms.PayDecisionReasonCode,
			FinalItms.CurrentEntityState,
			FinalItms.EntityStateDescription,
			[FinalItms].[RePresentedItem],
			[FinalItms].[FraudStatusCode],
			Item.IsDeleted									AS DeletedItemIndicator,
			FinalItms.CollectingLocation,
			FinalItms.CollectingBranchLocation,
			FinalItms.CollectionPoint,
			FinalItms.CollectingBranchReference,
			FinalItms.CollectingParticipantIdentifier,
			FinalItms.PayingParticipantIdentifier,
			FinalItms.BeneficiaryParticipantIdentifier,
			FinalItms.[Source],
			FinalItms.ChannelRiskType,
			FinalItms.UniqueItemIdentifier,
			FinalItms.TransactionSetIdentifier,
			Item.APGDIN										AS ClearingDIN
		FROM
			#FinalItms			AS FinalItms
		LEFT JOIN
			Base.Item			AS Item WITH (SNAPSHOT)
		ON
			Item.FCMIdentifier = FinalItms.UniqueItemIdentifier
		LEFT JOIN
			(
				SELECT
					PostingInfo.InternalId	AS InternalId,
					PostingInfo.ItemId		AS ItemId
				FROM
					(
						SELECT
							PD	.InternalId		AS InternalId,
							PD.ItemId			AS ItemId,
							ROW_NUMBER() OVER (PARTITION BY
												PD.ItemId
												ORDER BY
												PD.InternalId DESC
											) AS RKD
						FROM
							Post.PostingDebit	AS PD WITH (SNAPSHOT)
						INNER JOIN
							#FinalItms			AS FinalItms
						ON
							PD.ItemId = FinalItms.UniqueItemIdentifier
					) AS PostingInfo
				WHERE
					[PostingInfo].[RKD] = 1
			)					AS FinalPosting
		ON
			FinalPosting.ItemId = FinalItms.UniqueItemIdentifier
		LEFT JOIN
			[Lookup].Currency	AS CUR WITH (SNAPSHOT)
		ON
			CUR.Id = FinalItms.Currency;

	END;

GO

GRANT
	EXECUTE
ON [Web].[usp_GetEntityStateSearchItems]
TO
	WebItemRetrieval;

GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'STAR',
	@level0type = N'SCHEMA',
	@level0name = N'Web',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetEntityStateSearchItems';

GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This Stored Procedure will be used by web service method ICS EntityStateSearch Query to fetch all the items that have received a default decision by Switch or DEW for a given business date based on input parameters.Results will be filtered further by any additional parameter value supplied.',
	@level0type = N'SCHEMA',
	@level0name = N'Web',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetEntityStateSearchItems';

GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Web',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetEntityStateSearchItems';
