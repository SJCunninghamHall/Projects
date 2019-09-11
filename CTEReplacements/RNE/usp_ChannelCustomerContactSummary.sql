CREATE PROCEDURE [RnEWareHouseReports].[usp_ChannelCustomerContactSummary]
	(
		@BusinessDate	DATE
	)
/*****************************************************************************************************************
* Stored Procedure	: [RnEWareHouseReports].[usp_ChannelCustomerContactSummary]
* Author					: Akuri Reddy
* Description			: Extracts credits belongs to configured channels 
* Creation Date		: 25/05/2018
* Last Modified		:
******************************************************************************************************************/
AS
	BEGIN

		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		BEGIN TRY

			DECLARE @CurrentDateKey INT =
						(
							SELECT	TOP 1
									DateKey
							FROM
									Report.dimDate
							WHERE
									FullDate = @BusinessDate
						);
			DECLARE @ReportID INT =
						(
							SELECT
								ReportID
							FROM
								[Report].[dimReportMaster]
							WHERE
								ReportName	= 'Report34ChannelCustomerContact'
						);

			SELECT
				DI	.DebitId,
				CA.TransactionSetKey,
				TS.AltSource,
				C.ChannelID
			INTO
				#EligibleDebits
			FROM
				[Report].dimDebitInformation	AS DI
			INNER JOIN
				Report.factDebitAmounts			AS CA
			ON
				CA.DebitId = DI.DebitId
			INNER JOIN
				Report.dimTransactionSet		AS TS
			ON
				CA.TransactionSetKey = TS.TransactionSetId
			INNER JOIN
				Config.Channel					AS C
			ON
				C.ChannelID = TS.AltSource
			AND C.IsInclude = 1
			WHERE
				CA.DateKey = @CurrentDateKey
			AND DI.ItemType = 'RTPI'
			AND C.ReportId = @ReportID;

			CREATE NONCLUSTERED INDEX nci_TransactionSetKey
			ON #EligibleDebits (TransactionSetKey);

			SELECT
				CE	.CreditId,
				CE.MSG01,
				CE.MSG02,
				CE.MSG03,
				CE.EntityType,
				CE.Revision,
				CE.EntityId,
				CA.TransactionSetKey,
				ED.AltSource,
				CI.Sortcode,
				CI.AccountNumber,
				CI.Reference,
				ED.ChannelID,
				ROW_NUMBER() OVER (PARTITION BY
									CE.CreditId
									ORDER BY
									EntityId DESC
								) AS RKD
			INTO
				#EligibleCreditsOfDebits
			FROM
				[Report].[dimCreditEntityStateHistory]	AS CE
			INNER JOIN
				Report.dimCreditInformation				AS CI
			ON
				CI.CreditId = CE.CreditId
			INNER JOIN
				Report.factCreditAmounts				AS CA
			ON
				CA.CreditId = CE.CreditId
			INNER JOIN
				#EligibleDebits							AS ED
			ON
				CA.TransactionSetKey = ED.TransactionSetKey
			WHERE
				CE.MessageType IN ( 'MSG01',
									'MSG02',
									'MSG03'
								)
			AND CE.DateKey = @CurrentDateKey
			AND CA.DateKey = @CurrentDateKey
			AND CE.EntityType IN (	'I',
									'D'
								);

			CREATE NONCLUSTERED INDEX nci_MSG01
			ON #EligibleCreditsOfDebits (MSG01);
			CREATE NONCLUSTERED INDEX nci_MSG02
			ON #EligibleCreditsOfDebits (MSG02);
			CREATE NONCLUSTERED INDEX nci_MSG03_EntityType
			ON #EligibleCreditsOfDebits (MSG03, EntityType);
			CREATE NONCLUSTERED INDEX nci_CreditId_RKD
			ON #EligibleCreditsOfDebits (CreditId, RKD);

			SELECT
				CreditId
			INTO
				#SubmittedCredits
			FROM
				#EligibleCreditsOfDebits
			WHERE
				MSG01 = 90
			GROUP BY
				CreditId;

			CREATE NONCLUSTERED INDEX nci_CreditId
			ON #SubmittedCredits (CreditId);

			SELECT
				CreditId,
				MSG01,
				ROW_NUMBER() OVER (PARTITION BY
									CreditId
									ORDER BY
									EntityId DESC
								) AS RKD
			INTO
				#HoldoverCredits
			FROM
				#EligibleCreditsOfDebits
			WHERE
				MSG01 > 0;

			CREATE NONCLUSTERED INDEX nci_CreditId_RKD
			ON #HoldoverCredits (CreditId, RKD);

			SELECT
				CreditId,
				MSG02,
				ROW_NUMBER() OVER (PARTITION BY
									CreditId
									ORDER BY
									EntityId DESC
								) AS RKD
			INTO
				#AckNackCredits
			FROM
				#EligibleCreditsOfDebits
			WHERE
				MSG02 > 0;

			CREATE NONCLUSTERED INDEX nci_CreditId_RKD
			ON #AckNackCredits (CreditId, RKD);

			SELECT
				CreditId,
				MSG03,
				ROW_NUMBER() OVER (PARTITION BY
									CreditId
									ORDER BY
									EntityId DESC
								) AS RKD
			INTO
				#RejectedCredits
			FROM
				#EligibleCreditsOfDebits
			WHERE
				MSG03 > 0
			AND EntityType = 'I';

			CREATE NONCLUSTERED INDEX nci_CreditId_RKD
			ON #RejectedCredits (CreditId, RKD);

			SELECT
				Final.Channel,
				Final.[ICS Credit UUID],
				Final.[Credit Sortcode],
				Final.[Credit Account Number],
				Final.[Reference Number],
				[Final].[Submitted to Switch],
				[Final].[Accepted By Switch]
			FROM
				(
					SELECT
						EC	.ChannelID								AS Channel,
						EC.CreditId									AS "ICS Credit UUID",
						EC.Sortcode									AS "Credit Sortcode",
						EC.AccountNumber							AS "Credit Account Number",
						EC.Reference								AS "Reference Number",
						IIF(SC.CreditId IS NOT NULL, 'Yes', 'No') AS "Submitted to Switch",
						CASE
							WHEN SC.CreditId IS NOT NULL
							AND HC.MSG01 = 165
							THEN 'Holdover'
							WHEN AckNak.MSG02 = 100
							AND ISNULL(RejC.MSG03, 0) NOT IN ( 130 )
							THEN 'Yes'
							ELSE 'No'
						END											AS "Accepted By Switch",
						ROW_NUMBER() OVER (PARTITION BY
											EC.CreditId
											ORDER BY
											EC.CreditId DESC
										)						AS RKD
					FROM
						#EligibleCreditsOfDebits	AS EC
					LEFT JOIN
						#SubmittedCredits			AS SC
					ON
						SC.CreditId = EC.CreditId
					LEFT JOIN
						#HoldoverCredits			AS HC
					ON
						HC.CreditId = EC.CreditId
					AND [HC].[RKD] = 1
					LEFT JOIN
						#AckNackCredits				AS AckNak
					ON
						AckNak.CreditId = EC.CreditId -- SJC
					AND [AckNak].[RKD] = 1
					LEFT JOIN
						#RejectedCredits			AS RejC
					ON
						RejC.CreditId = EC.CreditId
					AND [RejC].[RKD] = 1
					WHERE
						[EC].[RKD] = 1
				)					AS Final
			LEFT JOIN
				Report.dimChannel	AS CH
			ON
				CH.Channel = Final.Channel
			WHERE
				[Final].[RKD] = 1
			ORDER BY
				CH.Description DESC,
				Final.[ICS Credit UUID],
				Final.[Credit Sortcode],
				Final.[Credit Account Number];

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
ON [RnEWareHouseReports].[usp_ChannelCustomerContactSummary]
TO
	[RnEWAR];
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'RnEReportDataWarehouse',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ChannelCustomerContactSummary';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Extracts credits belongs to configured channels',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ChannelCustomerContactSummary';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ChannelCustomerContactSummary';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Calling Application',
	@value = N'iPSL.RNE.ChannelCustomerContactSummaryReport.rdl',
	@level0type = N'SCHEMA',
	@level0name = N'RnEWareHouseReports',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ChannelCustomerContactSummary';
GO
