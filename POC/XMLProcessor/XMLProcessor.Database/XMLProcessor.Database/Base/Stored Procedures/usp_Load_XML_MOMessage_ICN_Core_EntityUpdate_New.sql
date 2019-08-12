CREATE PROCEDURE [Base].[usp_Load_XML_MOMessage_ICN_Core_EntityUpdate_New]
    @ICNEntityAuditUpdateHolder [Base].[ICNEntity_New] READONLY
/*****************************************************************************************************
* Name				: [Base].[usp_Load_XML_MOMessage_ICN_Core_EntityUpdate]
* Description		: This Stored Procedure is called by Base.usp_Load_XML_MOMessage_ICN_CoreEntityUpdate
					  to insert the fields read from the XML into the Base.Entity table	
* Type of Procedure : Natively Compiled stored procedure
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

            --Insert the EntityUpdate values into EntityUpdate table
            INSERT INTO [Base].[Entity] (   [EntityId] ,
                                            [CoreId] ,
                                            [EntityType] ,
                                            [EntityIdentifier] ,
                                            [Revision] ,
                                            [EntityState] ,
                                            [SourceDateTime]
                                        )
                        SELECT X.[EntityId] ,
                               X.[CoreId] ,
                               X.[EntityType] ,
                               X.[EntityIdentifier] ,
                               X.[Revision] ,
                               X.[EntityState] ,
                               X.[SourceDateTime]
                        FROM   (   SELECT [EntityId] ,
                                          [CoreId] ,
                                          [EntityType] ,
                                          [EntityIdentifier] ,
                                          [Revision] ,
                                          [EntityState] ,
                                          [SourceDateTime] ,
                                          ROW_NUMBER() OVER ( PARTITION BY EntityId
                                                              ORDER BY EntityId
                                                            ) RowNum
                                   FROM   @ICNEntityAuditUpdateHolder
                               ) X
                        WHERE  X.RowNum = 1;

        END TRY
        BEGIN CATCH
            THROW;
        END CATCH;

    END;
GO

/*
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_Load_XML_MOMessage_ICN_Core_EntityUpdate_New';
GO

EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This Stored Procedure is called by Base.usp_Load_XML_MOMessage_ICN_CoreEntityUpdate
			   to insert the fields read from the XML into the Base.Entity table', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_Load_XML_MOMessage_ICN_Core_EntityUpdate_New';
GO

EXECUTE sp_addextendedproperty @name = N'Component', @value = N'STAR', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_Load_XML_MOMessage_ICN_Core_EntityUpdate_New';
GO
*/