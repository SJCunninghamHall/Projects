CREATE PROCEDURE [DataImport].[usp_LoadSortCodeAttributeData]
/*****************************************************************************************************
* Name				: [DataImport].[usp_LoadSortCodeAttributeData]
* Description		: Update business date for new records and insert records into Report.DimParticipantData table
* Called By			: 
* Type of Procedure : Interpreted stored procedure
* Author			: Nageswara Rao
* Creation Date		: 14/02/2019
* Last Modified		: 
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************/
AS
    BEGIN  

        SET NOCOUNT ON;  

		BEGIN TRY  
 
			DECLARE @BusinessDate DATE;

			SELECT  @BusinessDate = BusinessDate 
			FROM    [Config].[ProcessingDate];
			
			BEGIN TRANSACTION;   

				UPDATE  
					[Staging].[SortCodeWithAttributes]
				SET     
					BusinessDate = @BusinessDate
				WHERE   
					BusinessDate IS NULL;

				--DELETING THE DUPLICATES FOR THAT Business Date
				;WITH DUPCTE
					AS
					(
						SELECT	
							SortCode
							,ROW_NUMBER() OVER (PARTITION BY SortCode ORDER BY SortCodeKey DESC) RowNum 
						FROM 
							[Staging].[SortCodeWithAttributes]
						WHERE 
							BusinessDate = @BusinessDate
					)

				DELETE DUPCTE WHERE RowNum > 1

				INSERT INTO 
					[Report].[dimParticipantData]
					(
						SortCode
						,ParticipantID
						,SettlementParticipantID
						,ParticipantName
						,SettlementBankName
						,ONUSFlag
					)
				SELECT	
					SortCode
					,ParticipantId AS ParticipantID
					,SettlementParticipantID
					,BankName AS ParticipantName 
					,SettlementBankName
					,ONUSFlag				                 
				FROM    
					Staging.SortCodeWithAttributes SCWA
				INNER JOIN 
					Config.ProcessingDate PD 
				ON 
					SCWA.BusinessDate = PD.BusinessDate
				WHERE   
					SCWA.BankOfficeType <> 'S'
  
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
			
			EXEC [Base].[usp_LogException] @Number, @Message, @UserName,
				@Severity, @State, @Type, @Line, @Source;  
			
			THROW;  
		END CATCH;  
    END;
GO
	
GRANT EXECUTE ON [DataImport].[usp_LoadSortCodeAttributeData] TO [RnEReportDwDataImporter];
	
GO

EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)',
    @level0type = N'SCHEMA', @level0name = N'DataImport', @level1type = N'PROCEDURE',
    @level1name = N'usp_LoadSortCodeAttributeData';
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'This stored procedure Update business date for new records and insert records into Report.DimParticipantData table.',
    @level0type = N'SCHEMA', @level0name = N'DataImport', @level1type = N'PROCEDURE',
    @level1name = N'usp_LoadSortCodeAttributeData';
GO
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'RnEReportDataWarehouse',
    @level0type = N'SCHEMA', @level0name = N'DataImport', @level1type = N'PROCEDURE',
    @level1name = N'usp_LoadSortCodeAttributeData';
GO
EXEC sys.sp_addextendedproperty 
@name=N'Calling Application'
, @value=N'IPSL.RNE.RefreshDWHSOD.dtsx' 
, @level0type=N'SCHEMA'
, @level0name=N'DataImport'
, @level1type=N'PROCEDURE'
, @level1name=N'usp_LoadSortCodeAttributeData'
