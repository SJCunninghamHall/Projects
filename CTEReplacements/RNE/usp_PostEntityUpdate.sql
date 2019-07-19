
/*****************************************************************************************************
* Name              : [Posting].[usp_PostEntityUpdate]
* Description       : Update Posting Updates to Entity
* Author  		: Asish Murali
*******************************************************************************************************
*Parameter Name				Type							   Description
*------------------------------------------------------------------------------------------------------
 @RNEMOID			    variable					        PostingId 
********************************************************************************************************
* Amendment History
*------------------------------------------------------------------------------------------------------
* Version 		ID          Date         Name             Reason
*******************************************************************************************************
* 1.0.0			001         21/02/2017 	 Asish		  This Procedure Update Record COunt and Nil update
                                                       to PostingEntityTable
*********************************************************************************************************/
CREATE PROCEDURE [Posting].[usp_PostEntityUpdate]
(
 @RNEMOID INT
)
AS

	SET NOCOUNT ON;

	BEGIN TRY

		BEGIN


			SELECT 
				ex.EntityIdentifier
				,SUM(CASE WHEN RecordPostType = 'NIL' THEN 1 ELSE 2 END) Post_check
			INTO
				#DiffPost
			FROM 
				[Posting].[RNEPostingExtract]  ex
			WHERE 
				ex.RnEMoID = @RNEMOID
			GROUP BY
				ex.EntityIdentifier

			CREATE NONCLUSTERED INDEX nci_EntityIdentifier ON #DiffPost(EntityIdentifier)

			UPDATE 
				pe
			SET 
				pe.PostNil = 
							CASE 
								WHEN Post_check = 1 
								THEN 'NIL' 
								ELSE NULL 
							END
			FROM 
				Staging.PostingEntity pe
			INNER JOIN	
				#DiffPost ex
			WHERE 
				pe.EntityIdentifier = ex.EntityIdentifier


			SELECT 
				ex.ItemIdentifier EntityIdentifier
				,MAX(ex.ItemPartitionSeq)  MaxRec
			INTO
				#MaxExtract
			FROM 
				[Posting].[RNEPostingExtract]  ex
			WHERE 
				ex.RnEMoID = @RNEMOID
			GROUP BY 
				ex.ItemIdentifier
			UNION 
				SELECT 
					ex.EntityIdentifier
					,MAX(ex.ItemPartitionSeq)  MaxRec
				FROM 
					[Posting].[RNEPostingExtract]  ex
				WHERE 
					ex.RnEMoID = @RNEMOID
				GROUP BY 
					ex.EntityIdentifier

			CREATE NONCLUSTERED INDEX nci_EntityIdentifier ON #MaxExtract(EntityIdentifier)

			UPDATE 
				pe
			SET 
				pe.RecordCount = ex.MaxRec
			FROM 
				Staging.PostingEntity pe
			INNER JOIN
				#MaxExtract ex
			ON 
				pe.EntityIdentifier = ex.EntityIdentifier 


		END
		
	END TRY

	BEGIN CATCH

		DECLARE @ErrorNumber int;
		DECLARE @ErrorMessage varchar(4000);

		SET @ErrorNumber = ERROR_NUMBER();
		SET @ErrorMessage = ERROR_MESSAGE();

		THROW;

	END CATCH;
GO

GO

GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'1.0.0', @level0type = N'SCHEMA', @level0name = N'Posting', @level1type = N'PROCEDURE', @level1name = N'usp_PostEntityUpdate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Update Staging Posting Entity with Record counts and NIL', @level0type = N'SCHEMA', @level0name = N'Posting', @level1type = N'PROCEDURE', @level1name = N'usp_PostEntityUpdate';


GO
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'iPSL.ICE.RNE.Database', @level0type = N'SCHEMA', @level0name = N'Posting', @level1type = N'PROCEDURE', @level1name = N'usp_PostEntityUpdate';

