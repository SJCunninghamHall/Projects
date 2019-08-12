CREATE PROCEDURE [Base].[usp_LogEventEntry]
     @ErrorID BIGINT               -- Error ID/ID from the error or exception log tabble.
	,@ErrorCode VARCHAR(10)		   -- Error code logged to the table
	,@ErrorSource NVARCHAR(200)    -- Source of the error. name of the DLL or procedure 
	,@ErrorSeverity INT            -- severity, 1-10 warning and rest as Error
    ,@ErrorMessage VARCHAR(2000)   -- Error message
	,@EventErrorNumber INT         -- Should be greater than 50000, this will uniquely identify which application made event log entry.
	
   WITH EXECUTE AS OWNER
	
/****** Object:  StoredProcedure [Base].[usp_LogEventEntry]    Script Date: 15/06/2017 ******/
-- =============================================
-- Author:		Sharad Kumar
-- Create Date: 16/06/2016
-- Description:	Generic Error Logging Routine an entry to the event log whenever an entry is made to the exception log or error log table
--*********************************************************************************************************
--* Amendment History
--*--------------------------------------------------------------------------------------------------------
--* Version 				UserID          Date                    Reason
--*********************************************************************************************************
--* 1.0.0					Sharad			16/06/2017				Initial Version
--* 1.0.1					WaightRy		20/06/2017				Input param @ErrorCode change to v(10) from INT for ARC purposes
--* 1.0.2					WaightRy		23/06/2017				Added "WITH RESULT SETS NONE" to xp_LogEvent as advised by "FRED"
--* 1.0.3					WaightRy		05/10/2017				Added "Informational" as advised by "MO"
-- =============================================
-- =============================================
AS
BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON; 
		BEGIN TRY
			DECLARE @Severity          VARCHAR(15) 
			DECLARE @EventErrorMessage VARCHAR(2048) 

            IF ( @ErrorSeverity < 5 )
                SET @Severity = 'Informational';
            ELSE
                IF ( @ErrorSeverity >= 5
                     AND @ErrorSeverity < 11
                   )
                    SET @Severity = 'warning';
                ELSE
                    SET @Severity = 'error';

			SET @EventErrorMessage = Concat(CHAR(13),'Error ID     : ',@ErrorID,
										CHAR(13), 'Error Code   : ',@ErrorCode,
										CHAR(13), 'Application Error Severity : ',@ErrorSeverity,
										CHAR(13), 'Error Source : ', @ErrorSource,
										CHAR(13), 'Error Message: ', @ErrorMessage)

			EXECUTE xp_logevent @EventErrorNumber,@EventErrorMessage,@Severity WITH RESULT SETS NONE

		END TRY
		BEGIN CATCH
			throw;
		END CATCH
END
GO
/*
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_LogEventEntry';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This stored procedure will be called when any exceptions or errors occur while loading the messages into the STAR DB', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_LogEventEntry';


GO
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'STAR', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_LogEventEntry';
*/
