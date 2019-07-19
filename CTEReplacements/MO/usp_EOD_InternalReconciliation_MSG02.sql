CREATE PROCEDURE [Base].[usp_EOD_InternalReconciliation_MSG02]
    (
        @ActivityID            VARCHAR(60),
        @ReconStage            VARCHAR(100),
        @BusinessDateEntity    VARCHAR(10),
        @BusinessDateAttribute VARCHAR(5),
        @UserName              VARCHAR(50),
        @Source                VARCHAR(100),
        @Result                INT           OUTPUT,
        @SysOut                VARCHAR(4000) OUTPUT
    )
/*****************************************************************************************************
* Name				: [Base].[usp_EOD_InternalReconciliation_MSG02]
* Description		: Stored Procedure to perform MSG02 internal recon. It checks if all the items sent as part of 01MS01 
have received MSG02 and are archived.
* Type of Procedure : User-defined stored procedure
* Author			: Arushi Pabla
* Creation Date		: 06-Nov-2017
* Last Modified		: N/A
* Parameters		: 8
*******************************************************************************************************
*Parameter Name				Type							Description
*------------------------------------------------------------------------------------------------------
 @ActivityID				VARCHAR(60)						Activity Id for logging table
,@ReconStage				VARCHAR(10)						Workflow to get parameters from EODParams
,@BusinessDateEntity		VARCHAR(10)						Business Date entity to get value from config
,@BusinessDateAttribute		VARCHAR(5)						Business Date attribute to get value from config.
,@UserName					VARCHAR(50) 					User Name from the package
,@Source					VARCHAR(100) 					Package name
,@Result					INT								Output paramater considering result
 @SysOut					VARCHAR(511)					SysOut parameter
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************
*										History
*------------------------------------------------------------------------------------------------------
* Version 					ID          Date                    Reason
*******************************************************************************************************
* 1.0.0						001         06-Nov-2017   			Initial version
* 1.0.1						002			15-Jan-2019				Removed CHARINDEX from table columns to improve performance
*******************************************************************************************************/
AS
    BEGIN
        SET NOCOUNT ON;
		DECLARE  
		@BusinessDate           DATE,		     
        @Window                 VARCHAR(5),
        @RoleFlag               VARCHAR(25),
        @DownstreamComponent    VARCHAR(10),      
        @Severity               INT,
        @ErrorCode              VARCHAR(10),
        @Message                VARCHAR(255),      
        @SourceDirtyFlag        INT,
        @SourceStateList        VARCHAR(100),
		@NotAcknowledgeCount	INT = 0,
		@NotArchiveCount		INT = 0

        BEGIN TRY
            BEGIN TRANSACTION;
            SELECT
                @BusinessDate
                = CONVERT(DATE,[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue](@BusinessDateEntity,@BusinessDateAttribute));
			SELECT  
				
                @Window                 = [Window],
                @RoleFlag               = [RoleFlag],
                @DownstreamComponent    = [DownstreamComponent],
				@SourceDirtyFlag		= [SourceDirtyFlag],
				@SourceStateList		= [SourceStateList]
            FROM
                [$(MoConfigDatabase)].[Config].[tfn_EODParams](@ReconStage)

			
			CREATE TABLE #EODStates
			(
				DocumentState SMALLINT
			)
			INSERT INTO #EODStates
			SELECT value FROM string_split(@SourceStateList,',') WHERE value != '';

                -- Get the count of 01MS01 records for 02SM01 is not received

				SELECT 
					SourceID
				INTO
					#SourceCTE
				FROM
				   [Base].Source
				WHERE 
				   MessageType = '01MS01'
				AND 
					BusinessDate = @BusinessDate

				CREATE CLUSTERED INDEX ci_SourceID ON #SourceCTE(SourceID)

				SELECT 
					@NotAcknowledgeCount = COUNT(1)
				FROM 
					#SourceCTE	 CTE
				LEFT OUTER JOIN 
					[Base].Source SRC
				ON
				    CTE.SourceID = SRC.RelatedSourceID
				AND 
					SRC.MessageType = '02SM01'
				AND 
					SRC.BusinessDate = @BusinessDate
				WHERE 
				    SRC.RelatedSourceID IS NULL


				--Get the count of MSG02 recrds which are not archived
				IF (@NotAcknowledgeCount = 0)
				BEGIN
					SELECT 
						@NotArchiveCount = Count(1)
					FROM 
						[Base].[Source]
					WHERE
						MessageType = '02SM01'
					AND 
						EXISTS (SELECT 1 FROM #EODStates es WHERE DocumentState = SourceState)
					AND 
						SourceDirtyFlag != @SourceDirtyFlag
					AND 
						BusinessDate = @BusinessDate
				END
			        
            IF (@NotAcknowledgeCount = 0 AND @NotArchiveCount = 0)
                BEGIN
                    SET @Result = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'SuccessCode');
                    SET @ErrorCode = '';
                    SET @Message
                        = 'EOD- MO Internal ' + @DownstreamComponent + ' Reconciliation process for ' + @RoleFlag + ' '
                          + @Window + ' Result: SUCCESS.';
                    SET @SysOut = '';
                    SET @Severity = 1;
                END;
            ELSE IF @NotAcknowledgeCount > 0
                BEGIN
                    SET @ErrorCode = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', @ReconStage);
                    SET @Result = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'FailureCode');
                    SET @Severity = 3;
                    SET @Message
                        = '[MOException] EOD- MO Internal ' + @DownstreamComponent + ' Reconciliation process for '
                          + @RoleFlag + ' ' + @Window + ' failed.' + CAST(@NotAcknowledgeCount AS VARCHAR(10))
                          + ' Document(s) have not received acknowledgement from SWITCH.';
                    SET @SysOut = ISNULL(@ErrorCode,'') + ':' + @Message;
                END;
			ELSE
				 BEGIN
                    SET @ErrorCode = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', @ReconStage+'_IA');
                    SET @Result = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'FailureCode');
                    SET @Severity = 3;
                    SET @Message
                        = '[MOException] EOD- MO Internal ' + @DownstreamComponent + ' Reconciliation process for '
                          + @RoleFlag + ' ' + @Window + ' failed.' + CAST(@NotArchiveCount AS VARCHAR(10))
                          + ' Document(s) have not been sent to ' + @DownstreamComponent + '.';
                    SET @SysOut = ISNULL(@ErrorCode,'') + ':' + @Message;
                 END;

            EXEC [Logging].usp_LogAndAudit
                @ActivityID,
                @UserName,
                @ErrorCode,
                @Severity,
                @Source,
                @Message,
                NULL;

            COMMIT;
        END TRY
        BEGIN CATCH
            DECLARE @ErrorMessage NVARCHAR(4000);
            DECLARE @ErrorSeverity INT;
            DECLARE @ErrorState INT;
            DECLARE @ErrorLine INT;
            SELECT
                @ErrorSeverity = ERROR_SEVERITY(),
                @ErrorState    = ERROR_STATE(),
                @ErrorLine     = ERROR_LINE(),
                @ErrorMessage  = ERROR_MESSAGE();
            SET @Result = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'FailureCode');

            SET @SysOut = CAST(@ErrorMessage AS VARCHAR);           
            IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION;
            EXEC [Logging].usp_LogError NULL, @ActivityID;
            RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine);
        END CATCH;
        SET NOCOUNT OFF;
    END;
GO

EXEC [sys].[sp_addextendedproperty]
    @name = N'Component',
    @value = N'iPSL.ICS.MO.DB',
    @level0type = N'SCHEMA',
    @level0name = N'Base',
    @level1type = N'PROCEDURE',
    @level1name = N'usp_EOD_InternalReconciliation_MSG02';
GO

EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Caller : This stored procedure is being invoked from EOD SSIS Generic package triggered from ControlM.
			Description : Stored Procedure to perform MSG02 internal recon. 
			It checks if all the items sent as part of 01MS01 have received in MSG02 and are archived.',
    @level0type = N'SCHEMA',
    @level0name = N'Base',
    @level1type = N'PROCEDURE',
    @level1name = N'usp_EOD_InternalReconciliation_MSG02';
GO

EXEC [sys].[sp_addextendedproperty]
    @name = N'Version',
    @value = [$(Version)],
    @level0type = N'SCHEMA',
    @level0name = N'Base',
    @level1type = N'PROCEDURE',
    @level1name = N'usp_EOD_InternalReconciliation_MSG02';
GO

GRANT
    EXECUTE
    ON OBJECT::[Base].[usp_EOD_InternalReconciliation_MSG02]
    TO
    [ControlMRole]
    AS [dbo];
GO

