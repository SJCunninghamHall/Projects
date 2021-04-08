CREATE PROCEDURE [Base].[csp_LogError]
	@ErrorMessage VARCHAR(4000) = NULL,
	@ErrorLogID TINYINT = NULL,
	@ErrorNumber INT = NULL,
	@ErrorSeverity INT = NULL,
	@ErrorState INT = NULL,
	@ErrorProcedure NVARCHAR(128) = NULL,
	@ErrorLine INT = NULL
/*****************************************************************************************************
* Name				: [Base].[csp_LogError]
* Description		: Stored Procedure insert the Errors into Errorlog table
* Type of Procedure : Natively Compiled stored procedure
* Author			: Pavan Kumar Manneru
* Creation Date		: 04/07/2016
* Last Modified		: N/A
* Parameters		:
*******************************************************************************************************
*Parameter Name				Type			Description
*------------------------------------------------------------------------------------------------------
@ErrorMessage				VARCHAR			Error Message
@ErrorLogID					TINYINT			Error Log ID
@ErrorNumber				INT				Error Number
@ErrorSeverity				INT				Error Severity
@ErrorState					INT				Error State
@ErrorProcedure				NVARCHAR		Error Procedure
@ErrorLine					INT				Error Line
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
*******************************************************************************************************/
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER 
AS BEGIN ATOMIC WITH (
      TRANSACTION ISOLATION LEVEL = SNAPSHOT,
      LANGUAGE = 'English')
	  
	  BEGIN TRY
		--Insert the Error details into the ErrorLog table 
        INSERT  [Base].[ErrorLog]
                    ( [OccuredDateTime]
					  ,[ErrorLogID]
					  ,[UserName]
					  ,[ErrorNumber]
					  ,[ErrorSeverity]
					  ,[ErrorState]
					  ,[ErrorProcedure]
					  ,[ErrorLine]
					  ,[ErrorMessage]
                    )
                    VALUES
					(
						GETDATE(),
						@ErrorLogID,
                        CONVERT(sysname, SUSER_NAME()) ,
                        @ErrorNumber,
                        @ErrorSeverity,
                        @ErrorState,
                        @ErrorProcedure ,
                        @ErrorLine,
                        @ErrorMessage
					)
                  
        END TRY
        BEGIN CATCH
            THROW
        END CATCH;

END
GO
/*

EXECUTE sp_addextendedproperty @name = N'Component', @value = N'STAR', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_LogError';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', 
	@value = N'This stored procedure will be called by [Base].[usp_LogError] for inserting the error details into table [Base].[ErrorLog]', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_LogError';


GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'1.0.0', 
	@level0type = N'SCHEMA', @level0name = N'Base', 
	@level1type = N'PROCEDURE', @level1name = N'csp_LogError';

*/