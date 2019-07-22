CREATE PROCEDURE [RnEWareHouseReports].[usp_SLCSubmissionBreakdownMSG07DocLevelReport]
/*****************************************************************************************************
* Name				: [RnEWareHouseReports].[usp_SLCSubmissionBreakdownMSG07DocLevelReport]
* Description		: Create Submission Breakdown CSV Report -Contains File level details of the MSG07 Sent to switch to track the SLC.
* Type of Procedure : Interpreted stored procedure
* Author			: Nageswara Rao
* Creation Date		: 02/01/2018
* Last Modified		: N/A
*******************************************************************************************************/
AS
	BEGIN TRY

		BEGIN

			DECLARE @MSG08AckRcvd TABLE
				(
					EntityState INT
				);

			INSERT INTO
				@MSG08AckRcvd
			SELECT
				EntityState
			FROM
				Report.dimReportEntityState AS ES
			INNER JOIN
				Report.dimReportMaster		AS RM
			ON
				ES.ReportId = RM.ReportID
			WHERE
				ReportName	= 'InClearingSubmissionBreakdownReport'
			AND ColumnName = 'AckRcvd'
			AND MessageType = 'MSG08';

			SELECT
				DC	.DocumentMessageId						AS [File Name],
				CONVERT(VARCHAR(8), DC.CreatedDate, 108)	AS [Time],
				DC.NumberOfEntries							AS [Volume],
				DC.DebitId,
				DA.Amount									AS [Amount],
				CASE
					WHEN MSG08 IN
							(
								SELECT
									EntityState
								FROM
									@MSG08AckRcvd
							)
					THEN NULL
					ELSE ISNULL(DC.ReasonCode, '')
				END											AS [ReasonCode],
				CASE
					WHEN MSG08 IN
							(
								SELECT
									EntityState
								FROM
									@MSG08AckRcvd
							)
					THEN NULL
					ELSE [RnEWareHouseReports].[ufn_GetDocErrorDesc](DC.ReasonCode)
				END											AS [ErrorDesc]
			INTO
				#MSG07Documents
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
			WHERE
				DT.isCurrentBusinessDate = 1
			AND DC.MessageType = 'MSG07';

			SELECT
				[File Name],
				[Time],
				[Volume],
				SUM([Amount])	AS [Value],
				[ReasonCode],
				[ErrorDesc]
			FROM
				#MSG07Documents
			GROUP BY
				[File Name],
				[Time],
				[Volume],
				[ReasonCode],
				[ErrorDesc]
			ORDER BY
				[Time] ASC;

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
ON [RnEWareHouseReports].[usp_SLCSubmissionBreakdownMSG07DocLevelReport]
TO
	[RnESsrsDwAccess];

GO

EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_SLCSubmissionBreakdownMSG07DocLevelReport';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This stored procedure is used to create Submission Breakdown CSV Report -Contains File level details of the MSG07 Sent to switch to track the SLC.',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_SLCSubmissionBreakdownMSG07DocLevelReport';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'RnEReportDataWarehouse',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_SLCSubmissionBreakdownMSG07DocLevelReport';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Calling Application',
	@value = N'iPSL.RNE.SubmissionBreakdownMSG07Report.dtsx',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_SLCSubmissionBreakdownMSG07DocLevelReport';

GO