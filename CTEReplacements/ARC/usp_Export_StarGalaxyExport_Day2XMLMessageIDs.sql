CREATE PROCEDURE [StarGalaxyExport].[usp_Export_StarGalaxyExport_Day2XMLMessageIDs]
	(
		@LongTermArchiveMigrationDateRangeStart BIGINT,
		@LongTermArchiveMigrationDateRangeEnd	BIGINT,
		@LongTermArchiveMigrationDay2RangeStart BIGINT OUTPUT,
		@LongTermArchiveMigrationDay2RangeEnd	BIGINT	OUTPUT
	)

/*****************************************************************************************************
* Name				: [StarGalaxyExport].[usp_Export_StarGalaxyExport_Day2XMLMessageIDs]
* Description		: This Stored Procedure finds the list of XMLMessage IDs for the entities 
						whose day2 data is not archived. It will load the eligible MessageIDs
						into ImportDay2XMLMessageIds table
* Type of Procedure : Stored procedure
* Author			: Sabarish Jayaraman
* Creation Date		: 28/03/2018
* Last Modified		: N/A
*******************************************************************************************************/
AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE
			@ProcedureName	sysname,
			@ErrorMessage	VARCHAR(4000),
			@Day2Date		BIGINT;

		SELECT
			@ProcedureName	= OBJECT_NAME(@@PROCID),
			@ErrorMessage	= NULL;

		BEGIN TRY

			DELETE	FROM
			[StarGalaxyExport].[ExportDay2XMLMessageIds];

			-- Find next business date
			SET @Day2Date =
				(
					SELECT	TOP 1
							LEFT(X.Id, 8) AS Day2ItemDate
					FROM
							Base.Entity		AS E
					RIGHT JOIN
							Base.Core		AS C
					ON
						E.CoreId = C.CoreId
					INNER JOIN
							Base.XMLMessage AS X
					ON
						X.Id = C.XMLMessageId
					WHERE
							(
								EntityIdentifier IN
									(
										SELECT
												E.EntityIdentifier
										FROM
												Base.Core	AS C
										INNER JOIN
												Base.Entity AS E
										ON
											C.CoreId = E.CoreId
										WHERE
												C.CoreId
									BETWEEN		@LongTermArchiveMigrationDateRangeStart AND @LongTermArchiveMigrationDateRangeEnd
									)
						AND		LEFT(X.Id, 8) > LEFT(@LongTermArchiveMigrationDateRangeEnd, 8)
							)
					ORDER BY
						LEFT(X.Id, 8)
				);

			SET @Day2Date = ISNULL(@Day2Date, 0);

			SET @LongTermArchiveMigrationDay2RangeStart = @Day2Date * 100000000000;
			SET @LongTermArchiveMigrationDay2RangeEnd = @LongTermArchiveMigrationDay2RangeStart + 99999999999;

			-- Select all entities matching the given date range
			SELECT
				E.EntityIdentifier
			INTO
				#Day1Entities
			FROM
				Base.Core	AS C
			INNER JOIN
				Base.Entity AS E
			ON
				C.CoreId = E.CoreId
			WHERE
				C.CoreId
		BETWEEN @LongTermArchiveMigrationDateRangeStart AND @LongTermArchiveMigrationDateRangeEnd;

			CREATE CLUSTERED INDEX ci_EntityIdentifier
			ON #Day1Entities (EntityIdentifier);

			-- Select the Entities which are having entries with state greater than 200 eligible for Day2 Logic
			-- Insert into ExportDay2XMLMessageIds table
			INSERT INTO
				[StarGalaxyExport].[ExportDay2XMLMessageIds]
				(
					XmlId
				)
			SELECT	DISTINCT
					X.Id	AS [Xml ID]
			FROM
					Base.Entity		AS E
			RIGHT JOIN
					Base.Core		AS C
			ON
				E.CoreId = C.CoreId
			INNER JOIN
					Base.XMLMessage AS X
			ON
				X.Id = C.XMLMessageId
			WHERE
					(
						EntityIdentifier IN
							(
								SELECT	DISTINCT
										EntityIdentifier
								FROM
										#Day1Entities
							)
				OR		C.IntMessageType = 'PTMA01'
				OR
					(
						EntityType <> 'I'
				AND		C.IntMessageType = '07MA01'
					)
				OR
					(
						EntityType <> 'I'
				AND		C.IntMessageType = '08MA01'
					)
					)
			AND LEFT(C.CoreId, 8) = @Day2Date
			AND
			(
					E.EntityState IS NULL
			OR		E.EntityState > 200
				);
		END TRY
		BEGIN CATCH

			IF @ErrorMessage IS NULL
				BEGIN
					SET @ErrorMessage = 'Error!! Stored Procedure ' + @@SERVERNAME + '.' + DB_NAME() + '.' + @ProcedureName + ' Returned the following error :- ' + CAST(ERROR_MESSAGE() AS VARCHAR(1000)) + ' Line Number :- ' + CAST(ERROR_LINE() AS VARCHAR(1000));
				END;

			EXECUTE [Base].[usp_LogAndRaiseError]
				@ErrorMessage;

			; THROW 50000, @ErrorMessage, 1;

			RETURN (-1);

		END CATCH;


	END;
GO

GRANT
	EXECUTE
ON [StarGalaxyExport].[usp_Export_StarGalaxyExport_Day2XMLMessageIDs]
TO
	StarGalaxyExporter;
GO
