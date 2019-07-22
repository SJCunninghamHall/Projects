CREATE PROCEDURE [RnEWareHouseReports].[usp_SLCSubmissionBreakdownMSG07DocLevelPDFReport]
/*****************************************************************************************************
* Name				: [RnEWareHouseReports].[usp_SLCSubmissionBreakdownMSG07DocLevelPDFReport]
* Description		: Create Submission Breakdown PDF Report -Contains File level details of the MSG07 Sent to switch to track the SLC.
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
				CASE
					WHEN CONVERT(VARCHAR(8), DC.CreatedDate, 108)
					BETWEEN '00:00:00' AND '10:00:59'
					THEN 'TimeGroup1'
					WHEN CONVERT(VARCHAR(8), DC.CreatedDate, 108)
					BETWEEN '10:01:00' AND '12:00:59'
					THEN 'TimeGroup2'
					WHEN CONVERT(VARCHAR(8), DC.CreatedDate, 108)
					BETWEEN '12:01:00' AND '14:30:59'
					THEN 'TimeGroup3'
					WHEN CONVERT(VARCHAR(8), DC.CreatedDate, 108)
					BETWEEN '14:31:00' AND '15:00:59'
					THEN 'TimeGroup4'
					WHEN CONVERT(VARCHAR(8), DC.CreatedDate, 108)
					BETWEEN '15:01:00' AND '15:30:59'
					THEN 'TimeGroup5'
					ELSE 'TimeGroup6'
				END											AS [TimeGroup],
				CONVERT(VARCHAR(8), DC.CreatedDate, 108)	AS [Time],
				DC.NumberOfEntries							AS [Volume],
				CASE
					WHEN MSG08 IN
							(
								SELECT
									EntityState
								FROM
									@MSG08AckRcvd
							)
					THEN NULL
					ELSE REPLACE(ISNULL(DC.ReasonCode, ''), '"', '')
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
					ELSE REPLACE([RnEWareHouseReports].[ufn_GetDocErrorDesc](DC.ReasonCode), '"', '')
				END											AS [ErrorDesc],
				DC.DebitId,
				DA.Amount									AS [Amount]
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
				[TimeGroup],
				[Time],
				[Volume],
				[ReasonCode],
				[ErrorDesc],
				SUM([Amount])	AS [Value]
			FROM
				#MSG07Documents
			GROUP BY
				[File Name],
				[TimeGroup],
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
ON [RnEWareHouseReports].[usp_SLCSubmissionBreakdownMSG07DocLevelPDFReport]
TO
	[RnESsrsDwAccess];

GO

EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_SLCSubmissionBreakdownMSG07DocLevelPDFReport';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This stored procedure is used to create Submission Breakdown CSV Report -Contains File level details of the MSG07 Sent to switch to track the SLC.',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_SLCSubmissionBreakdownMSG07DocLevelPDFReport';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'RnEReportDataWarehouse',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_SLCSubmissionBreakdownMSG07DocLevelPDFReport';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Calling Application',
	@value = N'iPSL.RNE.SubmissionBreakdownMSG07PDFReport.rdl',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_SLCSubmissionBreakdownMSG07DocLevelPDFReport';

GO