/*****************************************************************************************************
* Name              : [usp_GetAgencySortCodeAndAccounts]
* Description  	    : This Stored Procedure will fetch the records from [Manual].[AgencySortCode] table with SortCode and Account Number.
* Author			: Bhaskar Reddy			   
*******************************************************************************************************
*Parameter Name				Type							   Description
*------------------------------------------------------------------------------------------------------

*******************************************************************************************************************************
* Amendment History
*------------------------------------------------------------------------------------------------------------------------------
* ID            Date             User					Reason
*****************************************************************************************************
* 001           17/07/2017 		Bhasakr Reddy			Initial version
* 002			21/07/2017		Shiju					Added ExpiryDate Condition
* 003			24/07/2017		Divya Singh				Code Review Action remove unused Parameter 
* 004			27/07/2017		Champika B				Code Review Action Deadlock Proof Changes
* 005			01/08/2017		Champika B				SQL code alignment 
* 006			02/08/2017		Shiju					Added AccountNumber as new column  Replaced StartAccountNumber and EndAccountNumber
* 007			04/09/2017		Champika B				Code Review Action remove version number
* 008			15/09/2017		Champika B				Number of Deadlock  retry value to config table
* 009			13/02/2018		Champika B				Temporal logic and @Environment added
* 010			27/02/2018		Champika B				Get @Environment from ConfigSettings
* 011			08 Jan 2019		Sabarish Jayaraman		included Workflowtype in the output 
******************************************************************************************************/
CREATE PROCEDURE [RefOut].[usp_GetAgencySortCodeAndAccounts]
	@Date	DATETIME	= NULL
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
		SET @TriesVal =
			(
				SELECT
					[VALUE]
				FROM
					base.ConfigSettings
				WHERE
					[Name]	= 'DeadLockRetry'
			);
		SET @Date = ISNULL(@Date, CAST(GETDATE() AS DATE));
		SET @Date += ' 23:59:59';

		DECLARE @Environment SMALLINT	=
					(
						SELECT
							[Value]
						FROM
							[Base].[ConfigSettings]
						WHERE
							[NAME]	= 'DefaultEnvironmentSetting'
					);

		WHILE @Tries <= @TriesVal
			BEGIN
				BEGIN TRY

					SELECT
						SortCode,
						[BaseData].[StartAccountNumber],
						[BaseData].[EndAccountNumber],
						AgencyId,
						[Workflow]
					INTO
						#CTE
					FROM
						(
							SELECT
								[SD].[SortCode],
								CAST(AccountNumber AS BIGINT) AS StartAccountNumber,
								CAST(AccountNumber AS BIGINT) AS EndAccountNumber,
								AgencyId,
								[Workflow]
							FROM
								Manual.AgencySortCode
								FOR SYSTEM_TIME AS OF @Date AS SD
							WHERE
								SD.Environment = @Environment
						) AS BaseData
					UNION ALL
					SELECT
						[SortCode]	,
						StartAccountNumber + 1,
						EndAccountNumber,
						AgencyId,
						[Workflow]
					FROM
						#CTE
					WHERE
						EndAccountNumber > StartAccountNumber;

					SELECT
						[SortCode]	,
						StartAccountNumber	AS Account,
						AgencyId,
						[Workflow]
					FROM
						#CTE
					GROUP BY
						[SortCode],
						StartAccountNumber,
						AgencyId,
						[Workflow]
					ORDER BY
						[SortCode],
						StartAccountNumber,
						AgencyId,
						[Workflow]
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
	@name = N'Component',
	@value = N'iPSL.ReferenceDataDB',
	@level0type = N'SCHEMA',
	@level0name = N'RefOut',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetAgencySortCodeAndAccounts';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This Stored Procedure will fetch the records from [Manual].[AgencySortCode] table with SortCode and Account Number',
	@level0type = N'SCHEMA',
	@level0name = N'RefOut',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetAgencySortCodeAndAccounts';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'RefOut',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetAgencySortCodeAndAccounts';
GO
GRANT
	EXECUTE
ON OBJECT::[RefOut].[usp_GetAgencySortCodeAndAccounts]
TO
	[Reference_Lloyds_Access];
GO
GRANT
	EXECUTE
ON OBJECT::[RefOut].[usp_GetAgencySortCodeAndAccounts]
TO
	[Reference_HSBC_Access];