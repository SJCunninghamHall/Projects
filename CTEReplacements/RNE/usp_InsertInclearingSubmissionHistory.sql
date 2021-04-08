CREATE PROCEDURE [DataImport].[usp_InsertInclearingSubmissionHistory]
/*****************************************************************************************************
* Name				: [DataImport].[usp_InsertInclearingSubmissionHistory]
* Description		: This stored procedure INSERTs the final details of the Historical Data for InclearingSubmissionHistory
* Type of Procedure : Interpreted stored procedure
* Author			: Asish
* Creation Date		: 06/05/2018
* Last Modified		: N/A
*******************************************************************************************************/
AS
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

	BEGIN TRY

		BEGIN

			SELECT
				EntityState
			INTO 
				#MSG08AckRcvd
			FROM
				Report.dimReportEntityState AS ES
			INNER JOIN
				Report.dimReportMaster		AS RM
			ON
				ES.ReportId = RM.ReportID
			WHERE
				ReportName	= 'Inclearing Submission Repair Report'
			AND ColumnName = 'AckRcvd'
			AND MessageType = 'MSG08';

			CREATE NONCLUSTERED INDEX nci_EntityState
			ON #MSG08AckRcvd (EntityState);

			SELECT
				EntityState
			INTO
				#MSG08NegAckRcvd
			FROM
				Report.dimReportEntityState AS ES
			INNER JOIN
				Report.dimReportMaster		AS RM
			ON
				ES.ReportId = RM.ReportID
			WHERE
				ReportName	= 'Inclearing Submission Repair Report'
			AND ColumnName = 'NegAckRcvd'
			AND MessageType = 'MSG08';

			CREATE NONCLUSTERED INDEX nci_EntityState
			ON #MSG08NegAckRcvd (EntityState);

			SELECT
				EntityState
			INTO
				#MSG09Rejected
			FROM
				Report.dimReportEntityState AS ES
			INNER JOIN
				Report.dimReportMaster		AS RM
			ON
				ES.ReportId = RM.ReportID
			WHERE
				ReportName	= 'Inclearing Submission Repair Report'
			AND ColumnName = 'Rejected'
			AND MessageType = 'MSG09';

			CREATE NONCLUSTERED INDEX nci_EntityState
			ON #MSG09Rejected (EntityState);

			SELECT
				EntityState
			INTO
				#MSG09Repaired
			FROM
				Report.dimReportEntityState AS ES
			INNER JOIN
				Report.dimReportMaster		AS RM
			ON
				ES.ReportId = RM.ReportID
			WHERE
				ReportName	= 'Inclearing Submission Repair Report'
			AND ColumnName = 'Repaired'
			AND MessageType = 'MSG09';

			CREATE NONCLUSTERED INDEX nci_EntityState
			ON #MSG09Repaired (EntityState);

			SELECT
				DI	.DebitId,
				DI.Sortcode,
				DI.ItemType,
				TX.AltSource	AS ChannelID,
				1				AS TotalSubmitted,
				DT.FullDate,
				CASE
					WHEN DC.MSG08 IN
							(
								SELECT
									EntityState
								FROM
									#MSG08NegAckRcvd
							)
					OR	DC.MSG09 IN
							(
								SELECT
									EntityState
								FROM
									#MSG09Rejected
							)
					THEN 1
					ELSE 0
				END				AS TotalRejected,
				CASE
					WHEN DC.RepairES IN
							(
								SELECT
									EntityState
								FROM
									#MSG09Repaired
							)
					THEN 1
					ELSE 0
				END				AS TotalRepaired,
				CASE
					WHEN (DC.MSG08 IN
							(
								SELECT
									EntityState
								FROM
									#MSG08NegAckRcvd
							)
						)
					AND DC.MSG09 IN
							(
								SELECT
									EntityState
								FROM
									#MSG09Rejected
							)
					THEN ISNULL(DC.MSG09ErrorCode, '')
					WHEN (DC.MSG08 IN
							(
								SELECT
									EntityState
								FROM
									#MSG08AckRcvd
							)
						)
					AND DC.MSG09 IN
							(
								SELECT
									EntityState
								FROM
									#MSG09Rejected
							)
					THEN ISNULL(DC.MSG09ErrorCode, '')
					WHEN DC.MSG08 IN
							(
								SELECT
									EntityState
								FROM
									#MSG08NegAckRcvd
							)
					THEN ISNULL(DC.ReasonCode, '')
					ELSE ''
				END				AS ErrorCode
			INTO
				#MSG07DocNakItems
			FROM
				Report.dimDocumentDebitsHistory AS DC
			INNER JOIN
				Report.dimDate					AS DT
			ON
				DT.FullDate = CONVERT(DATE, DC.CreatedDate)
			INNER JOIN
				Report.factDebitAmounts			AS DA
			ON
				DC.DebitId = DA.DebitId
			INNER JOIN
				Report.dimDebitInformation		AS DI
			ON
				DI.DebitId = DA.DebitId
			INNER JOIN
				Report.vw_DimTransactionSet		AS TX
			ON
				TX.TransactionSetId = DA.TransactionSetKey
			LEFT JOIN
				Config.AckNakStatus				AS RCode
			ON
				DC.ReasonCode = RCode.ReportingCode
			LEFT JOIN
				Config.AckNakStatus				AS ECode
			ON
				DC.MSG09ErrorCode = ECode.ReportingCode
			WHERE
				DT.isCurrentBusinessDate = 1
			AND DC.MessageType = 'MSG07'
			AND
			(
					(DC.MSG08 IN
						(
							SELECT
								EntityState
							FROM
								#MSG08AckRcvd
						)
					)
			OR
				(
					DC.MSG09 IN
						(
							SELECT
								EntityState
							FROM
								#MSG09Rejected
						)
			OR		DC.RepairES IN
						(
							SELECT
								EntityState
							FROM
								#MSG09Repaired
						)
				)
			OR		(DC.MSG08 IN
						(
							SELECT
								EntityState
							FROM
								#MSG08NegAckRcvd
						)
					)
				);



			SELECT
				FullDate		AS BusinessDate,
				MD.Sortcode,
				AG.AgencyName,
				ItemType,
				ChannelID,
				CH.Description	AS ChannelDesc,
				TotalSubmitted,
				TotalRejected,
				TotalRepaired,
				ErrorCode		AS SwitchErrorCode
			FROM
				MSG07DocNakItems					AS MD
			INNER JOIN
				[Report].[dimAgencySortCodeList]	AS AG
			ON
				AG.SortCode = MD.Sortcode
			INNER JOIN
				[Report].[dimChannel]				AS CH
			ON
				CH.Channel = MD.ChannelID;

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
GO

GRANT
	EXECUTE
ON [DataImport].[usp_InsertInclearingSubmissionHistory]
TO
	[RnEReportDwDataImporter];

GO

EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'DataImport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_InsertInclearingSubmissionHistory';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This stored procedure Inserts Historical Data Into InclearingSubmissionHistoryTable',
	@level0type = N'SCHEMA',
	@level0name = N'DataImport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_InsertInclearingSubmissionHistory';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'RnEReportDataWarehouse',
	@level0type = N'SCHEMA',
	@level0name = N'DataImport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_InsertInclearingSubmissionHistory';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Calling Application',
	@value = N'IPSL.RNE.RefreshDataWarehouse.dtsx',
	@level0type = N'SCHEMA',
	@level0name = N'DataImport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_InsertInclearingSubmissionHistory';

GO
