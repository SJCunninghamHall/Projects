/*****************************************************************************************************
* Name              : [usp_GetStopsSingleMultiToApg]
* Description  	    : This Stored Procedure will fetch the records from [Base].StopsDetail table.
* Author			: Subrat Samal			   
*******************************************************************************************************
*Parameter Name				Type							   Description
*------------------------------------------------------------------------------------------------------

*******************************************************************************************************************************
* Amendment History
*------------------------------------------------------------------------------------------------------------------------------
* ID          Date             User					Reason
*****************************************************************************************************
* 001			31/01/2017 		Subrat Samal			Initial version
* 002			28/03/2017 		Jaisankar N.			Removed source detail id and added with participantId
* 003			09/05/2017 		Nisha Merline			Changed schema from LBG to RefOut
* 004			12/05/2017		Divya Singh				Changed the LogExecption sp name to SqlErrorLog
* 005			27/06/2017		Shiju					Added FileSource Condition <> 'IFCA'
* 006			03/07/2017		Bhaskar Reddy			Removed the table [Base].[StopsTravellerDetail] in sp
* 007			24/07/2017		Divya Singh				Code Review Action remove unused Parameter 
* 008			27/07/2017		Champika B				Code Review Action Deadlock Proof Changes
* 009			01/08/2017		Champika B				SQL code alignment
* 010			04/09/2017 		Nisha Merline			Code review action remove NOT functionality
* 011			04/09/2017		Champika B				Code Review Action remove version number
* 012			15/09/2017		Champika B				Number of Deadlock  retry value to config table
* 013           10/04/2018      Champika B				PBI 173917 Live hotfix STOPs change 
* 014           18/04/2018      Jaisankar N				PBI 173917 Live hotfix STOPs change & bug175498
* 015           30/01/2019      Mazar Shaik				PBI 208078 CR236 - Commercial Lotted Stops - Ref Data Changes
* 016			16/05/2019		Shiju B					PBI 218506 CR392 - NPA Stops
* 017			23/05/2019		Byamakesh				PBI 218506 CR392 - NPA Stops, added @BusinessDate variable and UNION
* 018			18/06/2019		Byamakesh				Fix for bug 222447 - Corrected BusinessDay check with EffectiveFrom
******************************************************************************************************/
CREATE PROCEDURE [RefOut].[usp_GetStopsSingleMultiToApg]
AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @ErrorNumber INT;
		DECLARE @ErrorMessage VARCHAR(4000);
		DECLARE @Severity INT;
		DECLARE @State INT;
		DECLARE @Procedure VARCHAR(128);
		DECLARE @Line INT;
		DECLARE @Tries INT = 1;
		DECLARE @TriesVal INT;
		DECLARE @BusinessDate DATETIME;
		SET @TriesVal =
			(
				SELECT
					[Value]
				FROM
					Base.ConfigSettings
				WHERE
					[Name]	= 'DeadLockRetry'
			);
		SET @BusinessDate =
			(
				SELECT
					[BusinessDate]
				FROM
					[Base].[BusinessDate]
			);

		WHILE @Tries <= @TriesVal
			BEGIN

				BEGIN TRY

					SELECT
						[BaseData]	.[StartSortCode],
						[BaseData].[StartAccountNumber],
						IntStartChequeNumber,
						[BaseData].[EndSortCode],
						[BaseData].[EndAccountNumber],
						[BaseData].[IntEndChequeNumber],
						ParticipantId,
						[BaseData].[StopStatus]
					INTO
						#CTE
					FROM
						(
							SELECT
								RIGHT('000000' + [SD].[SortCode], 6)		AS StartSortCode,
								RIGHT('00000000' + [SD].[AccountNumber], 8) AS StartAccountNumber,
								[StartChequeNumber]							AS IntStartChequeNumber,
								RIGHT('000000' + [SD].[SortCode], 6)		AS EndSortCode,
								RIGHT('000000' + [SD].[AccountNumber], 8) AS EndAccountNumber,
								CASE
									WHEN [EndChequeNumber] = '000000'
									THEN [StartChequeNumber]
									ELSE [EndChequeNumber]
								END											AS IntEndChequeNumber,
								[SD].ParticipantId,
								CASE
									WHEN [SD].SortCode = ST.SortCode
									THEN 1
									ELSE 2
								END											AS StopStatus
							FROM
								[Base].[StopsDetail]	AS SD
							INNER JOIN
								[Base].[StopsHeader]	AS SH
							ON
								[SD].[HeaderId] = [SH].[HeaderId]
							LEFT JOIN
								[Manual].LBGStopTypes	AS ST
							ON
								ST.SortCode = RIGHT('000000' + CONVERT(VARCHAR(6), [SD].SortCode), 6)
							WHERE
								StopType IN ( 'S',
												'M'
											)
							AND
							(
									[SH].[FileSource] = 'NCA'
							OR		[SH].[FileSource] = 'RCBS'
							OR		[SH].[FileSource] = 'CS'
								)
							AND ISNUMERIC([StartChequeNumber]) = 1
							AND ISNUMERIC([EndChequeNumber]) = 1
							UNION ALL
							SELECT
								RIGHT('000000' + [SD].[SortCode], 6)		AS StartSortCode,
								RIGHT('00000000' + [SD].[AccountNumber], 8) AS StartAccountNumber,
								[StartChequeNumber]							AS IntStartChequeNumber,
								RIGHT('000000' + [SD].[SortCode], 6)		AS EndSortCode,
								RIGHT('000000' + [SD].[AccountNumber], 8) AS EndAccountNumber,
								CASE
									WHEN [EndChequeNumber] = '000000'
									THEN [StartChequeNumber]
									ELSE [EndChequeNumber]
								END											AS IntEndChequeNumber,
								[SD].ParticipantId,
								CASE
									WHEN [SD].SortCode = ST.SortCode
									THEN 1
									ELSE 2
								END											AS StopStatus
							FROM
								[Base].[StopsDetail]	AS SD
							LEFT JOIN
								[Manual].LBGStopTypes	AS ST
							ON
								ST.SortCode = RIGHT('000000' + CONVERT(VARCHAR(6), [SD].SortCode), 6)
							WHERE
								[SD].[HeaderId] IS NULL
							AND StopType IN ( 'S',
												'M'
											)
							AND ISNUMERIC([StartChequeNumber]) = 1
							AND ISNUMERIC([EndChequeNumber]) = 1
							AND [SD].[EffectiveFrom] <= @BusinessDate
							AND [SD].[IsDeleted] = 0
						) AS BaseData;


					SELECT
						StartSortCode,
						StartAccountNumber,
						IntStartChequeNumber,
						EndSortCode,
						EndAccountNumber,
						IntEndChequeNumber,
						ParticipantId,
						StopStatus
					FROM
						#CTE
					ORDER BY
						StartSortCode,
						StartAccountNumber,
						IntStartChequeNumber
					OPTION (MAXRECURSION 0);
					BREAK;
				END TRY
				BEGIN CATCH
					IF (ERROR_NUMBER() = 1205)
						BEGIN
							SET @Tries = @Tries + 1;
							IF @Tries <= @TriesVal
								CONTINUE;
							ELSE
								THROW;
						END;
					ELSE
						SET @ErrorNumber = ERROR_NUMBER();
					SET @ErrorMessage = ERROR_MESSAGE();
					SET @Severity = ERROR_SEVERITY();
					SET @State = ERROR_STATE();
					SET @Line = ERROR_LINE();
					SET @Procedure = ERROR_PROCEDURE();
					EXEC [Base].[usp_SqlErrorLog]
						@ErrorNumber,
						@Severity,
						@State,
						@Procedure,
						@Line,
						@ErrorMessage;
					THROW;
				END CATCH;
			END;
	END;
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Component ',
	@value = N'iPSL.ReferenceDataDB',
	@level0type = N'SCHEMA',
	@level0name = N'RefOut',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetStopsSingleMultiToApg';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description ',
	@value = N'This Stored Procedure will fetch the records from [Base].StopsDetail table.',
	@level0type = N'SCHEMA',
	@level0name = N'RefOut',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetStopsSingleMultiToApg';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Version ',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'RefOut',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetStopsSingleMultiToApg';
GO
GRANT
	EXECUTE
ON OBJECT::[RefOut].[usp_GetStopsSingleMultiToApg]
TO
	[Reference_Lloyds_Access];
