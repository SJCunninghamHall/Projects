CREATE PROCEDURE [Posting].[usp_UpdateResponsePaidItems] (@ResponseID INT, @RneMoID BIGINT)
/*****************************************************************************************************
* Name				: [Posting].[usp_UpdateResponsePaidItems]
* Description		: Update SUM file aggregates from Response file
* Called By			: 
* Type of Procedure : Interpreted stored procedure
* Author			: Akuri Reddy
* Creation Date		: 13/07/2017
* Last Modified		: 
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************/
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN TRANSACTION;

	BEGIN TRY

		DECLARE @SPName VARCHAR(100)='[Posting].[usp_UpdateResponsePaidItems]'

		EXEC [Base].[usp_LogEvent] 1,@SPName,'Enter';  

		SELECT  
			ResponseID ,
			RNEMOID,
			ResponseTransID ,
			ResponsePostType ,
			ResponseNPASortCode ,
			ResponseNPAAccNum ,
			ResponseStatus,
			ROW_NUMBER() OVER (PARTITION BY ResponseTransID,ResponsePostType ORDER BY ResponseRecordID DESC) RNK
		INTO
			#RNEPostingResp
		FROM      
			[Posting].[RNEPostingResponse] 
		WHERE 
			RNEMOID = @RneMoID 
		AND 
			ResponseID = @ResponseID

		-- Filtered, covering index
		CREATE NONCLUSTERED INDEX 
			nci_RTID_RPT_RNK 
		ON 
			#RNEPostingResp(ResponseTransID, ResponsePostType, RNK)
		INCLUDE
			(ResponseNPASortCode, ResponseNPAAccNum)
		WHERE
			RNK = 1


		UPDATE 
			RP 
		SET
			RP.NPASortCode =IIF(RP.NPASortCode IS NULL, PR.ResponseNPASortCode, RP.NPASortCode)
			,RP.NPAAccountNumber = IIF(RP.NPAAccountNumber IS NULL, PR.ResponseNPAAccNum, RP.NPAAccountNumber)
		FROM 
			[Posting].[ExtractResponseDetails] RP
		INNER JOIN 
			#RNEPostingResp PR 
		ON 
			PR.ResponseTransID = RP.ItemIdentifier 
		AND 
			PR.ResponsePostType = RP.RecordPostType	
		WHERE 
			PR.RNK = 1

		EXEC [Base].[usp_LogEvent] 1, @SPName, 'Exit'; 

		IF ( XACT_STATE() ) = 1
		BEGIN
			COMMIT TRANSACTION;							
		END;

	END TRY	  
	BEGIN CATCH
		IF XACT_STATE() <> 0
				ROLLBACK TRANSACTION; 

		DECLARE @Number INT = ERROR_NUMBER();
		DECLARE @Message VARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @UserName NVARCHAR(128) = CONVERT(SYSNAME, ORIGINAL_LOGIN());
		DECLARE @Severity INT = ERROR_SEVERITY();
		DECLARE @State INT = ERROR_STATE();
		DECLARE @Type VARCHAR(128) = 'Stored Procedure';
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Source VARCHAR(128) = ERROR_PROCEDURE();
		EXEC [Base].[usp_LogException] @Number,
									   @Message,
									   @UserName,
									   @Severity,
									   @State,
									   @Type,
									   @Line,
									   @Source; 
		THROW;
	END CATCH;
END;
GO

GRANT EXECUTE ON [Posting].[usp_UpdateResponsePaidItems] TO [RNESVCAccess];
	
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Update response items status' , @level0type=N'SCHEMA',@level0name=N'Posting', @level1type=N'PROCEDURE',@level1name=N'usp_UpdateResponsePaidItems'
GO

EXEC sys.sp_addextendedproperty @name=N'Version', @value=N'$(Version)' , @level0type=N'SCHEMA',@level0name=N'Posting', @level1type=N'PROCEDURE',@level1name=N'usp_UpdateResponsePaidItems'
GO

EXEC sp_addextendedproperty @name = N'Component', @value = N'iPSL.ICE.RNE.Database', @level0type = N'SCHEMA', @level0name = N'Posting', @level1type = N'PROCEDURE', @level1name = N'usp_UpdateResponsePaidItems';
GO
