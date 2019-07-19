/*****************************************************************************************************
* Name              : [usp_GetStopsAccountToApg]
* Description  	    : This Stored Procedure will fetch the records from [Base].StopsDetailtable.
* Author			: Subrat Samal			   
*******************************************************************************************************
*Parameter Name				Type							   Description
*------------------------------------------------------------------------------------------------------

*******************************************************************************************************************************
* Amendment History
*------------------------------------------------------------------------------------------------------------------------------
* ID			Date             User					Reason
*****************************************************************************************************
* 001			26/01/2017 		Subrat Samal			Initial version
* 002			28/03/2017 		Jaisankar N.			Removed SourceDetaildId condition and added participantdId
* 003			09/05/2017 		Divya Singh				Changed Schema from LBG to RefOut
* 004			12/05/2017		Divya Singh				Changed the LogExecption sp name to SqlErrorLog
* 005			27/06/2017		Shiju					Added Filesource <> 'IFCA' Condition
* 006			03/07/2017		Bhaskar Reddy			Removed the table [Base].[StopsTravellerDetail] in sp
* 007			24/07/2017		Divya Singh				Code Review Action remove unused Parameter 
* 008			27/07/2017		Champika B				Code Review Action Deadlock Proof Changes
* 009			01/08/2017		Champika B				SQL code alignment
* 010			04/09/2017 		Nisha Merline			Code review action remove NOT functionality
* 011			04/09/2017		Champika B				Code Review Action remove version number
* 012			15/09/2017		Champika B				Number of Deadlock  retry value to config table
* 013           10/04/2018      Champika B				PBI 173917 Live hotfix STOPs change
* 013           18/04/2018      Jaisankar N				PBI 173917 Live hotfix STOPs change - added numeric validation
* 014           30/01/2019      Mazar Shaik				PBI 208078 CR236 - Commercial Lotted Stops - Ref Data Changes
* 015			16/05/2019		Shiju B					PBI 218506 CR392 - NPA Stops
* 016			23/05/2019		Byamakesh				PBI 218506 CR392 - NPA Stops, added @BusinessDate variable and UNION
* 017			18/06/2019		Byamakesh				Fix for bug 222447 - Corrected BusinessDay check with EffectiveFrom
******************************************************************************************************/
CREATE PROCEDURE [RefOut].[usp_GetStopsAccountToApg]
AS
BEGIN

	SET NOCOUNT ON;
      
	DECLARE @ErrorNumber INT;
	DECLARE @ErrorMessage VARCHAR(4000);     
	DECLARE @Severity INT;
	DECLARE @State INT;
	DECLARE @Procedure VARCHAR(128);
	DECLARE @Line INT;
	DECLARE @Tries INT = 1;
	DECLARE @TriesVal INT;
	DECLARE @BusinessDate DATETIME;

	SET @TriesVal = (SELECT [Value] FROM Base.ConfigSettings WHERE [Name] = 'DeadLockRetry')
	SET @BusinessDate = (SELECT [BusinessDate] FROM [Base].[BusinessDate])
	
	WHILE @Tries <= @TriesVal
	BEGIN	
		BEGIN TRY

			SELECT [SD].[SortCode]
				  ,[SD].[AccountNumber]
				  ,[SD].ParticipantId
				  ,CASE WHEN [SD].SortCode = ST.SortCode THEN 1 ELSE 2 END AS StopStatus
			INTO
				#CTE
			FROM 
				[Base].[StopsDetail] SD			
			INNER JOIN 
				[Base].[StopsHeader] SH 
			ON 
				[SD].[HeaderId] = [SH].[HeaderId]	
			LEFT JOIN 
				[Manual].LBGStopTypes ST 
			ON 
				ST.SortCode = RIGHT('000000' + CONVERT(VARCHAR(6), [SD].SortCode),6)
			WHERE 
				StopType='R' 
			AND 
				(
					[SH].[FileSource] = 'NCA' 
				OR 
					[SH].[FileSource] ='RCBS' 
				OR 
					[SH].[FileSource] = 'CS'
				)
			OR 
				(
					StopType IN ('S','M') 
				AND 
					(
						ISNUMERIC(sd.StartChequeNumber) = 0  
					OR  
						ISNUMERIC(sd.EndChequeNumber) = 0 
					)
				)

			UNION ALL
			
				SELECT 
					[SD].[SortCode]
					,[SD].[AccountNumber]
					,[SD].ParticipantId
					,CASE 
						WHEN [SD].SortCode = ST.SortCode 
						THEN 1 
						ELSE 2 
					END AS StopStatus
				FROM 
					[Base].[StopsDetail] SD			
				LEFT JOIN 
					[Manual].LBGStopTypes ST 
				ON 
					ST.SortCode = RIGHT('000000' + CONVERT(VARCHAR(6), [SD].SortCode),6)
				WHERE 
					[SD].[HeaderId] IS NULL 
				AND 
					(
						StopType='R' 
					OR 
						(
							StopType IN ('S','M') 
						AND 
							(
								ISNUMERIC(sd.StartChequeNumber) = 0  
							OR  
								ISNUMERIC(sd.EndChequeNumber) = 0 
							)
						)
					)
				AND 
					[SD].[EffectiveFrom] <= @BusinessDate
				AND 
					[SD].[IsDeleted] = 0
			

			SELECT 
			[SortCode]
					,[AccountNumber]
					,[StopStatus]
			FROM 
				CTE 
			GROUP BY 
				[SortCode]
				,[AccountNumber]
				,[StopStatus]
			ORDER BY 
				[SortCode]
				,[AccountNumber]
				,[StopStatus]

			BREAK

		END TRY
		BEGIN CATCH				
			IF(ERROR_NUMBER() =1205)
			BEGIN
				SET @Tries = @Tries + 1
				IF @Tries <= @TriesVal
				CONTINUE	
				ELSE 
				THROW;
			END
			ELSE
			SET @ErrorNumber = ERROR_NUMBER();
			SET @ErrorMessage = ERROR_MESSAGE();		
			SET @Severity = ERROR_SEVERITY();
			SET @State = ERROR_STATE();
			SET @Line = ERROR_LINE();
			SET @Procedure = ERROR_PROCEDURE();
			EXEC [Base].[usp_SqlErrorLog] @ErrorNumber,@Severity,@State, @Procedure,@Line,@ErrorMessage;
			THROW;
		END CATCH;
	END
END
GO
EXEC sys.sp_addextendedproperty @name=N'Component', @value=N'iPSL.ReferenceDataDB' , @level0type=N'SCHEMA',@level0name=N'RefOut', @level1type=N'PROCEDURE',@level1name=N'usp_GetStopsAccountToApg'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'This Stored Procedure will fetch the records from [Base].StopsDetailtable' , @level0type=N'SCHEMA',@level0name=N'RefOut', @level1type=N'PROCEDURE',@level1name=N'usp_GetStopsAccountToApg'
GO
EXEC sys.sp_addextendedproperty @name=N'Version', @value=N'$(Version)' , @level0type=N'SCHEMA',@level0name=N'RefOut', @level1type=N'PROCEDURE',@level1name=N'usp_GetStopsAccountToApg'
GO
GRANT EXECUTE
    ON OBJECT::[RefOut].[usp_GetStopsAccountToApg] TO [Reference_Lloyds_Access];
