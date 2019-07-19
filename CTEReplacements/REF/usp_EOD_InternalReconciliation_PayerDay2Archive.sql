CREATE PROCEDURE [Base].[usp_EOD_InternalReconciliation_PayerDay2Archive]
    (
        @ActivityID            VARCHAR(60),
        @ReconStage            VARCHAR(100),
        @BusinessDateEntity    VARCHAR(255),
        @BusinessDateAttribute VARCHAR(255),
        @UserName              VARCHAR(50),
        @Source                VARCHAR(100),
        @Result                INT           OUTPUT,
        @SysOut                VARCHAR(4000) OUTPUT
    )
/*****************************************************************************************************
* Name				: [Base].[usp_EOD_InternalReconciliation_PayerDay2Archive]
* Description		: Stored Procedure to get and check EOD details
This stored procedure is used to check for Payer Day 2 EOD reconciliation.It checks that everything sent as part of MSG07 has been archived,
MSG08 has been received and archived and everything received as part of 
MSG09,MSG11,MSG12 has been archived.Reconcilication logic driven by EODParams table.
Triggered by SSIS Generic package from ControlM.Returns success code(configured) if reconciliation is success else failure code.
* Type of Procedure : User-defined stored procedure
* Author			: Arushi Pabla
* Creation Date		: 14-Dec-2017
* Last Modified		: Rahul
* Last Modified	By	: NA
* Parameters		: 8
*******************************************************************************************************
*Parameter Name				Type							Description
*------------------------------------------------------------------------------------------------------
 @ActivityID				VARCHAR(60)						Activity Id for logging table
,@ReconStage				VARCHAR(100)					recon stage to get parameters from EODParams
,@BusinessDateEntity		VARCHAR(255)					Business Date entity to get value from config
,@BusinessDateAttribute		VARCHAR(255)					Business Date attribute to get value from config.
,@UserName					VARCHAR(50) 					User Name from the package
,@Source					VARCHAR(100) 					Package name
,@Result					INT								Output paramater considering result
 @SysOut					VARCHAR(511)					SysOut parameter
*******************************************************************************************************
*										History
*------------------------------------------------------------------------------------------------------
* Version	ID		Date			Reason
*******************************************************************************************************
* 1.0.0		001     09-May-2017   	Initial version
* 1.0.1		002     13-Aug-2018  	Corrected attribute name from PAYER_DAY2_IA to PAYER_DAY2
* 1.0.1		002		15-Jan-2019		Removed CHARINDEX from table columns to improve performance
*******************************************************************************************************/
AS
    DECLARE
        @BusinessDate           DATE,
        @Message                VARCHAR(500), 
        @Window                 VARCHAR(5),
        @RoleFlag               VARCHAR(25),
        @DownstreamComponent    VARCHAR(10),      
        @SourceDirtyFlag        INT = 0,
		@ItemNotArchived	    INT = 0,
        @DocNotAcknowledged    INT = 0,
        @DocumentsNotArchived   INT = 0,
        @Severity               INT,
        @ErrorCode              VARCHAR(10),
		@ReconItemCount			INT = 0

    BEGIN

        SET NOCOUNT ON;
        BEGIN TRY
            BEGIN TRANSACTION;
			DECLARE @DebitStateList varchar(100),
					@DebitDirtyFlag SMALLINT,
					@DebitStateList_1 varchar(100),
					@DebitDirtyFlag_1 SMALLINT
					
            SELECT
                @BusinessDate
                = CONVERT(DATE,[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue](@BusinessDateEntity,
                                                                                @BusinessDateAttribute
                                                                                     )
                         );

           SELECT 
                @Window                 = [Window],
                @RoleFlag               = [RoleFlag],
                @DownstreamComponent    = [DownstreamComponent],
                @SourceDirtyFlag        = [SourceDirtyFlag]
           FROM
                [$(MoConfigDatabase)].[Config].[tfn_EODParams](@ReconStage)
           WHERE
				ReconStage = @ReconStage;

			 SELECT 
				@DebitStateList			= [DebitStateList],
				@DebitDirtyFlag			= [DebitDirtyFlag]
           FROM
                [$(MoConfigDatabase)].[Config].[tfn_EODParams]('PAYER_DAY2')
			WHERE
					ReconStage = 'PAYER_DAY2';

			SELECT 
				@DebitStateList_1			= [DebitStateList],
				@DebitDirtyFlag_1			= [DebitDirtyFlag]
           FROM
                [$(MoConfigDatabase)].[Config].[tfn_EODParams]('PAYER_DAY2_1')
			WHERE
					ReconStage = 'PAYER_DAY2_1';

			CREATE TABLE #EODStates
			(
				DebitState SMALLINT
			)
			INSERT INTO #EODStates
			SELECT value FROM string_split(@DebitStateList,',') WHERE value != '';   

			CREATE TABLE #EODStates_1
			(
				DebitState SMALLINT
			)
			INSERT INTO #EODStates_1
			SELECT value FROM string_split(@DebitStateList_1,',') WHERE value != '';   

			--items in 570 with dirty flag != 30
			SELECT
				@ItemNotArchived = COUNT(1)
			FROM
				[Base].ItemState itmState
			WHERE
				Window2BusinessDate = @BusinessDate
			AND 
				PayerRoleFlag = 1
			AND 
				Gender = 1
			AND 
				EXISTS(SELECT 1 FROM #EODStates WHERE DebitState = PayerItemState)
			AND 
				PayerItemDirtyFlag != @DebitDirtyFlag
										
			IF @ItemNotArchived = 0
				BEGIN
					--documents for which 08SM01 hasnt come

					SELECT 
						SourceID
					INTO
						#SourceCTE
					FROM
						[Base].Source
					WHERE 
						MessageType = '07MS01'						
					AND 
						BusinessDate = @BusinessDate

					CREATE CLUSTERED INDEX ci_SourceId ON #SourceCTE(SourceID)
													
					SELECT 
						@DocNotAcknowledged = COUNT(1)
					FROM 
						#SourceCTE	 CTE
					LEFT OUTER JOIN 
						[Base].Source SRC
					ON
						CTE.SourceID = SRC.RelatedSourceID
					AND 
						SRC.MessageType = '08SM01'
					AND 
						SRC.BusinessDate = @BusinessDate
					WHERE 
						SRC.RelatedSourceID IS NULL
											
					--docs for which 08MA01 hasnt run
					IF @DocNotAcknowledged = 0
						BEGIN
							SELECT
								@DocumentsNotArchived = COUNT(1)
							FROM
								[Base].[Source]
							WHERE
								MessageType = '08SM01'
							AND 
								(
									SourceDirtyFlag IS NULL
								OR 
									SourceDirtyFlag != @SourceDirtyFlag
								)
							AND 
								BusinessDate = @BusinessDate
													
							IF @DocumentsNotArchived = 0
								BEGIN
									--WAR Scenario Archive (MSG09,MSG11,MSG12)
									SELECT
										@ReconItemCount = COUNT(1)
									FROM
										[Base].ItemState itmState
									WHERE
										Window2BusinessDate = @BusinessDate
									AND 
										PayerRoleFlag = 1
									AND 
										Gender = 1
									AND 
										EXISTS	(
													SELECT 
														1 
													FROM 
														#EODStates_1 
													WHERE 
														DebitState = PayerItemState
												)
									AND 
										PayerItemDirtyFlag != @DebitDirtyFlag_1
								END;
						END;
				END;
								
            IF (	@ItemNotArchived = 0
                   AND @DocNotAcknowledged = 0
				   AND @DocumentsNotArchived = 0
				   AND @ReconItemCount = 0
               )
                BEGIN
                    SET @Result = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'SuccessCode');
                    SET @ErrorCode = '';
                    SET @Message
                        = 'EOD- MO Internal ' + @DownstreamComponent + ' Reconciliation process for ' + @RoleFlag + ' '
                          + @Window + ' completed successfully.';
                    SET @Severity = 1;
                    SET @SysOut = ''	
				END				
			
            ELSE IF @ItemNotArchived > 0
                BEGIN
                    SET @ErrorCode = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', @ReconStage);
                    SET @Result = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'FailureCode');
                    SET @Severity = 3;
                    SET @Message
                        = '[MOException] EOD- MO Internal ' + @DownstreamComponent + ' Reconciliation process for '
                          + @RoleFlag + ' ' + @Window + ' failed.' + CAST(@ItemNotArchived AS VARCHAR(10))
                          + ' Item(s) sent to SWITCH(MSG07) have not been ARCHIVED.';
                    SET @SysOut = @ErrorCode + ':' + @Message;
                END;
			ELSE IF @DocNotAcknowledged > 0
                BEGIN
                    SET @ErrorCode = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', @ReconStage +'_ACK');
                    SET @Result = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'FailureCode');
                    SET @Severity = 3;
                    SET @Message
                        = '[MOException] EOD- MO Internal ' + @DownstreamComponent + ' Reconciliation process for '
                          + @RoleFlag + ' ' + @Window + ' failed.' + CAST(@DocNotAcknowledged AS VARCHAR(10))
                          + ' Documents(s) have not received acknowledgement from SWITCH.';
                    SET @SysOut = @ErrorCode + ':' + @Message;
                END;
			ELSE IF @DocumentsNotArchived > 0
                BEGIN
                    SET @ErrorCode = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', @ReconStage + '_ACKIA');
                    SET @Result = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'FailureCode');
                    SET @Severity = 3;
                    SET @Message
                        = '[MOException] EOD- MO Internal ' + @DownstreamComponent + ' Reconciliation process for '
                          + @RoleFlag + ' ' + @Window + ' failed.' + CAST(@DocumentsNotArchived AS VARCHAR(10))
                          + ' Documents(s) have not been sent to ARCHIVE.';
                    SET @SysOut = @ErrorCode + ':' + @Message;
                END;   
           ELSE IF @ReconItemCount > 0
                BEGIN
                    SET @ErrorCode = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', @ReconStage+'_WAR');
                    SET @Result = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'FailureCode');
                    SET @Severity = 3;
                    SET @Message
                        = '[MOException] EOD- MO Internal ' + @DownstreamComponent + ' Reconciliation process for '
                          + @RoleFlag + ' ' + @Window + ' failed.' + CAST(@ReconItemCount AS VARCHAR(10))
                          + ' Items(s) have not been sent to ARCHIVE for MSG09,MSG11,MSG12.';
                    SET @SysOut = @ErrorCode + ':' + @Message;
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
            --If transaction fails, roll back insert			
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
    @level1name = N'usp_EOD_InternalReconciliation_PayerDay2Archive';
GO

EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Caller : This stored procedure is being invoked from EOD SSIS Generic package triggered from ControlM.
			Description : Stored Procedure is used to check for Payer Day 2 EOD reconciliation.
			It checks that everything sent as part of MSG07 has been archived, MSG08 has been received and archived and everything received as part of 
			MSG09, MSG11, MSG12 has been archived. Reconcilication logic driven by EODParams table.',
    @level0type = N'SCHEMA',
    @level0name = N'Base',
    @level1type = N'PROCEDURE',
    @level1name = N'usp_EOD_InternalReconciliation_PayerDay2Archive';
GO

EXEC [sys].[sp_addextendedproperty]
    @name = N'Version',
    @value = [$(Version)],
    @level0type = N'SCHEMA',
    @level0name = N'Base',
    @level1type = N'PROCEDURE',
    @level1name = N'usp_EOD_InternalReconciliation_PayerDay2Archive';
GO


GRANT
    EXECUTE
    ON OBJECT::[Base].[usp_EOD_InternalReconciliation_PayerDay2Archive]
    TO
    [ControlMRole]
    AS [dbo];
GO

