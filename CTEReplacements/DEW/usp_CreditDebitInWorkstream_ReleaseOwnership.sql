CREATE PROCEDURE [DataAccess].[usp_CreditDebitInWorkstream_ReleaseOwnership]
	@UserName	VARCHAR(30)
AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @ErrorMessage VARCHAR(4000);
		DECLARE @UserId AS SMALLINT;
		DECLARE @End AS TINYINT;
		DECLARE @DebitInWorkStreamAudit AS [Process].[tv_06MD_DebitInWorkstreamAudit];

		BEGIN TRY

			SELECT
				@UserId = [UserSeq]
			FROM
				[DataAccess].[User]
			WHERE
				[UserName]	= @UserName;

			SELECT
				@End	= [WorkstreamStateSeq]
			FROM
				[CFG].[WorkstreamState]
			WHERE
				[Name]	= 'End';

			INSERT INTO
				@DebitInWorkStreamAudit
				(
					[DebitInWorkstreamAuditSeq],
					[DebitInWorkstreamSeq],
					[StateSeq], 
					[UserSeq],
					[DateTime]
				)
			SELECT
				CAST(ROUND([DebitInWorkstreamSeq] / 100000000000, 0) * 100000000000 AS BIGINT) + CAST(NEXT VALUE FOR [Process].[sqn_DebitInWorkstreamAudit] AS BIGINT),
				[DebitInWorkstreamSeq],
				[StateSeq],
				NULL,
				GETDATE()
			FROM
				[Process].[DebitInWorkstream]
			WHERE
				[StateSeq]	<> @End
			AND [GroupSeq] IS NOT NULL
			AND [UserSeq] = @UserId
			AND [UserDecisionSeq] IS NULL
			AND
			(
					[UserSuspended] IS NULL
			OR		[UserSuspended] = 0
				);

			--Find the DebitInWorkstreamSeq which are eligible for ReleaseOwnership

			SELECT
				[DebitInWorkstreamSeq]
			INTO
				#ReleaseOwnershiprecord
			FROM
				[Process].[DebitInWorkstream]
			WHERE
				[StateSeq]	<> @End
			AND [GroupSeq] IS NOT NULL
			AND [UserSeq] = @UserId
			AND [UserDecisionSeq] IS NULL
			AND
			(
					[UserSuspended] IS NULL
			OR		[UserSuspended] = 0
				);

			CREATE CLUSTERED INDEX ci_DebitInWorkstreamSeq
			ON #ReleaseOwnershiprecord (DebitInWorkstreamSeq);

			UPDATE
				[Process].[DebitInWorkstream]
			SET
			[GroupSeq]	= NULL,
				[UserSeq] = NULL
			FROM
				[Process].[DebitInWorkstream]	AS [DIW]
			INNER JOIN
				#ReleaseOwnershiprecord			AS [RO]
			ON
				[RO].[DebitInWorkstreamSeq] = [DIW].[DebitInWorkstreamSeq];

			--Capture the Audit log
			EXEC [Process].[usp_06MD_Insert_DebitInWorkstreamAudit]
				@DebitInWorkStreamAudit;

		END TRY
		BEGIN CATCH

			-- Log the error information
			DECLARE @ErrorMessageLog VARCHAR(4000) = ERROR_MESSAGE();
			EXECUTE [Base].[usp_LogException]
				@ErrorMessageLog;
			THROW;
		END CATCH;
	END;

GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'DataAccess',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_CreditDebitInWorkstream_ReleaseOwnership';
GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'
Description		:	This Procedure will Release the ownership of a particular user in [Process].[DebitInWorkstream] and update groupid and UserId to null. 
					Release ownership of the Item on : Not decisioned, Not Suspended, Not Reached End and is the currently assigned to the User 
Parameter Name							  Type					Description
@UserName                                VARCHAR(30)            User name  
',
	@level0type = N'SCHEMA',
	@level0name = N'DataAccess',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_CreditDebitInWorkstream_ReleaseOwnership';




GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'iPSL.iCE.DEW.Database',
	@level0type = N'SCHEMA',
	@level0name = N'DataAccess',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_CreditDebitInWorkstream_ReleaseOwnership';
GO
GRANT
	EXECUTE
ON OBJECT::[DataAccess].[usp_CreditDebitInWorkstream_ReleaseOwnership]
TO
	[WebAccess]
AS [dbo];
GO