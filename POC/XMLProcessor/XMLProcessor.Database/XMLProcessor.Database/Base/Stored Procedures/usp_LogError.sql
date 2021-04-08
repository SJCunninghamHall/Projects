CREATE PROCEDURE [Base].[usp_LogError]
    @ErrorMessage VARCHAR(4000) = NULL,
	@ErrorSeverity INT = NULL 
/*****************************************************************************************************
* Name				: [Base].[usp_LogError]
* Description		: This stored procedure will be called when any exceptions or errors occur while 
					  loading the messages into the STAR DB
* Type of Procedure : Interpreted stored procedure
* Author			: Pavan Kumar Manneru
* Creation Date		: 04/07/2016
* Last Modified		: N/A
* Parameters		:
*******************************************************************************************************
*Parameter Name				Type				Description
*------------------------------------------------------------------------------------------------------
@ErrorMessage				VARCHAR				ErrorMessage
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************
*										History
*------------------------------------------------------------------------------------------------------
* Version 					ID          Date                    Reason
*******************************************************************************************************
* 1.0.0						001         04/07/2016   			Initial version
* 1.0.1						002			20/06/2017				Additionally log to Windows Event Log
*******************************************************************************************************/
AS
    BEGIN
        SET NOCOUNT ON;

        BEGIN TRY
        -- Return if there is no error information to log.
		DECLARE @ErrorLogID TINYINT,
				@ErrorNumber INT,
				@ErrorState INT,
				@ErrorProcedure NVARCHAR(128),
				@ErrorLine INT,
				@SmallMessage VARCHAR(2000)
		
            IF @ErrorMessage IS  NULL
                SET @ErrorMessage = ERROR_MESSAGE();
            IF ERROR_NUMBER() IS NULL
                AND @ErrorMessage IS NULL
                RETURN;

			IF XACT_STATE() = -1
            BEGIN
                PRINT 'Cannot log error since the current transaction is in an un-committable state. '
                    + 'Rollback the transaction before executing usp_LogError in order to successfully log error information.';
                RETURN;
            END;
			
			SELECT @ErrorLogID = NEXT VALUE FOR [Base].[sqn_ErrLog]
			SET @ErrorNumber = ERROR_NUMBER()
			IF(@ErrorSeverity IS NULL)
			BEGIN
				SET @ErrorSeverity = ERROR_SEVERITY()
			END
			
			SET @ErrorState = ERROR_STATE()
			SET @ErrorProcedure = ERROR_PROCEDURE()
			SET @ErrorLine = ERROR_LINE()
			SET @SmallMessage = LEFT(@ErrorMessage,2000)

			--Call Natively compiled stored procedure to insert the Error details into the ErrorLog table
			EXECUTE [Base].[csp_LogError] @ErrorMessage,
											 @ErrorLogID,
											 @ErrorNumber,
											 @ErrorSeverity,
											 @ErrorState,
											 @ErrorProcedure,
											 @ErrorLine 
											 
			-- In addition, write the error to Windows event log using the "FRED" developed generic routine.
			-- Commented out until security has been confirmed for this procedure
			EXECUTE  [Base].[usp_LogEventEntry] 
					 @ErrorID			= @ErrorLogID
					,@ErrorCode			= @ErrorNumber
					,@ErrorSource		= @ErrorProcedure
					,@ErrorSeverity		= @ErrorSeverity
					,@ErrorMessage		= @SmallMessage
					,@EventErrorNumber	= 80000 -- Hard coded for ARC StarDB	
																                  
        END TRY
        BEGIN CATCH
            PRINT 'An error occurred in stored procedure usp_LogError: ';
            RETURN -1;
        END CATCH;
    END;
GO
/*
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_LogError';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This stored procedure will be called when any exceptions or errors occur while loading the messages into the STAR DB', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_LogError';


GO
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'STAR', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_LogError';

*/