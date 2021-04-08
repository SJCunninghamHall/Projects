CREATE PROCEDURE [RNEReport].[usp_getMSG07DebitsWithDocumentsHistory]
	@BusinessDateRangeStart BIGINT,
	@BusinessDateRangeEnd	BIGINT

/*****************************************************************************************************
* Name				: [RNEReport].[usp_getMSG07DebitsWithDocumentsHistory]
* Description		: This stored procedure exports the data for Debits and corresponding Documents	history from STAR to RnEReportDataWarehouse.
* Type of Procedure : Natively compiled stored procedure
* Author			: Nageswara Rao 
* Creation Date		: 29/12/2017
* Last Modified		: N/A
*******************************************************************************************************/

AS
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

	BEGIN

		SELECT
			EntityId,
			EntityIdentifier,
			EntityState
		INTO
			#MSG08EntityStates
		FROM
			(
				SELECT
					E.EntityId,
					E.EntityIdentifier,
					E.EntityState,
					ROW_NUMBER() OVER (PARTITION BY
										E.EntityIdentifier
										ORDER BY
										E.Revision DESC
									) AS RKD
				FROM
					Base.Entity AS E
				JOIN
					Base.Core	AS C
				ON
					C.CoreId = E.CoreId
				WHERE
					C.IntMessageType = '08MA01'
				AND E.EntityType = 'D'
				AND C.CoreId
				BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd
			) AS A;

		CREATE NONCLUSTERED INDEX nci_EntityIdentifier
		ON #MSG08EntityStates (EntityIdentifier);

		SELECT
			EntityId,
			EntityIdentifier,
			EntityState
		INTO
			#MSG09EntityStates
		FROM
			(
				SELECT
					E.EntityId,
					E.EntityIdentifier,
					E.EntityState,
					ROW_NUMBER() OVER (PARTITION BY
										E.EntityIdentifier
										ORDER BY
										E.Revision DESC
									) AS RKD
				FROM
					Base.Entity AS E
				JOIN
					Base.Core	AS C
				ON
					C.CoreId = E.CoreId
				WHERE
					C.IntMessageType = '09MA01'
				AND E.EntityType = 'I'
				AND C.CoreId
				BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd
			) AS A
		WHERE
			[A].[RKD] = 1;

		CREATE NONCLUSTERED INDEX nci_EntityIdentifier
		ON #MSG09EntityStates (EntityIdentifier);

		SELECT
			EntityId,
			EntityIdentifier,
			EntityState
		INTO
			#RepairEntityStates
		FROM
			(
				SELECT
					E.EntityId,
					E.EntityIdentifier,
					E.EntityState,
					ROW_NUMBER() OVER (PARTITION BY
										E.EntityIdentifier
										ORDER BY
										E.Revision DESC
									) AS RKD
				FROM
					Base.Entity AS E
				JOIN
					Base.Core	AS C
				ON
					C.CoreId = E.CoreId
				WHERE
					C.IntMessageType = '09MA02'
				AND E.EntityType = 'I'
				AND C.CoreId
				BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd
			) AS A
		WHERE
			[A].[RKD] = 1;

		CREATE NONCLUSTERED INDEX nci_EntityIdentifier
		ON #RepairEntityStates (EntityIdentifier);

		-- Do we need this final temp table population just to select from afterwards - would this select suffice on its own?
		SELECT
			Debits	.DocumentId							AS MSG07DocumentId,
			Doc.DocumentMessageId,
			Doc.CreatedDate,
			Doc.NumberOfEntries,
			Debits.DebitId								AS MSG07DebitId,
			MSG08E.EntityState							AS MSG08EntityState,
			MSG09E.EntityState							AS MSG09EntityState,
			MSG092E.EntityState							AS RepairES,
			CONVERT(VARCHAR(100), RCode.ReasonCodes)	AS ReasonCode,
			MSG09Error.ErrorCode,
			NULL										AS MSG02EntityState,
			NULL										AS MSG03EntityState,
			NULL										AS MSG03ErrorCode,
			NULL										AS MSG01
		INTO
			#FinalDocsCTE
		FROM
			Base.vw_Document	AS Doc
		INNER JOIN
			(
				SELECT
					DB	.DebitId,
					DB.DocumentId
				FROM
					Base.Debit AS DB
				WHERE
					ItemId
				BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd
				AND DocumentId IS NOT NULL
			)					AS Debits
		ON
			Debits.DocumentId = Doc.DocumentId
		LEFT JOIN
			Base.vw_Core		AS C
		ON
			Doc.XMLMessageId = C.XMLMessageId
		LEFT JOIN
			#MSG08EntityStates	AS MSG08E
		ON
			Doc.DocumentMessageId = MSG08E.EntityIdentifier
		LEFT JOIN
			#MSG09EntityStates	AS MSG09E
		ON
			Debits.DebitId = MSG09E.EntityIdentifier
		LEFT JOIN
			#RepairEntityStates AS MSG092E
		ON
			Debits.DebitId = MSG092E.EntityIdentifier
		LEFT JOIN
			##Temp_DocReasons	AS RCode
		ON
			Doc.DocumentMessageId = RCode.DocumentMessageId
		LEFT JOIN
			Base.EntityError	AS MSG09Error
		ON
			MSG09E.EntityId = MSG09Error.EntityId
		WHERE
			Doc.DocumentId
	BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd;


		SELECT
			MSG07DocumentId			AS DocumentId,
			DocumentMessageId,
			CreatedDate,
			NumberOfEntries,
			MSG07DebitId			AS DebitId,
			'MSG07'					AS MessageType,
			MSG08EntityState		AS MSG08,
			MSG09EntityState		AS MSG09,
			RepairES,
			[F].[ReasonCode],
			ErrorCode				AS MSG09ErrCode,
			[F].[MSG02EntityState]	AS MSG02,
			[F].[MSG03EntityState]	AS MSG03,
			[F].[MSG03ErrorCode]
		FROM
			#FinalDocsCTE AS F;

	END;

GO

GRANT
	EXECUTE
ON [RNEReport].[usp_getMSG07DebitsWithDocumentsHistory]
TO
	[RNEReportAccess];

GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'RNEReport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_getMSG07DebitsWithDocumentsHistory';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This stored procedure exports the data for Debits and corresponding Documents history from STAR to RnEReportDataWarehouse.',
	@level0type = N'SCHEMA',
	@level0name = N'RNEReport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_getMSG07DebitsWithDocumentsHistory';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'STAR',
	@level0type = N'SCHEMA',
	@level0name = N'RNEReport',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_getMSG07DebitsWithDocumentsHistory';
GO