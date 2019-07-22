CREATE PROCEDURE [Agency].[usp_ReturnAgencyISOMSG06CSV]
	@AgencyId		INT,
	@BusinessDate	DATE,
	@TotalItemCount INT = 0
/*****************************************************************************************************
* Name				: [Agency].[usp_ReturnAgencyISOMSG06CSV]
* Description		: This Stored Procedure returns the MSG06 Items in CSV format for a given AgencyId
* Type of Procedure : Interpreted stored procedure
* Author			: Nageswara Rao
* Creation Date		: 19/06/2018
*******************************************************************************************************/
AS
	BEGIN

		SET NOCOUNT ON;

		SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

		BEGIN TRY

			BEGIN TRAN;

			--To derive the business date range for retrieving items from the FinalCredit table
			DECLARE @BusinessDateFrom BIGINT;
			DECLARE @BusinessDateTo BIGINT;

			--Table varible to calculate the number of TSets available for extraction for a given AgencyId
			DECLARE @EligibleISOMSG06Tsets [Agency].[tv_ISOMSG06Tsets];


			SET @BusinessDateFrom = Base.cfn_Convert_Date_StartRangeKey(@BusinessDate);
			SET @BusinessDateTo = Base.cfn_Convert_Date_EndRangeKey(@BusinessDate);

			INSERT INTO
				@EligibleISOMSG06Tsets
				(
					TransactionSetIdWithVersion,
					DebitId,
					ItemId,
					InternalTxId,
					TransactionSetRank
				)
			SELECT
				EligibleTransactionSets.TransactionSetIdWithVersion,
				EligibleTransactionSets.DebitId,
				EligibleTransactionSets.ItemId,
				EligibleTransactionSets.InternalTxId,
				ROW_NUMBER() OVER (ORDER BY
									EligibleTransactionSets.ItemId ASC
								) AS TransactionSetRank
			FROM
				(
					SELECT
						TX	.TransactionSetIdWithVersion,
						FD.DebitId,
						DB.ItemId,
						TX.InternalTxId,
						ROW_NUMBER() OVER (PARTITION BY
											FD.DebitId
											ORDER BY
											FD.ItemId DESC
										) AS RKD
					FROM
						Base.vw_FinalDebit	AS FD
					INNER JOIN
						Base.Debit			AS DB WITH (SNAPSHOT)
					ON
						FD.DebitId = DB.DebitId
					INNER JOIN
						[Base].[vw_TXSet]	AS TX
					ON
						DB.InternalTxId = TX.InternalTxId
					INNER JOIN
						Base.ItemUpdate		AS IU WITH (SNAPSHOT)
					ON
						DB.ItemId = IU.InternalId
					INNER JOIN
						Base.Core			AS CO WITH (SNAPSHOT)
					ON
						IU.CoreID = CO.CoreId
					INNER JOIN
						Lookup.MessageType	AS MSGTYPE WITH (SNAPSHOT)
					ON
						CO.MessageType = MSGTYPE.MessageId
					WHERE
						MSGTYPE.MessageType = 'MSG06'
					AND FD.PayingParticipantId = @AgencyId
					AND FD.ItemId
					BETWEEN @BusinessDateFrom AND @BusinessDateTo
				) AS EligibleTransactionSets
			WHERE
				[EligibleTransactionSets].[RKD] = 1;

			IF (@TotalItemCount = 0)
				BEGIN
					SELECT
						[Result].[RowValue]
					FROM
						(
							SELECT
								'Item ID,Sortcode,Account,Serial,Amount,Kappa Flag,T-set Identifier,Collecting Participant,Switched Sortcode,Switched Account,Debit Item Type,Debit Item Transaction Code,Represented Item Indicator'	AS RowValue,
								1																																																		AS RNO
							UNION ALL
							SELECT
								'No Data Available' AS RowValue,
								2					AS RNO
						) AS Result
					ORDER BY
						[Result].[RNO];
				END;
			ELSE
				BEGIN

					SELECT
						DB	.DebitId													AS [Item ID],
						RIGHT('000000' + CAST(FD.Sortcode AS VARCHAR(6)), 6) AS Sortcode,
						RIGHT('00000000' + CAST(FD.AccountNumber AS VARCHAR(8)), 8)		AS Account,
						RIGHT('000000' + CAST(FD.SerialNumber AS VARCHAR(6)), 6) AS Serial,
						CONVERT(VARCHAR, ISNULL(FD.Amount, 0.00))						AS Amount,
						IIF(DBFRD.SuspiciousCheque = 1, 'true', 'false')				AS [Kappa Flag],
						TX.TransactionSetId												AS [T-set Identifier],
						TX.CollectingParticipantId										AS [Collecting Participant],
						RIGHT('000000' + CAST(FD.SwitchedSortCode AS VARCHAR(6)), 6) AS [Switched Sortcode],
						RIGHT('00000000' + CAST(FD.SwitchedAccount AS VARCHAR(8)), 8) AS [Switched Account],
						ITMTYPE.ItemTypeCode											AS [Debit Item Type],
						FD.TranCode														AS [Debit Item Transaction Code],
						IIF(FD.Represent = 1, 'true', 'false')			AS [Represented Item Indicator]
					INTO
						#EligibleItems
					FROM
						@EligibleISOMSG06Tsets	AS ETSET
					INNER JOIN
						[Base].[vw_TXSet]		AS TX
					ON
						ETSET.InternalTxId = TX.InternalTxId
					INNER JOIN
						Base.Debit				AS DB WITH (SNAPSHOT)
					ON
						DB.ItemId = ETSET.ItemId
					INNER JOIN
						Base.vw_FinalDebit		AS FD
					ON
						DB.DebitId = FD.DebitId
					INNER JOIN
						Base.ItemUpdate			AS IU WITH (SNAPSHOT)
					ON
						IU.InternalId = DB.ItemId
					INNER JOIN
						Base.Core				AS CO WITH (SNAPSHOT)
					ON
						CO.CoreId = IU.CoreID
					INNER JOIN
						Lookup.ItemType			AS ITMTYPE WITH (SNAPSHOT)
					ON
						ITMTYPE.Id = FD.ItemType
					LEFT JOIN
						Base.DebitFraudData		AS DBFRD WITH (SNAPSHOT)
					ON
						DBFRD.ItemId = DB.ItemId
					WHERE
						CO.IntMessageType = '06MA01'
					AND FD.PayingParticipantId = @AgencyId;


					SELECT
						[Result].[RowValue]
					FROM
						(
							SELECT
								'Item ID,Sortcode,Account,Serial,Amount,Kappa Flag,T-set Identifier,Collecting Participant,Switched Sortcode,Switched Account,Debit Item Type,Debit Item Transaction Code,Represented Item Indicator'	AS RowValue,
								1																																																		AS RNO,
								'1'																																																		AS [T-set Identifier],
								'1'																																																		AS [Debit Item Type],
								'1'																																																		AS [Item ID]
							UNION ALL
							SELECT
								(
									SELECT
										CONCAT	([Item ID], ',', [A].[Sortcode], ',', [A].[Account], ',', [A].[Serial], ',', [A].[Amount], ',', [A].[Kappa Flag], ',', [T-set Identifier], ',', [Collecting Participant], ',', [A].[Switched Sortcode], ',', [A].[Switched Account], ',', [Debit Item Type], ',', [Debit Item Transaction Code], ',', [A].[Represented Item Indicator])
								)	AS RowValue,
								2	AS RNO,
								[T-set Identifier],
								[Debit Item Type],
								[Item ID]
							FROM
								(
									SELECT
										[Sortcode]	,
										[Account],
										[Serial],
										[Amount],
										[Kappa Flag],
										[Switched Sortcode],
										[Switched Account],
										[Represented Item Indicator]
									FROM
										#EligibleItems
								) AS A
						) AS Result
					ORDER BY
						[Result].[RNO],
						[Result].[T-set Identifier],
						[Result].[Debit Item Type],
						[Result].[Item ID];

				END;
			IF (XACT_STATE()) = 1
				BEGIN
					COMMIT	TRANSACTION;
				END;
		END TRY
		BEGIN CATCH
			IF (XACT_STATE()) = -1
				BEGIN
					ROLLBACK TRANSACTION;
				END;
		END CATCH;
	END;

GO
GRANT
	EXECUTE
ON [Agency].[usp_ReturnAgencyISOMSG06CSV]
TO
	AgencyISOMsgExtractor;

GO


EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'STAR',
	@level0type = N'SCHEMA',
	@level0name = N'Agency',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReturnAgencyISOMSG06CSV';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This Stored Procedure returns the MSG06 Items in CSV format for a given AgencyId.',
	@level0type = N'SCHEMA',
	@level0name = N'Agency',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReturnAgencyISOMSG06CSV';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Agency',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReturnAgencyISOMSG06CSV';


