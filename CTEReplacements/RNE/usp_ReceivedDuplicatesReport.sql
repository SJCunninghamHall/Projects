/****************************************************************************************
* Stored Procedure:[WAR].[usp_ReceivedDuplicatesReport]
* Description: Create No Pays Duplicate Cheque Report - Contains items that we have received in MSG06 where an APG operator has assigned a
*				No pay reason as Duplicate Cheque
* Sort Order : ParticipantName
* Amendment History
***************************************************************************************** 
* Version		Name						Date               Reason
* 1.3.0			Mazar Shaik				    14 Aug 2017        Create No Pays Duplicate Cheque Report
*****************************************************************************************/
CREATE PROCEDURE [WAR].[usp_ReceivedDuplicatesReport]
	@BusinessDate	VARCHAR(8)
AS
	BEGIN

		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		BEGIN TRY

			SELECT	DISTINCT
					ParticipantID,
					Participantname
			INTO
					#ParticipantDetails
			FROM
					[Report].[dimParticipantData];

			CREATE NONCLUSTERED INDEX nci_ParticipantID
			ON #ParticipantDetails (ParticipantID);

			SELECT
				PD	.ParticipantName	AS [Collecting Participant],
				DT.CollectingLocation	AS [Collecting Location],
				DI.DebitId				AS UIN,
				DI.Sortcode,
				DI.AccountNumber		AS [Account Number],
				DI.Serial				AS [Serial Number],
				FD.Amount				AS [DR Value]
			FROM
				[Report.dimDebitInformation]	AS DI
			INNER JOIN
				[Report].[factDebitAmounts]		AS FD
			ON
				FD.DebitId = DI.DebitId
			INNER JOIN
				Report.vw_DimTransactionSet		AS DT
			ON
				DT.TransactionSetId = FD.TransactionSetKey
			INNER JOIN
				#ParticipantDetails				AS PD
			ON
				PD.ParticipantID = DT.CollectingParticipantId
			WHERE
				DI.cf_NoPaySuspectRsn = 'Duplicate Cheque'
			AND DI.SettlementDate = @BusinessDate
			ORDER BY
				PD.ParticipantName;


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
ON [WAR].[usp_ReceivedDuplicatesReport]
TO
	[RnEWAR];
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'RnEReportDataWarehouse',
	@level0type = N'SCHEMA',
	@level0name = N'WAR',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReceivedDuplicatesReport';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Create No Pays Duplicate Cheque Report - Contains items that we have received in MSG06 where an APG operator has assigned a No pay reason as Duplicate Cheque',
	@level0type = N'SCHEMA',
	@level0name = N'WAR',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReceivedDuplicatesReport';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'WAR',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReceivedDuplicatesReport';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Calling Application',
	@value = N'iPSL.RNE.WARReceivedDuplicates.dtsx',
	@level0type = N'SCHEMA',
	@level0name = N'WAR',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReceivedDuplicatesReport';

GO