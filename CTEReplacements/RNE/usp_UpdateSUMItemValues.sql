CREATE PROCEDURE [Posting].[usp_UpdateSUMItemValues]
/*****************************************************************************************************
* Name				: [Posting].[usp_UpdateSUMItemValues]
* Description		: Update SUm Debit and Credit Entries for final Extract
* Called By			: IPSL.RNE.SUMExtractXML.dtsx
* Type of Procedure : Interpreted stored procedure
* Author			: Asish
* Creation Date		: 20/11/2017
* Last Modified		:  
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************/
AS
	BEGIN

		SET NOCOUNT ON;

		BEGIN TRANSACTION;

		BEGIN TRY

			DECLARE
				@Businessdate		DATE,
				@PrevBusinessDate	DATE,
				@NextBusinessDate	DATE;

			SELECT
				@Businessdate		= BusinessDate,
				@PrevBusinessDate	= PreviousDate,
				@NextBusinessDate	= NextDate
			FROM
				Config.ProcessingDate;

			EXEC [Base].[usp_LogEvent]
				1,
				'[Posting].[usp_UpdateSUMItemValues]',
				'Enter';

			--Items which could have been rejected by part of other message like MSG11 will be flagged for excluding from Paid

			SELECT
				DebitId
			INTO
				#ExcludeDebits
			FROM
				[Staging].[DebitMsgES] AS Db
			WHERE
				EXISTS
				(
					SELECT
						1
					FROM
						[Config].[SumMsgEntityState] AS cfn
					WHERE
						(
							Db.MessageType = cfn.MessageType
					AND		Db.EntityState = cfn.EntityState
					AND		PaidInd = 'N'
						)
				)
			GROUP BY
				DebitId;


			CREATE NONCLUSTERED INDEX nci_DebitId
			ON #ExcludeDebits (DebitId);


			UPDATE
				Db
			SET
			PayDecision = 'N'
			FROM
				[Staging].[DebitMsgES]	AS Db
			INNER JOIN
				#ExcludeDebits			AS Ex
			ON
				Db.DebitId = Ex.DebitId;


			SELECT
				TransactionSetId
			INTO
				#IncludeDebits
			FROM
				[Staging].[DebitMsgES] AS Db
			WHERE
				EXISTS
				(
					SELECT
						1
					FROM
						[Config].[SumMsgEntityState] AS cfn
					WHERE
						(
							Db.MessageType = cfn.MessageType
					AND		Db.EntityState = cfn.EntityState
					AND		PaidInd = 'Y'
					AND		CrDrInd = 1
						)
				)
			GROUP BY
				TransactionSetId;


			CREATE NONCLUSTERED INDEX nci_DebitId
			ON #IncludeDebits (DebitId);


			UPDATE
				Cr
			SET
			PayDecision = 'Y'
			FROM
				[Staging].[CreditMsgEs] AS Cr
			INNER JOIN
				#IncludeDebits			AS Ex
			ON
				Cr.TransactionSetId = Ex.TransactionSetId;



			--Getting the MultiDebit Paid amount


			SELECT
				TransactionSetId,
				Amount,
				ROW_NUMBER() OVER (PARTITION BY
									DebitId
									ORDER BY
									Db.MessageType DESC
								) AS LatestDebit
			INTO
				#getLatest
			FROM
				[Staging].[DebitMsgES]			AS Db
			INNER JOIN
				[Config].[SumMsgEntityState]	AS cfn
			ON
				(
					Db.MessageType = cfn.MessageType
			AND		Db.EntityState = cfn.EntityState
			AND		PaidInd = 'Y'
			AND
			(
					Db.EntityState NOT IN ( 210,
											211
										)
			AND		Db.SettlementDate = @Businessdate
				)
				)
			WHERE
				NoOfDebit > 1;



			CREATE NONCLUSTERED INDEX nci_LatestDebit
			ON #getLatest (LatestDebit)
			WHERE LatestDebit = 1;


			SELECT
				TransactionSetId,
				SUM(Amount) AS MltDbPaidAmnt
			INTO
				#AGGDBAmt
			FROM
				#getLatest
			WHERE
				LatestDebit = 1
			GROUP BY
				TransactionSetId;



			CREATE NONCLUSTERED INDEX nci_TransactionSetId
			ON #AGGDBAmt (TransactionSetId);



			UPDATE
				DB
			SET
			DB	.MltDbPaidAmnt = [Agg].[MltDbPaidAmnt]
			FROM
				[Staging].[DebitMsgES]	AS DB
			INNER JOIN
				#AGGDBAmt				AS Agg
			ON
				DB.TransactionSetId = Agg.TransactionSetId;



			DROP TABLE IF EXISTS #getLatest; -- SJC - original code used the same name twice for two separate CTEs. Either drop and recreate or use a new name for the second temp table.


			SELECT
				TransactionSetId,
				Amount,
				ROW_NUMBER() OVER (PARTITION BY
									DebitId
									ORDER BY
									Db.MessageType DESC
								) AS LatestDebit
			INTO
				#getLatest
			FROM
				[Staging].[DebitMsgES]			AS Db
			INNER JOIN
				[Config].[SumMsgEntityState]	AS cfn
			ON
				(
					Db.MessageType = cfn.MessageType
			AND		Db.EntityState = cfn.EntityState
			AND		PaidInd = 'Y'
			AND
			(
					Db.EntityState NOT IN ( 210,
											211
										)
			AND		Db.SettlementDate = @Businessdate
				)
				)
			WHERE
				NoOfDebit > 1;



			CREATE NONCLUSTERED INDEX nci_LatestDebit
			ON #getLatest (LatestDebit)
			WHERE LatestDebit = 1;


			SELECT
				TransactionSetId,
				SUM(Amount) AS MltDbPaidAmnt
			INTO
				#AGGDBAmt
			FROM
				#getLatest
			WHERE
				LatestDebit = 1
			GROUP BY
				TransactionSetId;



			CREATE NONCLUSTERED INDEX nci_TransactionSetId
			ON #AGGDBAmt (TransactionSetId);



			UPDATE
				DB
			SET
			DB	.MltDbPaidAmnt = [Agg].[MltDbPaidAmnt]
			FROM
				[Staging].[CreditMsgES] AS DB
			INNER JOIN
				#AGGDBAmt				AS Agg
			ON
				DB.TransactionSetId = Agg.TransactionSetId;

			---Update the NPA Sort Code tredit Node for Responses we received from client on Debit node.

			UPDATE
				Cr
			SET
			Cr	.NPASortCode = Db.NPASortCode
			FROM
				Staging.CreditMsgES		AS Cr
			INNER JOIN
				[Staging].[DebitMsgES]	AS Db
			ON
				Cr.TransactionSetId = Db.TransactionSetId
			WHERE
				Cr.NoOfCredit = 1
			AND Db.NoOfDebit = 1
			AND Db.EntityState IN
					(
						SELECT
							EntityState
						FROM
							Config.SumMsgEntityState
						WHERE
							CrDrInd = 1
						AND PaidInd = 'Y'
					)
			AND Cr.MessageType NOT IN ( 'MSG06' )
			AND Db.NPASortCode IS NOT NULL
			AND Cr.NPASortCode IS NULL;




			--Update Charging Participant and MessageType to Credit records on Transaction Set level
			UPDATE
				Cr
			SET
			Cr	.ChargedParticipantId = Db.ChargedParticipantId,
				Cr.SWMessageType = Db.SWMessageType
			FROM
				Staging.CreditMsgES		AS Cr
			INNER JOIN
				[Staging].[DebitMsgES]	AS Db
			ON
				Cr.TransactionSetId = Db.TransactionSetId;







			--Updated HoldOver Date for NPA Posting Occured to Existing Records of Base Table...
			UPDATE
				TB
			SET
			HoldOverDate	= @NextBusinessDate
			FROM
				Outclearing.SumDayOneExtracts	AS TB
			INNER JOIN
				(
					SELECT
						DP	.TransactionSetIdWithVersion
					FROM
						Staging.DerivedPostingType AS DP
					WHERE
						DP.CreditEntityState IN ( 165 )
					AND DP.ProcessingDate = @Businessdate
					GROUP BY
						DP.TransactionSetIdWithVersion
				)								AS CTR
			ON
				TB.TransactionSetIdWithVersion = CTR.TransactionSetIdWithVersion;

			EXEC [Base].[usp_LogEvent]
				1,
				'[Posting].[usp_UpdateSUMItemValues]',
				'Exit';

			IF (XACT_STATE()) = 1
				BEGIN
					COMMIT	TRANSACTION;
				END;
		END TRY
		BEGIN CATCH
			IF XACT_STATE() <> 0
				ROLLBACK TRANSACTION;

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
ON [Posting].[usp_UpdateSUMItemValues]
TO
	[RNESVCAccess];

GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Update SUm Debit and Credit Entries for final Extract',
	@level0type = N'SCHEMA',
	@level0name = N'Posting',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_UpdateSUMItemValues';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Posting',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_UpdateSUMItemValues';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'iPSL.ICE.RNE.Database',
	@level0type = N'SCHEMA',
	@level0name = N'Posting',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_UpdateSUMItemValues';
GO



