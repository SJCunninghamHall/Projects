CREATE PROCEDURE [DataAccess].[usp_DebitInWorkStream_GetNextItem]
   @UserId SMALLINT,
   @GroupId UNIQUEIDENTIFIER,
   @WorkstreamState_End TINYINT,
   @UserDecision_Fail TINYINT,
   @Process_ReferId TINYINT,
   @Process_VerifyId TINYINT,
   @Process_ApproveId TINYINT,
   @ResponseWindowsDatetime AS DATETIME2(0),
   @WorkstreamState_Decision TINYINT,
   @WorkGroupId BIGINT,
   @WorkstreamId BIGINT,
   @SubWorkstreamId BIGINT ,
   @ProcessId BIGINT,
   @CustomerSegmentId BIGINT, 
   @Process_WorkstreamStateId TINYINT,
   @Process_DecisionId TINYINT,
   @WorkItemId BIGINT OUTPUT,
   @AccountNumber INT OUTPUT,
   @AccountSortCode INT OUTPUT
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN TRY		

		SELECT	
			[PriorityWorkstream].[DebitSeq],
			[Priority],
			[StateSeq],
			[UserDecisionSeq]	-- is not in any other workstream that has not
		INTO
			#PriorityWorkstream
		FROM
			[Process].[DebitInWorkstream] AS [PriorityWorkstream]  WITH(SNAPSHOT) --  been worked to workstreamstate of end of
		INNER JOIN 
			[Process].[06MD_Debit] [D] WITH(SNAPSHOT)
		ON 
			[D].[DebitSeq] = [PriorityWorkstream].[DebitSeq]
		WHERE
			[D].[DayTwoRspnWndwEndDtTm] = @ResponseWindowsDatetime	

		CREATE CLUSTERED INDEX ci_DS_P_SS ON #PriorityWorkstream(DebitSeq, Priority, StateSeq)
		CREATE NONCLSUTERED INDEX nci_DS_SS ON #PriorityWorkstream(DebitSeq, StateSeq)

		-------------------------------------------------------------------------------------------------------------------------------------------------

		SELECT TOP (1) 
			[DIW].[DebitInWorkstreamSeq],
			[D].[AccountNumber],
			[D].[Sortcode]
		INTO
			#SelectItem
		FROM 
			[Process].[DebitInWorkstream] AS [DIW] WITH(SNAPSHOT)
		INNER JOIN 
			[Process].[06MD_Debit] [D] WITH(SNAPSHOT)
		ON 
			[D].[DebitSeq] = [DIW].[DebitSeq] 
		AND 
			[D].[DayTwoRspnWndwEndDtTm]= @ResponseWindowsDatetime
		INNER JOIN 
			[Process].[06MD_Debit_State] [DS] WITH(SNAPSHOT)
		ON 
			[DS].[DebitSeq] = [D].[DebitSeq]
		AND 
			(
				[DS].[FinalDecisionApplied] IS NULL 
			OR  
				[DS].[FinalDecisionApplied] = 0 
			OR 
				[DS].UserDecisionSeq IS NULL
			) 
		LEFT JOIN 
			[Process].[DebitInWorkstreamAudit] [DIWA] WITH(SNAPSHOT)       -- check in the audit table if the user has worked previously on this item
		ON 
			[DIWA].[DebitInWorkstreamSeq] = [DIW].[DebitInWorkstreamSeq]
		AND 
			[DIWA].[UserSeq] = @UserId
		AND 
			(
				[DIW].[StateSeq] < @WorkstreamState_End
			OR 
				[DIW].[StateSeq] > @WorkstreamState_End
			)
		AND 
			(
				[DIW].[StateSeq] < @Process_ReferId
			OR 
				[DIW].[StateSeq] > @Process_ReferId
			)
		AND 
			[DIWA].UserDecisionSeq IS NOT NULL
		LEFT JOIN 
			#PriorityWorkstream AS [PriorityWorkstream]
		ON	
			[PriorityWorkstream].[DebitSeq] = [DIW].[DebitSeq]									 						
		AND 
			(	--  higher priority workstream 
				[PriorityWorkstream].[Priority] < [DIW].[Priority] -- Not indexed
			
				-- Logic for unapplied and stops. if the item is being work on lower priority workstream  
				--	and a new posting file is loaded with unapplied (higher priority workstream)
			OR 
				(
					[PriorityWorkstream].[StateSeq] = @Process_ReferId 
				OR 
					[PriorityWorkstream].[StateSeq] = @Process_VerifyId  
				OR 
					[PriorityWorkstream].[StateSeq] = @Process_ApproveId												   
				)
			)
		AND 
			[DIW].[StateSeq] = @WorkstreamState_Decision     
		AND 
			(  	-- item not in End state
				[PriorityWorkstream].[StateSeq] < @WorkstreamState_End 
			OR 
				[PriorityWorkstream].[StateSeq] > @WorkstreamState_End
			)
		WHERE	
			[DIW].[UserSeq] IS NULL													-- not owned by a user
		AND 
			[DIW].[WorkGroupSeq] = @WorkGroupId										-- in the workgroup
		AND 
			[DIW].[WorkstreamSeq] = @WorkstreamId									-- in the workstream
		AND 
			(																		-- Sub workstream, if any						
				(
					[DIW].[SubWorkstreamSeq] IS NULL 
				AND 
					@SubWorkstreamId IS NULL
				)
			OR 
				[DIW].[SubWorkstreamSeq] = @SubWorkstreamId
			)
		AND 
			[DIW].[StateSeq] = @Process_WorkstreamStateId							-- at the work stream state
		AND 
			(																		-- customer segment, if any
				@CustomerSegmentId = 0
			OR 
				(
					(
						[DS].[CustomerSegmentSeq] IS NULL 
					AND 
						@CustomerSegmentId IS NULL
					)
				OR 
					[DS].[CustomerSegmentSeq] = @CustomerSegmentId
				)                             
			)
		AND 
			(																		-- operator has preiousky not worked on the item
				[DIWA].[DebitInWorkstreamSeq] IS NULL						        
			OR 
				(
					[DIW].[StateSeq] = @Process_ReferId
				)
			)

		AND 
			[PriorityWorkstream].[DebitSeq] IS NULL
		ORDER BY 
			CASE
				WHEN @ProcessId = @Process_DecisionId 
				THEN [Amount]		-- if workstreamstate is Decision order by
			END DESC,				--  Amount DESC
			CASE
				WHEN @ProcessId <> @Process_DecisionId 
				THEN [DIW].[TimeStamp]	-- if workstreamstate is not Decision order by
			END ASC

		----------------------------------------------------------------------------------------------------------------------------

		UPDATE  
			[DIW]
		SET 	
			@WorkItemId = [DIW].[DebitInWorkstreamSeq],
			@AccountNumber = [SelectItem].[AccountNumber],
			@AccountSortCode =[SelectItem].[Sortcode],
			[UserSeq] = @UserId,
			[GroupSeq] = @GroupId,
			[TimeStamp] = GETDATE()
		FROM	
			[Process].[DebitInWorkstream] AS [DIW] WITH(SNAPSHOT)
		INNER JOIN 
			#SelectItem AS [SelectItem] 
		ON 
			[SelectItem].DebitInWorkstreamSeq = [DIW].[DebitInWorkstreamSeq]

		----------------------------------------------------------------------------------------------------------------------------

	END TRY
    BEGIN CATCH
        -- Log the error information
        DECLARE @ErrorMessage VARCHAR(4000) = ERROR_MESSAGE();
        EXECUTE [Base].[usp_LogException] @ErrorMessage;
        THROW;
    END CATCH;
END;
GO
EXEC [sys].[sp_addextendedproperty] @name = N'Component',
                                    @value = N'iPSL.iCE.DEW.Database',
                                    @level0type = N'SCHEMA',
                                    @level0name = N'DataAccess',
                                    @level1type = N'PROCEDURE',
                                    @level1name = N'usp_DebitInWorkStream_GetNextItem';
GO
EXEC [sys].[sp_addextendedproperty] @name = N'MS_Description',
                                    @value = N'
Description		: This Child Procedure will get the next item from [Process].[DebitInWorkstream] based on parameters and update the value for processed cheque.
Parameter Name				Type							Description
@UserId						SMALLINT						User ID
@GroupId					UNIQUEIDENTIFIER				UNIQUEIDENTIFIER
@WorkstreamState_End		TINYINT							End Workstream State
@UserDecision_Fail			TINYINT							User Fail Decision Seq
@Process_ReferId			TINYINT							Process Refer Id
@ResponseWindowsDatetime	DATETIME2(0)					Day2 Response Windows Datetime
@WorkstreamState_Decision	TINYINT							Decision Workstream State
@WorkGroupId				BIGINT							WorkGroupId
@WorkstreamId				BIGINT							WorkstreamId
@SubWorkstreamId			BIGINT							SubWorkstreamId
@ProcessId					BIGINT							ProcessId
@CustomerSegmentId			BIGINT							CustomerSegmentId	
@Process_WorkstreamStateId  TINYINT							Process Workstream State Id
@Process_DecisionId			TINYINT							Process Decision Id	
@WorkItemId					BIGINT							WorkItemId	
@AccountNumber				INT								AccountNumber
@AccountSortCode			INT								AccountSortCode
@RowCount					INT								Update RowCount
',
                                    @level0type = N'SCHEMA',
                                    @level0name = N'DataAccess',
                                    @level1type = N'PROCEDURE',
                                    @level1name = N'usp_DebitInWorkStream_GetNextItem';
GO
EXEC [sys].[sp_addextendedproperty] @name = N'Version',
                                    @value = N'$(Version)',
                                    @level0type = N'SCHEMA',
                                    @level0name = N'DataAccess',
                                    @level1type = N'PROCEDURE',
                                    @level1name = N'usp_DebitInWorkStream_GetNextItem';
GO

GRANT EXECUTE
ON OBJECT::[DataAccess].[usp_DebitInWorkStream_GetNextItem]
TO  [WebAccess]
AS [dbo];
GO