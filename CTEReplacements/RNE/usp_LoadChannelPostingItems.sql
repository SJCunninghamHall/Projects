CREATE PROCEDURE [Report].[usp_LoadChannelPostingItems]
	@RowCount	INT OUTPUT
/*****************************************************************************************************
* Name				: [Report].[usp_LoadChannelPostingItems]
* Description		: This stored procedure exports the data from ChannelPostingItemsTable staging 
* Type of Procedure : Interpreted stored procedure
* Author			: Hamid Narikkoden
* Creation Date		: 03/05/2018
* Last Modified		: 20/07/2018
*******************************************************************************************************/
AS
	BEGIN

		DECLARE @FlipFlopNPAAccount VARCHAR(8); 

		SET NOCOUNT ON;

		BEGIN TRY

			SELECT
				@FlipFlopNPAAccount = AccountNumber
			FROM
				Config.NPAAccount
			WHERE
				IsActive = 1;

			SELECT
				C.[Description]										AS Channel,
				PayDecision,
				CreditId,
				DebitId,
				TransactionSetIdWithVersion,
				DepositDate,
				CreditSortCode,
				CreditAccountNo,
				CAST(CreditAmount * 100 AS INT)						AS CreditAmount,
				ClearingDate,
				SettlementReference,
				ErrorCode											AS ErrorCd,
				NoPaySource,
				COALESCE(NPAPG.IndustryCode, I.NoPayReasonCode, '') AS NoPayReasonCode,
				COALESCE(NPR.Description, I.NoPayReason, '')		AS NoPayReason,
				IsOnUs,
				DebitSortCode,
				DebitAccountNo,
				DebitSerial,
				CAST(DebitAmount * 100 AS INT)						AS DebitAmount,
				COALESCE(NPA.RegionalSortCode, 'Not Populated')		AS NPASortCode, -- For HSBC Display as Not Populated-- For LBG, Display Regional Sort Code
				COALESCE(@FlipFlopNPAAccount, 'Not Populated')		AS NPAAccount	-- For HSBC Display as Not Populated-- For LBG, Display Flip Flop NPA Account
			INTO
				#MAIN
			FROM
				[Staging].ChannelPostingItems	AS I
			INNER JOIN
				[Config].ChannelList			AS C
			ON
				C.Channel = I.Channel
			LEFT JOIN
				[Config].NPASortCodes			AS NPA
			ON
				NPASortCode = NPA.CBSSortCode
			LEFT JOIN
				[Config].[NoPayReasonCodeList]	AS NPR
			ON
				NPR.ReasonCode = I.NoPayReason
			LEFT JOIN
				[Config].APGNoPayReasonCodes	AS NPAPG
			ON
				NPAPG.APGNoPayReasonCode = I.NoPayReason;

			CREATE NONCLUSTERED INDEX nci_TransactionSetIdWithVersion
			ON #MAIN (TransactionSetIdWithVersion);

			SELECT
				TransactionSetIdWithVersion,
				COUNT(DISTINCT CreditId)	AS CreditC
			INTO
				#CreditCount
			FROM
				#MAIN
			GROUP BY
				TransactionSetIdWithVersion;

			CREATE NONCLUSTERED INDEX nci_TransactionSetIdWithVersion
			ON #CreditCount (TransactionSetIdWithVersion);

			SELECT
				TransactionSetIdWithVersion,
				COUNT(DISTINCT DebitId) AS DebitCount
			INTO
				#DebitCount
			FROM
				#MAIN
			GROUP BY
				TransactionSetIdWithVersion;

			CREATE NONCLUSTERED INDEX nci_TransactionSetIdWithVersion
			ON #DebitCount (TransactionSetIdWithVersion);

			SELECT
				Channel,
				PayDecision,
				CreditId,
				DebitId,
				CASE
					WHEN [CC].[CreditC] = [DC].[DebitCount]
					THEN DebitId
					WHEN [CC].[CreditC] > [DC].[DebitCount]
					THEN CreditId
					WHEN [CC].[CreditC] < [DC].[DebitCount]
					THEN DebitId
				END																									AS ICSItemID,
				M.TransactionSetIdWithVersion,
				CAST(REPLACE(CAST(CONVERT(VARCHAR(10), DepositDate, 105) AS VARCHAR(10)), '-', '') AS VARCHAR(8))	AS DepositDate,
				CreditSortCode,
				CreditAccountNo,
				CAST(REPLACE(CAST(CONVERT(VARCHAR(10), ClearingDate, 105) AS VARCHAR(10)), '-', '') AS VARCHAR(8)) AS ClearingDate,
				[M].[CreditAmount],
				[M].[DebitAmount],
				CASE
					WHEN [CC].[CreditC] = [DC].[DebitCount]
					THEN [M].[DebitAmount]
					WHEN [CC].[CreditC] > [DC].[DebitCount]
					THEN [M].[CreditAmount]
					WHEN [CC].[CreditC] < [DC].[DebitCount]
					THEN [M].[DebitAmount]
				END																									AS TransactionAmount,
				SettlementReference,
				ErrorCd,
				NoPaySource,
				[M].[NoPayReasonCode],
				[M].[NoPayReason],
				IsOnUs,
				DebitSortCode,
				DebitAccountNo,
				DebitSerial,
				[M].[NPASortCode],
				[M].[NPAAccount]
			FROM
				#MAIN			AS M
			LEFT JOIN
				#CreditCount	AS CC
			ON
				M.TransactionSetIdWithVersion = CC.TransactionSetIdWithVersion
			LEFT JOIN
				#DebitCount		AS DC
			ON
				M.TransactionSetIdWithVersion = DC.TransactionSetIdWithVersion;

			SELECT
				@RowCount	= COUNT(*)
			FROM
				[Staging].ChannelPostingItems;
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

	END;
GO

GRANT
	EXECUTE
ON [Report].[usp_LoadChannelPostingItems]
TO
	[RNEReportAccess];

GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Report',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_LoadChannelPostingItems';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This stored procedure exports the data from ChannelPostingItemsTable staging.',
	@level0type = N'SCHEMA',
	@level0name = N'Report',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_LoadChannelPostingItems';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'iPSL.ICE.RNE.Database',
	@level0type = N'SCHEMA',
	@level0name = N'Report',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_LoadChannelPostingItems';
GO