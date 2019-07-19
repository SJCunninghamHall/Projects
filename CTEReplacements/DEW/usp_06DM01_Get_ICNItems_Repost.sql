CREATE PROCEDURE [Process].[usp_06DM01_Get_ICNItems_Repost]
	@DebitItem			[Process].[tv_DebitSeq] READONLY,
	@tv_06MD_DebitInWorkstream_Param	[Process].[tv_DebitInWorkstream_Complete] READONLY,
	@CoreSeq			BIGINT,
	@BusinessDateSeq	BIGINT,
	@ProcessedId		VARCHAR(3)
AS
    BEGIN
        SET NOCOUNT ON;
		BEGIN TRY
				
			SELECT	
				[DI].[DebitSeq]
				,[TVDIW].UserSeq
				,ROW_NUMBER() OVER ( PARTITION BY [TVDIW].[DebitSeq] ORDER BY [TVDIW].[Priority] DESC) AS PriorityNumDESC
			INTO
				#DebitInWorkStream
			FROM
				@DebitItem	[DI] 
			INNER JOIN	
				@tv_06MD_DebitInWorkstream_Param [TVDIW]  
			ON 
				[DI].[DebitSeq]	= [TVDIW].[DebitSeq]					

			CREATE NONCLUSTERED INDEX 
				nci_DS_US_PND 
			ON 
				#DebitInWorkStream(DebitSeq, UserSeq, PriorityNumDESC)
			WHERE 
				PriorityNumDESC = 1

			SELECT 
				DebitSeq
				,UserSeq
			INTO
				#DebitInWorkStreamItem
			FROM 
				#DebitInWorkStream [DIW]
			WHERE 
				[DIW].PriorityNumDESC = 1
				
			CREATE NONCLUSTERED INDEX nci_ds ON #DebitInWorkStreamItem(DebitSeq, UserSeq)
			CREATE NONCLUSTERED INDEX nci_us ON #DebitInWorkStreamItem(UserSeq, DebitSeq)

            SELECT	
				@BusinessDateSeq
				+ CAST(NEXT VALUE FOR[Process].[sqn_06MD01_ICNItems] AS BIGINT)	[ICNItemSeq],
				@CoreSeq														[CoreSeq],
				[D].[DebitId]													[ItemId],
				@ProcessedId													[ProcessedId],
				[U].[UserName]													[OperatorId],
				GETDATE()														[UpdateDateTime],
				'true'															[PayDecision],
				NULL															[PayDecisionReasonCode]
			FROM	
				@DebitItem	[DI]
			INNER JOIN	
				[Process].[06MD_Debit] [D] WITH ( SNAPSHOT )	
			ON [D].DebitSeq	= [DI].DebitSeq
			INNER JOIN	
				#DebitInWorkStreamItem [TVDIW]	
			ON 
				[D].[DebitSeq] = [TVDIW].[DebitSeq]
			LEFT JOIN	
				[DataAccess].[User] [U]	WITH ( SNAPSHOT )	
			ON 
				[U].[UserSeq] = [TVDIW].[UserSeq]
			WHERE   
				[D].[IsActive] = 1			

        END TRY
        BEGIN CATCH
            THROW;
        END CATCH;
    END;

GO

EXEC [sys].[sp_addextendedproperty] @name = N'Component',
                                    @value = N'iPSL.iCE.DEW.Database',
                                    @level0type = N'SCHEMA',
                                    @level0name = N'Process',
                                    @level1type = N'PROCEDURE',
                                    @level1name = N'usp_06DM01_Get_ICNItems_Repost';
GO

EXEC [sys].[sp_addextendedproperty] @name = N'MS_Description',
                                    @value = N'
Description:	 This Stored Procedure get 06DM01 ICNItems Results data
Parameter Name						Type										Description
@DebitItem							[Process].[tv_DebitSeq]						Debit Items containing the DebitInWorkStreamId for Unapplied Report
@tv_06MD_DebitInWorkstream_Param	[Process].[tv_DebitInWorkstream_Complete]	@DebitItem item Information from DebitInWorkStream table
@CoreSeq							BIGINT										Core table Seq
@BusinessDateSeq					BIGINT										BusinessDateSeq 11 digit number with business date
@ProcessedId						VARCHAR(25)									Process Id (DEW)
',
                                    @level0type = N'SCHEMA',
                                    @level0name = N'Process',
                                    @level1type = N'PROCEDURE',
                                    @level1name = N'usp_06DM01_Get_ICNItems_Repost';
GO

EXEC [sys].[sp_addextendedproperty] @name = N'Version',
                                    @value = N'$(Version)',
                                    @level0type = N'SCHEMA',
                                    @level0name = N'Process',
                                    @level1type = N'PROCEDURE',
                                    @level1name = N'usp_06DM01_Get_ICNItems_Repost';
GO


