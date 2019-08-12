CREATE PROCEDURE [Base].[usp_Load_XML_MOMessage_ICN_Core_EntityUpdate_Error_New]
    @ICNEntityAuditUpdateHolder [Base].[ICNEntity_New] READONLY
/*****************************************************************************************************
* Name				: [Base].[usp_Load_XML_MOMessage_ICN_Core_EntityUpdate_Error]
* Description		: This Stored Procedure is called by Base.usp_Load_XML_MOMessage_ICN_CoreEntityUpdate
					  to insert the fields read from the XML into the Base.EntityError table
* Type of Procedure : Interpreted stored procedure
* Author			: Pavan Kumar Manneru
* Creation Date		: 04/07/2016
* Last Modified		: N/A
* Parameters		:
*******************************************************************************************************
*Parameter Name				Type					Description
*------------------------------------------------------------------------------------------------------
@ICNItemUpdate		ICNItemUpdateHolder				Entire list of ItemUpdates
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
AS
    BEGIN
        SET NOCOUNT ON;
        BEGIN TRY

            --Insert the EntityError values into the EntityError table
            INSERT INTO [Base].[EntityError] (   [EntityId] ,
                                                 [EntityStateID] ,
                                                 [ErrorCode] ,
                                                 [ErrorDescription]
                                             )
                        SELECT [EntityId] ,
                               NEXT VALUE FOR [Base].[sqn_EntityError] ,
                               [ErrorCode] ,
                               [ErrorDescription]
                        FROM   @ICNEntityAuditUpdateHolder X
                        WHERE  (   X.[ErrorCode] IS NOT NULL
                                   OR X.[ErrorDescription] IS NOT NULL
                               );

        END TRY
        BEGIN CATCH
            THROW;
        END CATCH;

    END
GO

/*
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_Load_XML_MOMessage_ICN_Core_EntityUpdate_Error_New';
GO

EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This Stored Procedure is called by Base.usp_Load_XML_MOMessage_ICN_CoreEntityUpdate
			   to insert the fields read from the XML into the Base.EntityError table', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_Load_XML_MOMessage_ICN_Core_EntityUpdate_Error_New';
GO

EXECUTE sp_addextendedproperty @name = N'Component', @value = N'STAR', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_Load_XML_MOMessage_ICN_Core_EntityUpdate_Error_New';
GO
*/