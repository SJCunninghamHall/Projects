/****************************************************************************************
* Stored Procedure:[WAR].[usp_WronglyClaimedReport]
* Description: Create Default Wrongly Claimed Report -Contains items that have been flagged in APG and the APG operator has amended the amount.
* Amendment History
*****************************************************************************************
* Version		Name						Date               Reason
* 1.3.0			Bhaskar Reddy			    02 Aug 2017        Create Default Wrangly Claimed Report
*****************************************************************************************/
CREATE PROCEDURE [WAR].[usp_WronglyClaimedReport]
	@BusinessDate	VARCHAR(8)
AS
	BEGIN

		SET NOCOUNT ON;

		SET XACT_ABORT ON;

		BEGIN TRY

			BEGIN

				SELECT	DISTINCT
						ParticipantID,
						Participantname
				INTO
						#ParticipantDetailsCTE
				FROM
						[Report].[dimParticipantData];

				CREATE NONCLUSTERED INDEX nci_ParticipantID
				ON #ParticipantDetailsCTE (ParticipantID);

				SELECT
					PD	.ParticipantName	AS [Collecting Participant],
					TS.CollectingLocation	AS [Collecting Location],
					DI.DebitId				AS USIN,
					DI.Sortcode,
					DI.AccountNumber		AS [Account Number],
					DI.Serial				AS [Serial Number],
					DA.OriginalAmount		AS [Original DR Value],
					DA.Amount				AS [Amended DR Value],
					'Wrongly Claimed'		AS Reason
				FROM
					[Report].[dimDebitInformation]			AS DI
				INNER JOIN
					[Report].[factDebitAmounts]				AS DA
				ON
					DI.DebitId = DA.DebitId
				INNER JOIN
					Report.vw_DimTransactionSet				AS TS
				ON
					DA.TransactionSetKey = TS.TransactionSetId
				INNER JOIN
					#ParticipantDetailsCTE					AS PD
				ON
					TS.CollectingParticipantId = PD.ParticipantID
				INNER JOIN
					[Report].[dimDebitEntityStateHistory]	AS DH
				ON
					DI.DebitId = DH.DebitId
				WHERE
					DH.MSG06 IN ( 541,
									550,
									551
								) --it will be either one of the entity state exists always
				AND DA.Amount != DA.Originalamount
				AND DI.SettlementDate = @BusinessDate;
			END;

		END TRY
		BEGIN CATCH
			DECLARE @Number INT = ERROR_NUMBER();
			DECLARE @Message VARCHAR(4000) = ERROR_MESSAGE();
			DECLARE @UserName NVARCHAR(128) = CONVERT(sysname, CURRENT_USER);
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
ON [WAR].[usp_WronglyClaimedReport]
TO
	[RnEWAR];
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'RnEReportDataWarehouse',
	@level0type = N'SCHEMA',
	@level0name = N'WAR',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_WronglyClaimedReport';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Create Default Wrongly Claimed Report -Contains items that have been flagged in APG and the APG operator has amended the amount.',
	@level0type = N'SCHEMA',
	@level0name = N'WAR',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_WronglyClaimedReport';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'WAR',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_WronglyClaimedReport';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Calling Application',
	@value = N'iPSL.RNE.WARWronglyClaimed.dtsx',
	@level0type = N'SCHEMA',
	@level0name = N'WAR',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_WronglyClaimedReport';

GO

