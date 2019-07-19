CREATE PROCEDURE [Excep].[usp_GetPostingResponseEntityMap](@ResponseID INT,@RneMoID BIGINT,@FileType VARCHAR(50))
/*****************************************************************************************************
* Name				: [Excep].[usp_GetPostingResponseEntityMap]
* Description		: Retrieves exception response details
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
AS
    SET NOCOUNT ON;
	
    BEGIN TRY

		DECLARE @Number INT;  
        DECLARE @Message VARCHAR(4000) ;
	    DECLARE @UserName NVARCHAR(128);  
        DECLARE @Severity INT;  
        DECLARE @State INT;  
        DECLARE @Type VARCHAR(128) = 'Stored Procedure';  
        DECLARE @Line INT;  
        DECLARE @Source VARCHAR(128) = 'Excep.usp_GetPostingResponseEntityMap'; 

		SELECT  
			ResponseID ,
			RNEMOID,
			ResponseTransID ,
			ResponseAggregationCnt ,
			ResponsePostType ,
			ResponseSubType ,
			RP.ResponseStatus ,
			ResponseSortCode ,
			ResponseAccNum ,
			ResponseAmount ,
			ResponseSTReasonCode ,
			RP.ResponseSequence ,
			ROW_NUMBER() OVER	( 
									PARTITION BY [ResponseID],ResponseTransID,[ResponsePostType],[ResponseSequence]
									ORDER BY  
									CASE 
										WHEN RP.ResponsePostType='DEB' AND RP.ResponseStatus IN ('N') AND RRC.DEWOverrideEntityState IS NOT NULL 
										THEN 1
										ELSE 9
									END 
								) RNK

		INTO
			#RNEPostingResp
		FROM    
			[Posting].[RNEPostingResponse] RP
		LEFT OUTER JOIN 
			Config.ResponseReasonCodes RRC 
		ON 
			RP.ResponseSTReasonCode = RRC.ReasonCode 
		AND 
			RP.ResponseStatus =RRC.ResponseStatus
		WHERE 
			RNEMOID = @RneMoID 
		AND 
			ResponseID = @ResponseID



		CREATE NONCLUSTERED INDEX nci_comp ON #RNEPostingResp(ResponseStatus, ResponseSubType)

		CREATE NONCLUSTERED INDEX 
			nci_comp2 
		ON 
			#RNEPostingResp(ResponseStatus, ResponseSTReasonCode)
		WHERE 
			RNK = 1 



		SELECT    
			FileType
			,AggregationCount
			,ResponseStatus
			,ResponseSubType
			,EntityType
			,EntityState
			,ResponseSTReasonCode
			,ExcepEntityState
		INTO
			#UNQRespMap
		FROM      
			Config.ResponseEntityMap
		GROUP BY   
			FileType
			,AggregationCount
			,ResponseStatus
			,ResponseSubType
			,EntityType
			,EntityState
			,ResponseSTReasonCode
			,ExcepEntityState


		CREATE NONCLUSTERED INDEX 
			nci_comp 
		ON 
			#UNQRespMap(ResponseStatus, ResponseSubType, FileType, EntityType)
		WHERE 
			EntityType = 'E'

		SELECT  
			ResponseTransID,
			RP.ResponsePostType,
			IIF (RP.ResponsePostType='DEB',ISNULL(RR.DEWOverrideEntityState, RE.EntityState), RE.EntityState) AS EntityState ,
			RE.ExcepEntityState,
			0 ExcepFlag,
			RP.ResponseStatus,
			RP.ResponseSequence,
			RP.ResponseSubType        
		FROM    
			#RNEPostingResp RP
		INNER JOIN 
			#UNQRespMap RE 
		ON 
			ISNULL(RP.ResponseSubType, 'NA') = ISNULL(RE.ResponseSubType,'NA')
		AND 
			RP.ResponseStatus = RE.ResponseStatus
		AND NOT 
			( 
				RP.ResponseStatus = 'P'
			AND 
				ISNULL(RP.ResponseSubType, 'NA') = 'C'
			)
		AND 
			RE.FileType = @FileType
		AND 
			RE.EntityType = 'E'
		LEFT JOIN 
			[Config].[ResponseReasonCodes] RR
		ON 
			RP.ResponseStatus = RR.ResponseStatus
		AND 
			RP.ResponseSTReasonCode = RR.ReasonCode
		WHERE  
			RNK = 1
		
		UNION ALL
		
			SELECT  
				ResponseTransID,
				RP.ResponsePostType,
				IIF (RP.ResponsePostType='DEB',ISNULL(RR.DEWOverrideEntityState, RE.EntityState), RE.EntityState)  AS EntityState ,
				RE.ExcepEntityState,
				0 ExcepFlag,
				RP.ResponseStatus,
				RP.ResponseSequence,
				RP.ResponseSubType 
			FROM    
				#RNEPostingResp RP
			INNER JOIN 
				#UNQRespMap RE 
			ON 
				ISNULL(RP.ResponseSubType, 'NA') = ISNULL(RE.ResponseSubType, 'NA')
			AND 
				RP.ResponseStatus = RE.ResponseStatus
			AND 
				( 
					RP.ResponseStatus = 'P'
				AND 
					ISNULL(RP.ResponseSubType, 'NA') = 'C'
				)
			AND 
				RE.FileType = @FileType
			AND 
				RE.EntityType = 'E'
			LEFT JOIN 
				[Config].[ResponseReasonCodes] RR
			ON 
				RP.ResponseStatus = RR.ResponseStatus
			AND 
				RP.ResponseSTReasonCode = RR.ReasonCode
			WHERE  
				RNK = 1
		
    END TRY

    BEGIN CATCH
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
    ON OBJECT::[Excep].[usp_GetPostingResponseEntityMap] TO [RNESVCAccess];
GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)', @level0type = N'SCHEMA', @level0name = N'Excep', @level1type = N'PROCEDURE', @level1name = N'usp_GetPostingResponseEntityMap';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This Procedure will get exception response.', @level0type = N'SCHEMA', @level0name = N'Excep', @level1type = N'PROCEDURE', @level1name = N'usp_GetPostingResponseEntityMap';


GO
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'iPSL.ICE.RNE.Database', @level0type = N'SCHEMA', @level0name = N'Excep', @level1type = N'PROCEDURE', @level1name = N'usp_GetPostingResponseEntityMap';

