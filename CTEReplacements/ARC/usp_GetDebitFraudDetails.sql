CREATE PROCEDURE [Web].[usp_GetDebitFraudDetails]
	@UniqueItemIdentifier	VARCHAR(25)		= NULL,
	@BusinessDate			DATE			= NULL,
	@RoleName				VARCHAR(400)	= NULL
/*****************************************************************************************************
* Name				: [Web].[usp_GetDebitFraudDetails]
* Description		: Stored Procedure to get the Debit Fraud Details 
* Type of Procedure : Interpreted stored procedure
* Author			: Stephen Birdsall
* Creation Date		:	/04/2017
* Last Modified		: 17/08/2018
* Modified By		: Harjeet Singh

*******************************************************************************************************/
AS
	BEGIN

		BEGIN TRY

			SET NOCOUNT ON;

			IF @RoleName IS NOT NULL
				BEGIN
					EXECUTE AS USER = @RoleName;
				END;

			-- internal variables
			DECLARE @BusinessDateFrom BIGINT;
			DECLARE @BusinessDateTo BIGINT;
			DECLARE @ErrorMessage VARCHAR(256);

			IF @UniqueItemIdentifier IS NULL
			AND @BusinessDate IS NULL
				BEGIN
					SET @ErrorMessage = 'Either the unique item identifier, or the business date must be provided.';
					THROW 51001, @ErrorMessage, 16;
				END;
			ELSE
				BEGIN
					IF	(@BusinessDate IS NOT NULL)
						BEGIN
							SET @BusinessDateFrom = CONVERT(BIGINT, CONVERT(VARCHAR(20), @BusinessDate, 112)) * 100000000000;
							SET @BusinessDateTo = @BusinessDateFrom + 99999999999;
						END;

					SELECT
						d.DebitId					AS UniqueItemIdentifier,
						dfd.SuspiciousCheque		AS SuspiciousItem,
						dfd.DateOfFirstCheque		AS DateOfFirstCheque,
						dfd.DateOfLastCheque		AS DateOfLastCheque,
						dfd.NumberOfCounterparties	AS NumberOfCounterparties,
						dfd.NumberOfGoodCheques		AS NumberOfGoodCheques,
						dfd.NumberOfFraudCheques	AS NumberOfFraudCheques,
						dfd.LargestAmount			AS LargestAmount,
						dfd.RiskIndicator			AS RiskIndicator,
						--                  --NULL AS FraudStatusCode , -- rework needed within MSGs 14 & 16
						FinalFrdSts.FraudResult		AS FraudStatusCode,
						FinalFrdSts.FraudReason		AS FraudReasonCode
					INTO
						#fraudDebits
					FROM
						Base.Debit			AS d WITH (SNAPSHOT)
					INNER JOIN
						Base.DebitFraudData AS dfd WITH (SNAPSHOT)
					ON
						dfd.ItemId = d.ItemId
					LEFT JOIN
						(
							SELECT
								FraudId,
								ItemId,
								FraudResult,
								FraudReason
							FROM
								[Base].[FraudStatusResults] WITH (SNAPSHOT)
							WHERE
								FraudId IN
									(
										SELECT
											MAX(FraudId)
										FROM
											[Base].[FraudStatusResults] WITH (SNAPSHOT)
										GROUP BY
											ItemId
									)
						)					AS FinalFrdSts
					ON
						FinalFrdSts.ItemId = d.DebitId
					WHERE
						(
							@UniqueItemIdentifier IS NOT NULL
					AND		d.DebitId = @UniqueItemIdentifier
						)
					OR
						(
							@UniqueItemIdentifier IS NULL
					AND		@BusinessDate IS NOT NULL
					AND		d.ItemId
					BETWEEN @BusinessDateFrom AND @BusinessDateTo
						);

					CREATE CLUSTERED INDEX ci_UniqueItemIdentifier
					ON #fraudDebits (UniqueItemIdentifier);

					SELECT
						fraud.UniqueItemIdentifier,
						fraud.SuspiciousItem,
						fraud.DateOfFirstCheque,
						fraud.DateOfLastCheque,
						fraud.NumberOfCounterparties,
						fraud.NumberOfGoodCheques,
						fraud.NumberOfFraudCheques,
						fraud.LargestAmount,
						fraud.RiskIndicator,
						fraud.FraudStatusCode,
						fraud.FraudReasonCode
					FROM
						#fraudDebits	AS fraud WITH (SNAPSHOT)
					INNER JOIN
						Base.FinalDebit AS FD WITH (SNAPSHOT)
					ON
						FD.DebitId = fraud.UniqueItemIdentifier;

				END;
		END TRY
		BEGIN CATCH
			THROW;
		END CATCH;
	END;
GO

GRANT
	EXECUTE
ON [Web].[usp_GetDebitFraudDetails]
TO
	WebItemRetrieval;
GO


EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'STAR',
	@level0type = N'SCHEMA',
	@level0name = N'Web',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetDebitFraudDetails';
GO

EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Stored Procedure to get the Debit Fraud Details',
	@level0type = N'SCHEMA',
	@level0name = N'Web',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetDebitFraudDetails';
GO

EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Web',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetDebitFraudDetails';
GO
