/*****************************************************************************************************
* Name              : [usp_GetSourceInternal]
* Description  	    : This Stored Procedure will fetch the records from SourceInternal table.
* Author			: Shiju				   
*******************************************************************************************************
*Parameter Name				Type							   Description
*------------------------------------------------------------------------------------------------------
 
*******************************************************************************************************************************
* Amendment History
*------------------------------------------------------------------------------------------------------------------------------
* ID          Date             User					Reason
*****************************************************************************************************
* 001			03/08/2017 		Shiju			Initial version
* 002			11/09/2017		Champika B		Version variable added 
* 003			29/06/2018		Abhishek		Added account number and representmentcode
* 004			09/10/2018		Champika B		Adding IsInternal logic
******************************************************************************************************/
CREATE PROCEDURE [Base].[usp_GetSourceInternal]
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

		WHILE @Tries <= 5
			BEGIN TRY

				SELECT
					InternalDepartmentID
				INTO
					#CTE
				FROM
					[Base].[SourceInternal]
				WHERE
					InternalDepartmentID IN
						(
							SELECT
								InternalDepartmentID
							FROM
								[Base].[SourceInternal]
							WHERE
								RecordID = 'D'
							GROUP BY
								InternalDepartmentID
							HAVING
								COUNT(1) = 1
						)
				AND NULLIF(DepartmentSortCode, 'NULL') IS NULL;

				CREATE NONCLUSTERED INDEX nci_InternalDepartmentID
				ON #CTE (InternalDepartmentID);

				SELECT
					ROW_NUMBER	() OVER (ORDER BY
										ID
									)		AS RowNumber,
					ID,
					ParticipantID	,
					RecordID,
					ReferenceNumber,
					CreationDate,
					CatalogueID,
					RecordCount,
					A.InternalDepartmentID,
					DepartmentCategoryType,
					DepartmentName,
					A.DepartmentSortCode,
					DepartmentSettlementSortCode,
					DepartmentSettlementAccount,
					HOCASortCode,
					HOCAAccountNumber,
					HOCAEffectiveDate,
					BusinessLineOwner,
					CreditExtractType,
					HOCASettlementSortCode,
					HOCASettlementAccount,
					CreatedDate,
					LastUpdatedDate,
					ModifiedDate,
					ModifiedBy,
					[AccountNumber],
					[RepresentmentCode],
					CASE
						WHEN B.InternalDepartmentID IS NOT NULL
						THEN 1
						WHEN NULLIF(DepartmentSortCode, 'NULL') IS NOT NULL
						THEN 1
						ELSE 0
					END							AS IsInternal
				FROM
					[Base].[SourceInternal] AS A
				LEFT OUTER JOIN
					#CTE					AS B
				ON
					A.InternalDepartmentID = B.InternalDepartmentID
				WHERE
					RecordID = 'D';

				BREAK;

			END TRY
			BEGIN CATCH
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
				IF (ERROR_NUMBER() = 1205)
					BEGIN
						SET @Tries = @Tries + 1;
						IF @Tries <= 5
							CONTINUE;
						ELSE
							THROW;
					END;
				ELSE
					THROW;
			END CATCH;
	END;
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'iPSL.ReferenceDataDB',
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetSourceInternal';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Insert log details',
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetSourceInternal';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetSourceInternal';
GO
GRANT
	EXECUTE
ON OBJECT::[Base].[usp_GetSourceInternal]
TO
	[Reference_db_Access];


