CREATE PROCEDURE [Excep].[usp_UpdateResponseException](@ResponseID INT,@RneMoID BIGINT,@FileType VARCHAR(50))
/*****************************************************************************************************
* Name				: [Excep].[usp_UpdateResponseException]
* Description		: Updates the response entity
* Called By			: IPSL.RNE.ImportPostingResponseXML.dtsx
* Type of Procedure : Interpreted stored procedure
* Author			: Asish Murali
* Creation Date		: 15/06/2017
* Last Modified		: 
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************/
/****************************************************************************************************** 
Changed By         Changed Date          Bug Id

Alpa               07/12/2018            204287(Sonar Cloud).
*******************************************************************************************************/
AS
    SET NOCOUNT ON;

	BEGIN TRANSACTION;

    BEGIN TRY

		DECLARE @Number INT;
        DECLARE @Message VARCHAR(4000) ;
	    DECLARE @UserName NVARCHAR(128);  
        DECLARE @Severity INT;  
        DECLARE @State INT;  
        DECLARE @Type VARCHAR(128) = 'Stored Procedure';  
        DECLARE @Line INT;  
        DECLARE @Source VARCHAR(128) = 'Excep.usp_UpdateResponseException'; 

		/* if Update Response Flag and Response Entity State */

		SELECT  
			MAX(ET.[InternalID]) AS InternalId
		INTO
			#ValidRecord
		FROM  
			[Staging].[TmpRespEntity] ET 
		LEFT JOIN 
			(
				SELECT  
					MAX(ResponseSequence) AS MaxSequence
					,ResponseTransID
					,ResponsePostType 
				FROM 
					[Staging].[TmpRespEntity] 
				WHERE 
					ISNULL(ExcepFlag,0) =0
				GROUP BY 
					ResponseTransID
					,ResponsePostType
			) As Result 
		ON   
			ET.ResponseTransID = Result.ResponseTransID
		AND 
			ET.ResponsePostType = Result.ResponsePostType
		WHERE 
			Result.ResponseTransID IS NULL 
		OR 
			ET.ResponseSequence=Result.MaxSequence
		GROUP BY 
			ET.ResponseTransID
			,ET.ResponsePostType


		CREATE NONCLUSTERED INDEX nci_InternalId ON #ValidRecord(InternalId)


		UPDATE  
			EP			
		SET 
			ResponseEntityState = 	CASE 
										WHEN ISNULL(ET.ExcepFlag,0) = 0 
										THEN ET.EntityState 
										ELSE EP.ResponseEntityState 
									END,
			[ResponseFlag] = 	CASE 
									WHEN ISNULL(ET.ExcepFlag,0) = 0 
									THEN 1 
									ELSE EP.[ResponseFlag] 
								END,
			EP.ResponseStatus=
								CASE 	
									WHEN ISNULL(ET.ExcepFlag, 0) = 0 AND (ET.ResponseStatus = 'P' AND ET.ResponseSubType = 'D')
									THEN ET.ResponseSubType
									WHEN ISNULL(ET.ExcepFlag,0) = 0 
									THEN ET.ResponseStatus
									ELSE EP.ResponseStatus
								END,			
			EP.[ExceptionFlag] =	CASE 
										WHEN ISNULL(ET.ExcepFlag,0) != 0 
										THEN ET.ExcepFlag
										ELSE NULL
									END,
			EP.ExcepEntityState = 	CASE 
										WHEN ISNULL(ET.ExcepFlag,0) != 0  
										THEN ET.ExcepEntityState 
										ELSE NULL
									END,
			EP.[ExtractedInUnexpectedNoReportFlag] = IIF(ET.ExcepFlag > 0 , NULL,EP.[ExtractedInUnexpectedNoReportFlag])
		FROM  
			[Staging].[TmpRespEntity] ET 
		INNER JOIN 
			[Posting].vw_ExtractResponseDetailsLatest EP
		ON 
			ET.ResponseTransID = EP.ItemIdentifier
		AND 
			EP.RecordPostType = ET.ResponsePostType
		INNER JOIN 
			#ValidRecord VR
		ON 
			VR.InternalId =ET.InternalID

		--- To mark the items as exception for which response entity state was not derived due to sub type mismatch or any other issues

		SELECT 
			ResponseTransID,
			ResponsePostType,
			ResponseStatus,
			ResponseSubType,	   
			CASE 
				WHEN ResponseStatus='Y' THEN 973 
				WHEN ResponseStatus='N' THEN 962
				ELSE 963
			END AS ExcepEntityState
		INTO
			#MissedItems
		FROM 
			[Posting].[RNEPostingResponse] RP
		WHERE 
			RNEMOID = @RneMoID 
		AND 
			ResponseID = @ResponseID
		AND 
			ResponseTransID NOT IN
								(
									SELECT 
										ResponseTransID
									FROM  
										[Staging].[TmpRespEntity]
								)




		CREATE NONCLUSTERED INDEX nci_RTID_RPT ON #MissedItems(ResponseTransID, ResponsePostType) 




		UPDATE  
			EP			
		SET		    
			EP.ResponseStatus= MI.ResponseStatus,																	
			EP.ExcepEntityState = MI.ExcepEntityState,
			EP.[ExceptionFlag] =
								(
									SELECT TOP 1 
										ISNULL([ExceptionID],0) 
									FROM 
										[Config].[ValidateException] 
									WHERE 
										ExceptionName = 'NoEntityState'
								),
			EP.[ExtractedInUnexpectedNoReportFlag] = IIF(MI.ExcepEntityState >0 , NULL,EP.[ExtractedInUnexpectedNoReportFlag])
		FROM  
			[Posting].vw_ExtractResponseDetailsLatest EP
		INNER JOIN 
			#MissedItems MI
		ON 
			MI.ResponseTransID = EP.ItemIdentifier
		AND 
			MI.ResponsePostType =EP.RecordPostType 

			
		UPDATE  
			EP			
		SET 
			EP.[ExceptionFlag] = ET.ExcepFlag,
			EP.ExcepEntityState = ET.ExcepEntityState,
			EP.[ExtractedInUnexpectedNoReportFlag] = NULL
		FROM  
			[Staging].[TmpRespEntity] ET 
		INNER JOIN 
			[Posting].vw_ExtractResponseDetailsLatest EP
		ON 
			ET.ResponseTransID = EP.ItemIdentifier
		AND 
			EP.RecordPostType = ET.ResponsePostType
		WHERE 
			ET.ExcepFlag > 0

		IF ( XACT_STATE() ) = 1
		BEGIN
			COMMIT TRANSACTION;							
		END;

	  END TRY
	  BEGIN CATCH
	    IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION; 

			-- transaction Rollback
			SELECT @Number = ERROR_NUMBER();  
            SELECT @Message = ERROR_MESSAGE() ;
			SELECT @UserName  = CONVERT(SYSNAME, ORIGINAL_LOGIN());  
            SELECT @Severity = ERROR_SEVERITY();  
            SELECT @State = ERROR_STATE();  
            SELECT @Type = 'Stored Procedure';  
            SELECT @Line = ERROR_LINE();  
            SELECT @Source = ERROR_PROCEDURE();  

            EXEC [Base].[usp_LogException] @Number, @Message, @UserName,
                @Severity, @State, @Type, @Line, @Source;  
            THROW
    END CATCH;
GO
GRANT EXECUTE
    ON OBJECT::[Excep].[usp_UpdateResponseException] TO [RNESVCAccess];
GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)', @level0type = N'SCHEMA', @level0name = N'Excep', @level1type = N'PROCEDURE', @level1name = N'usp_UpdateResponseException';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This Procedure will load update the response entity', @level0type = N'SCHEMA', @level0name = N'Excep', @level1type = N'PROCEDURE', @level1name = N'usp_UpdateResponseException';


GO
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'iPSL.ICE.RNE.Database', @level0type = N'SCHEMA', @level0name = N'Excep', @level1type = N'PROCEDURE', @level1name = N'usp_UpdateResponseException';

