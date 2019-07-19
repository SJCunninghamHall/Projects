CREATE PROCEDURE [Base].[usp_EOD_PayerBenReconPostingExtract]
    (
        @ActivityID            VARCHAR(60),
        @ReconStage            VARCHAR(100),
        @BusinessDateEntity    VARCHAR(10),
        @BusinessDateAttribute VARCHAR(5),
        @UserName              VARCHAR(50),
        @Source                VARCHAR(100),
        @Result                INT           OUTPUT,
        @Sysout                VARCHAR(1000) OUTPUT
    )
/*****************************************************************************************************
* Name				: [Base].[usp_EOD_PayerBenReconPostingExtract]
* Description		: Stored Procedure to perform Reconciliation for beneficiary trigger and extract (PTMA01,PERM01,PEMA01) for beneficiary
					  and items triggered for payer on day2. Triggered,Extracted and Archived items are checked for reconciliation.
					  Success code is returned in case of recon success else failure is returned. 
* Type of Procedure : User-defined stored procedure
* Author			: Arushi Pabla
* Creation Date		: 27-Jun-2018
* Last Modified		: Rahul
* Parameters		: 8
*******************************************************************************************************
*Parameter Name				Type							Description
*------------------------------------------------------------------------------------------------------
 @ActivityID				VARCHAR(60)						Activity Id for logging table
,@ReconStage				VARCHAR(100)					Workflow to get parameters from EODParams
,@BusinessDateEntity		VARCHAR(10)						Business Date entity to get value from config
,@BusinessDateAttribute		VARCHAR(5)						Business Date attribute to get value from config.
,@UserName					VARCHAR(50) 					User Name from the package
,@Source					VARCHAR(100) 					Package name
,@Result					INT								Output paramater considering result
,@Sysout					VARCHAR(1000) 					Output paramater considering error description
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************
*										History
*------------------------------------------------------------------------------------------------------
* Version	ID		Date			Reason
*******************************************************************************************************
* 1.0.0		001     27-Jun-2018		Initial version
* 1.0.1	    002     23-Oct-2018     Updated SP for Posting Holdover to Posting Rollover change
* 1.0.1		002		15-Jan-2019		Removed CHARINDEX from table columns to improve performance
*******************************************************************************************************/
AS
    BEGIN

        SET NOCOUNT ON;

        SET XACT_ABORT ON;

        BEGIN TRY
            BEGIN TRANSACTION;
            DECLARE @itemsNotTriggered INT = 0;
            DECLARE @itemsNotExtracted INT = 0;
            DECLARE @itemsNotArchived INT = 0;
			DECLARE @itemsNotInFinalState INT = 0;	
			DECLARE @itemsNotSentToBank INT = 0;
			DECLARE @itemsSentToBankNotArchv INT = 0;					
			DECLARE @itemsNotTriggeredFor06DM01 INT = 0;
			DECLARE @itemNotReceivedPSRM01 INT = 0;
            DECLARE @decision BIT;
            DECLARE @severity INT;
            DECLARE @errorCode VARCHAR(10);
            DECLARE @message VARCHAR(500) = ' ';
			DECLARE @PostingRolloverItemsNotTriggered INT = 0;
			DECLARE @BusinessDate DATE = [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue](@BusinessDateEntity, @BusinessDateAttribute);          
			DECLARE @PostingRetriggerState VARCHAR(1000)
                = ','+[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'PostingRetriggerState')+',';--948
			DECLARE @PEMA01States VARCHAR(50)
                = ','+[$(MoConfigDatabase)].[Config].sfn_ReadScalarConfigEAVValue('EOD', 'PEMA01States')+',';--950,975,949,947
            DECLARE @NonExtractState VARCHAR(1000)
                = ','+[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'NonExtractState')+',';-- 945
          	DECLARE @ExtractMessageTypes VARCHAR(1000)
                = ','+[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'IntMsgTypeExtractArchive')+',';--PEMA01			
			DECLARE @PayerBenTriggerableStates VARCHAR(1000)
                = ','+[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'PayerBenTriggerableStates')+',';
			 DECLARE @06Dm01ClearingState VARCHAR(1000)
                = ','+[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', '06Dm01ClearingState')+',';--560,561
			DECLARE @Day1ClearingState VARCHAR(1000)
                = ','+[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', '06Day1PostableClearingState')+',';--520
			 DECLARE @06Km01PostingState VARCHAR(1000)
                = ','+[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', '06Km01PostingState')+',';--970
			DECLARE @SentToBankSuccessPostingStates VARCHAR(1000)
                = ','+[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'SentToBankSuccess')+',';--955
			DECLARE @SentToBankCDFailurePostingStates VARCHAR(1000)
                = ','+[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'SentToBankConnectDirectFailure')+',';--956
			DECLARE @SentToBankOtherFailurePostingStates VARCHAR(1000)
                = ','+[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'SentToBankOtherFailure')+',';--957,958
			DECLARE @ExtractSuccessStates VARCHAR(1000)
				= ','+[$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('EOD', 'PendingResponseStates')+',';--950
			DECLARE @PostingRollOverES INT
				= [$(MoConfigDatabase)].[Config].[sfn_ReadScalarConfigValue]('PostingRollOver', 'PostingRollOverEntityState');--901

			CREATE TABLE #NotTriggeredStates 
			(
				CollectorState SMALLINT,
				RetriggerState  SMALLINT
			)

			INSERT INTO 
				#NotTriggeredStates
			SELECT 
				CollectorTriggerableStates.value
				,PostingRetriggerState.value 
			FROM 
				string_split(@PostingRetriggerState,',') PostingRetriggerState
			CROSS APPLY 
				(
					SELECT 
						value 
					FROM 
						string_split(@PayerBenTriggerableStates,',') 
					WHERE 
						value != ''
				EXCEPT
					SELECT 
						value 
					FROM 
						string_split(@06Dm01ClearingState,',') 
					WHERE 
						value != ''
				) CollectorTriggerableStates
			WHERE 
				PostingRetriggerState.value != '';

			CREATE TABLE #Day1TriggerStates
			(
				CollectorState SMALLINT,
				ResponseState SMALLINT
			)

			INSERT INTO 
				#Day1TriggerStates
			SELECT 
				Day1ClearingState.value
				,Km01PostingState.value 
			FROM 
				string_split(@06Km01PostingState,',') Km01PostingState
			CROSS APPLY 
				(
					SELECT 
						value 
					FROM 
						string_split(@Day1ClearingState,',') 
					WHERE 
						value != ''
				) Day1ClearingState
			WHERE 
				Km01PostingState.value != '';

			CREATE TABLE #itemsNotTriggeredFor06DM01
			(
				CollectorState SMALLINT,
				RetriggerState SMALLINT
			)
			INSERT INTO 
				#itemsNotTriggeredFor06DM01
			SELECT 
				Dm01ClearingState.value
				,Dm01ClearingState.value 
			FROM 
				string_split(@06Dm01ClearingState,',') Dm01ClearingState
			CROSS APPLY 
				(
					SELECT 
						value 
					FROM 
						string_split(@PostingRetriggerState,',') 
					WHERE 
						value != ''
				) PostingRetriggerState
			WHERE 
				Dm01ClearingState.value != '';

			CREATE TABLE #PostingRolloverItemsNotTriggeredStates
			(
				FailureState SMALLINT
			)
			INSERT INTO 
				#PostingRolloverItemsNotTriggeredStates
			SELECT 
				SentToBankOtherFailurePostingStates.value 
			FROM 
				string_split(@SentToBankOtherFailurePostingStates,',') SentToBankOtherFailurePostingStates
			WHERE 
				SentToBankOtherFailurePostingStates.value != '';

			CREATE TABLE #itemsNotExtracted
			(
				CollectorState SMALLINT,
				NotExtractedState SMALLINT
			)
			INSERT INTO 
				#itemsNotExtracted
			SELECT 
				PayerBenTriggerableStates.value
				,NonExtractState.value 
			FROM 
				string_split(@PayerBenTriggerableStates,',') PayerBenTriggerableStates
			CROSS APPLY 
				(
					SELECT 
						value 
					FROM 
						string_split(@NonExtractState,',') 
					WHERE 
						value != ''
				) NonExtractState
			WHERE 
				PayerBenTriggerableStates.value != '';

			CREATE TABLE #itemsNotArchived
			(
				CollectorState SMALLINT,
				ExtractedState SMALLINT,
				MessageType	   VARCHAR(6)
			)
			INSERT INTO 
				#itemsNotArchived
			SELECT 
				PayerBenTriggerableStates.value
				,PEMA01States.value
				,ExtractMessageTypes.value 
			FROM 
				string_split(@PayerBenTriggerableStates,',') PayerBenTriggerableStates
			CROSS APPLY 
				(
					SELECT 
						value 
					FROM 
						string_split(@PEMA01States,',') 
					WHERE 
						value != ''
				) PEMA01States
			CROSS APPLY 
				(
					SELECT 
						value 
					FROM 
						string_split(@ExtractMessageTypes,',') 
					WHERE 
						value != ''
				) ExtractMessageTypes
			WHERE 
				PayerBenTriggerableStates.value != '';

			CREATE TABLE #itemsNotReceived
			(
				CollectorState SMALLINT,
				ExtractedState SMALLINT,
				MessageType	   VARCHAR(6)
			)
			INSERT INTO 
				#itemsNotReceived
			SELECT 
				PayerBenTriggerableStates.value
				,ExtractSuccessStates.value
				,ExtractMessageTypes.value 
			FROM 
				string_split(@PayerBenTriggerableStates,',') PayerBenTriggerableStates
			CROSS APPLY 
				(
					SELECT 
						value 
					FROM 
						string_split(@ExtractSuccessStates,',') 
					WHERE 
						value != ''
				) ExtractSuccessStates
			CROSS APPLY 
				(
					SELECT 
						value 
					FROM 
						string_split(@ExtractMessageTypes,',') 
					WHERE 
						value != ''
				) ExtractMessageTypes
			WHERE 
				PayerBenTriggerableStates.value != '';

			CREATE TABLE #itemsNotSentToBank
			(
				CollectorState SMALLINT,
				ExtractedState SMALLINT
			)
			INSERT INTO 
				#itemsNotSentToBank
			SELECT 
				PayerBenTriggerableStates.value
				,SentToBankCDFailurePostingStates.value 
			FROM 
				string_split(@PayerBenTriggerableStates,',') PayerBenTriggerableStates
			CROSS APPLY 
				(
					SELECT 
						value 
					FROM 
						string_split(@SentToBankCDFailurePostingStates,',') 
					WHERE 
						value != ''
				) SentToBankCDFailurePostingStates
			WHERE 
				PayerBenTriggerableStates.value != '';

			CREATE TABLE #itemsSentToBankNotArchv
			(
				CollectorState SMALLINT,
				ExtractedState SMALLINT
			)
			INSERT INTO 
				#itemsSentToBankNotArchv
			SELECT 
				PayerBenTriggerableStates.value
				,SentToBankSuccessPostingStates.value 
			FROM 
				string_split(@PayerBenTriggerableStates,',') PayerBenTriggerableStates
			CROSS APPLY 
				(
					SELECT 
						value 
					FROM 
						string_split(@SentToBankSuccessPostingStates,',') 
					WHERE 
						value != ''
				UNION ALL
					SELECT 
						value 
					FROM 
						string_split(@SentToBankOtherFailurePostingStates,',') 
					WHERE 
						value != ''
				) SentToBankSuccessPostingStates
			WHERE 
				PayerBenTriggerableStates.value != '';
		
			EXEC [Base].[usp_UpdatePostingEntityState] @ActivityID

			--Items not Triggered for beneficiary
			SELECT 
				@itemsNotTriggered = COUNT(1) 
			FROM 
				[Base].PostingEntryState
			WHERE 
			(
				Window2BusinessDate=@BusinessDate)
			AND 
				EXISTS	(
							SELECT 
								1 
							FROM 
								#NotTriggeredStates 
							WHERE 
								(
									PostingState  = RetriggerState --948
								OR 
									(PostingState IS NULL) 
								)	
							AND 
								ClearingState = CollectorState --exclude 06dm01 scenario
						)

			--payer 06dm01/06km01 case which triggers on day2

			SELECT 
				ItemID
				,TsetID
			INTO
				#CTE
			FROM  
				[Base].PostingEntryState  
			WHERE 
				EXISTS	(
							SELECT 
								1 
							FROM 
								#Day1TriggerStates 
							WHERE
								ClearingState = CollectorState --520
							AND 
								PostingState = ResponseState--970
						)
			AND 
				(
					Window1BusinessDate = @BusinessDate 
				OR 
					Window2BusinessDate = @BusinessDate
				)

			CREATE CLUSTERED INDEX ci_IID_TID ON #CTE(ItemID, TsetID)
			
			SELECT 
				@itemsNotTriggeredFor06DM01 = COUNT(1) 
			FROM 
				[Base].PostingEntryState ps
			INNER JOIN 
				#CTE cte
			ON
				cte.ItemID = ps.ItemID 
			AND 
				cte.TsetID = ps.TsetID
			WHERE 
				(
					Window1BusinessDate = @BusinessDate 
				OR 
					Window2BusinessDate = @BusinessDate
				)
			AND 
				EXISTS
					(
						SELECT 
							1 
						FROM 
							#itemsNotTriggeredFor06DM01 
						WHERE
							ClearingState = CollectorState -- 560,561
						AND 
							(
								PostingState IS NULL	 
							OR 
								PostingState = RetriggerState
							)
					)--948
			
			SELECT 
				@PostingRolloverItemsNotTriggered = COUNT(1) 
			FROM 
				[Base].PostingEntryState
			WHERE  
				Window2BusinessDate = @BusinessDate			
			AND 
				ClearingState = @PostingRollOverES
			AND 
				EXISTS	(
							SELECT 
								1 
							FROM 
								#PostingRolloverItemsNotTriggeredStates 
							WHERE
								(
									PostingState IS NULL 
								OR 
									PostingState = FailureState
								)
						)--957,958
			
			SET @itemsNotTriggered = @itemsNotTriggered + @itemsNotTriggeredFor06DM01 + @PostingRolloverItemsNotTriggered
				       
			IF @itemsNotTriggered=0 
			BEGIN

				--Items not extracted (PERM01)

				SELECT 
					@itemsNotExtracted = COUNT(1) 
				FROM 
					Base.PostingEntryState
				WHERE
					(
						Window2BusinessDate = @BusinessDate
					)
				AND 
					EXISTS	(
								SELECT 
									1 
								FROM 
									#itemsNotExtracted 
								WHERE 
									PostingState = NotExtractedState --945							
								AND 
									ClearingState = CollectorState
							)

				IF @itemsNotExtracted=0
					BEGIN
						--Items not Archived(PEMA01)
						SELECT 
							@itemsNotArchived = COUNT(1) 
						FROM 
							Base.PostingEntryState
						WHERE 
							(	
								Window2BusinessDate = @BusinessDate
							)
						AND 
							EXISTS	(
										SELECT 
											1 
										FROM 
											#itemsNotArchived 
										WHERE
											InternalMessageType != MessageType --PEMA01
										AND 
											PostingState = ExtractedState  --950,949,975  
										AND 
											ClearingState = CollectorState
									)

						IF @itemsNotArchived = 0
							BEGIN	
									--Items for which PSRM01 is not Received
									SELECT 
										@itemNotReceivedPSRM01 = COUNT(1) 
									FROM 
										Base.PostingEntryState
									WHERE 
										Window2BusinessDate = @BusinessDate
									AND 
										EXISTS	(
													SELECT 
														1 
													FROM 
														#itemsNotReceived 
													WHERE
														InternalMessageType  = MessageType --PEMA01
													AND 
														PostingState = ExtractedState  --950
													AND 
														ClearingState = CollectorState
												)

									IF(@itemNotReceivedPSRM01 = 0)
									BEGIN
										--Items which were not sent ot bank
										SELECT 
											@itemsNotSentToBank = COUNT(1) 
										FROM 
											Base.PostingEntryState
										WHERE 
											Window2BusinessDate = @BusinessDate 
										AND 
											EXISTS	(
														SELECT 
															1 
														FROM 
															#itemsNotSentToBank 
														WHERE
															PostingState = ExtractedState  --in 956
														AND 
															ClearingState = CollectorState
													)

										IF @itemsNotSentToBank = 0
										BEGIN

											SELECT 
												@itemsSentToBankNotArchv = COUNT(1) 
											FROM 
												Base.PostingEntryState
											WHERE 
												Window2BusinessDate = @BusinessDate 
											AND 
												InternalMessageType != 'PSMA01'
											AND 
												EXISTS	(
															SELECT 
																1 
															FROM 
																#itemsSentToBankNotArchv 
															WHERE
																PostingState = ExtractedState --in 955,957,958
															AND 
																ClearingState = CollectorState
														)
												
											IF @itemsSentToBankNotArchv =0
												BEGIN
													SET @decision=1							
												END
											ELSE
												BEGIN
													SET @decision = 0;
													SET @message= SUBSTRING(@message + CAST(@itemsSentToBankNotArchv AS VARCHAR(20))
														+ ' item(s) was/were sent to bank for payer/ben were not archived.', 1, 500);
												END
										END
										ELSE 
										BEGIN 
											SET @decision = 0;
											SET @message= SUBSTRING(@message + CAST(@itemsNotSentToBank AS VARCHAR(20))
												+ ' item(s) was/were extracted but not sent to bank for payer/ben.', 1, 500);
										END
									END
									ELSE
									BEGIN 
										SET @decision = 0;
										SET @message= SUBSTRING(@message + CAST(@itemNotReceivedPSRM01 AS VARCHAR(20))
                                         + ' item(s) was/were extracted but PSRM01 not received for payer/ben.', 1, 500);
									END
							END
							ELSE
								BEGIN
									SET @decision = 0;
									SET @message= SUBSTRING(@message + CAST(@itemsNotArchived AS VARCHAR(20))
                                         + ' item(s) was/were extracted but not archived.', 1, 500);
			
								END
					END
				ELSE
					BEGIN
							SET @decision = 0;
							SET @message= SUBSTRING(@message + CAST(@itemsNotExtracted AS VARCHAR(20))
                                        + ' item(s) have/has not been extracted.', 1, 500);
			
					END
				END
			ELSE 
				BEGIN
					SET @decision = 0;
					SET @message= SUBSTRING(@message + CAST((@itemsNotTriggered)AS VARCHAR(20))
                                        + ' item(s) have/has not been triggered for postings.', 1, 500);
				END

			IF (@decision = 1)
                BEGIN
                    SET @Result = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigValue('EOD', 'SuccessCode');
                    SET @message
                        = SUBSTRING('EOD - MO Posting extract reconciliation process for payer/beneficiary completed successfully.', 1, 500);
                    SET @severity = 1;
                    SET @Sysout = '';
                END;
            ELSE
                BEGIN
                    SET @Result = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigValue('EOD', 'FailureCode');
                    SET @errorCode = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigValue('EOD', @ReconStage);
                    SET @severity = 3;
                    SET @message
                        = SUBSTRING(
                                       '[MOException] EOD - MO Posting Extract reconciliation process for payer/beneficiary failed.'
                                       + @message, 1, 500
                                   );
                    SET @Sysout = @errorCode + ':' + @message;
                END;
				
			EXEC [Logging].usp_LogAndAudit
            @ActivityID,
            @UserName,
            @errorCode,
            @severity,
            @Source,
            @message,
            NULL;		

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            DECLARE @ErrorMessage NVARCHAR(4000);
            DECLARE @ErrorSeverity INT;
            DECLARE @ErrorState INT;
            DECLARE @ErrorLine INT;
            SET @Result = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigValue('EOD', 'FailureCode');

            
            SELECT
                @ErrorSeverity = ERROR_SEVERITY(),
                @ErrorState    = ERROR_STATE(),
                @ErrorLine     = ERROR_LINE(),
                @ErrorMessage  = ERROR_MESSAGE();
			SET @Sysout = CAST(@ErrorMessage AS VARCHAR);
            --If transaction fails, roll back insert			
            IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION;
            EXEC [Logging].[usp_LogError] null,@ActivityID;
            RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine);

        END CATCH;

        SET NOCOUNT OFF;
    END;
GO

EXEC [sys].[sp_addextendedproperty]
    @name = N'Component',
    @value = N'iPSL.ICS.MO.DB',
    @level0type = N'SCHEMA',
    @level0name = N'Base',
    @level1type = N'PROCEDURE',
    @level1name = N'usp_EOD_PayerBenReconPostingExtract';
GO
EXEC [sys].[sp_addextendedproperty]
    @name = N'MS_Description',
    @value = N'Caller: EOD SSIS
	Description:Stored Procedure to perform Reconciliation for beneficiary(msg 13) trigger and  extract details(PTMA01,PERM01,PEMA01) and items triggered for payer on day2.Triggered,Extracted and Archived items are checked for reconciliation',
    @level0type = N'SCHEMA',
    @level0name = N'Base',
    @level1type = N'PROCEDURE',
    @level1name = N'usp_EOD_PayerBenReconPostingExtract';
GO
EXEC [sys].[sp_addextendedproperty]
    @name = N'Version',
    @value = [$(Version)],
    @level0type = N'SCHEMA',
    @level0name = N'Base',
    @level1type = N'PROCEDURE',
    @level1name = N'usp_EOD_PayerBenReconPostingExtract';
GO
GRANT
    EXECUTE
    ON OBJECT::[Base].[usp_EOD_PayerBenReconPostingExtract]
    TO
    [ControlMRole]
    AS [dbo];
GO


