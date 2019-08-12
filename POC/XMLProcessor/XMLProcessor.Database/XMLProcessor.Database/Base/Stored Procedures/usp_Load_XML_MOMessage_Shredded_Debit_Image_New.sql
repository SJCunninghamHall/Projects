CREATE PROCEDURE [Base].[usp_Load_XML_MOMessage_Shredded_Debit_Image_New]
    @DebitHolder [Base].[tv_Debit_New] READONLY
/*****************************************************************************************************
* Name				: [Base].[usp_Load_XML_MOMessage_Shredded_Debit_Image]
* Description		: This stored procedure will be called by all the TxSet related importing stored procedures
					  to insert the values read from xml into Base.[Image] table
* Type of Procedure : Interpreted stored procedure
* Author			: Anton Richards
* Creation Date		: 28/09/2016
* Last Modified		: N/A
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************/

AS
    BEGIN
        SET NOCOUNT ON;
        BEGIN TRY

            --Insert the Image values into the Image table



            INSERT INTO [Base].[Image] (   [ItemId] ,
                                           [ImageHash] ,
                                           [Image] ,
                                           [CaptureId] ,
                                           [CaptureDeviceID] ,
                                           [CaptureLocation] ,
                                           [CaptureDateTime] ,
                                           [FrontImageQuality] ,
                                           [RearImageQuality],
										   [UniqueItemIdentifier]
                                       )
                        SELECT x.ItemId ,
                               x.[ImageHash] ,
                               x.[Image] ,
                               x.[CaptureId] ,
                               x.[CaptureDeviceID] ,
                               x.[CaptureLocation] ,
                               x.[CaptureDateTime] ,
                               x.[FrontImageQuality] ,
                               x.[RearImageQuality],
							   x.DebitId AS [UniqueItemIdentifier]
                        FROM   @DebitHolder x
                        WHERE  ( x.Image IS NOT NULL );

        END TRY
        BEGIN CATCH
            THROW;
        END CATCH;

    END;
GO
/*
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_Load_XML_MOMessage_Shredded_Debit_Image_New';
GO

EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This stored procedure will be called by all the TxSet related importing stored procedures
			   to insert the values read from xml into Base.[Image] table', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_Load_XML_MOMessage_Shredded_Debit_Image_New';
GO

EXECUTE sp_addextendedproperty @name = N'Component', @value = N'STAR', @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE', @level1name = N'usp_Load_XML_MOMessage_Shredded_Debit_Image_New';
GO
*/