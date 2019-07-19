CREATE PROCEDURE [Base].[usp_Fwk_WriteDataForSendLogger]
(
	@messageType CHAR(6),
	@ActivityId VARCHAR(60),
	@Source [Base].[udt_Source] READONLY,
	@TransactionSet [Base].[udt_TransactionSet] READONLY,
	@Item [Base].[udt_Item] READONLY,
	@ItemState [Base].[udt_ItemState] READONLY,
	@PreviousState [Base].[udt_WithTwoStringColumns] READONLY,
	@FileName VARCHAR(100),
	@IdsList [Base].[udt_WithTwoStringColumns] READONLY,
	@TransactionSetState [Base].[udt_TransactionSetState] READONLY
)
/*****************************************************************************************************
* Name				: [Base].[usp_Fwk_WriteDataForSendLogger]
* Description		: Stored Procedure to save data into the MO database for Send Logger pattern.
It will insert/update data into Source, Item, TransactionSet tables and EntityPostingState
* Type of Procedure : User-defined stored procedure
* Author			: Sabarish Jayaraman
* Creation Date		: 26-Apr-2017
* Last Modified		: Rahul
* Parameters		:
*******************************************************************************************************
*Parameter Name				Type				Description
*------------------------------------------------------------------------------------------------------
@messageType				 CHAR(6)									Workflow name
@ActivityId					 VARCHAR(60)								Activity Id for logging table
@Source				         [Base].[udt_Source]						Source table data to be inserted
@TransactionSet			     [Base].[udt_TransactionSet]				TransactionSet table data to be upserted
@Item				         [Base].[udt_Item]							Item table data to be upserted
@ItemState			         [Base].[udt_ItemState]						Itemstate table data to be upserted
@PreviousState				 [Base].[udt_WithTwoStringColumns]          Previous states
@FileName					 VARCHAR(100)								File name
@TransactionSetState		 [Base].[udt_TransactionSetState]			TransactionSetState table data to be upserted
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************
*										History
*------------------------------------------------------------------------------------------------------
* Version	ID		Date			Reason
*******************************************************************************************************
* 1.0.0		001     26-Apr-2017   	Initial version
* 1.0.1		002		23-May-2017		Changed the state picking logic for Posting message
* 1.0.2		003		24-Jul-2017		Added logic to update Item table state from passed ItemState entry
* 1.0.3		004		30-Oct-2017 	Added new logic related to UpdatedDateTime Based on Role
* 1.0.4		005		16-Jan-2018		Added ItemType column in ItemState UDT
* 1.0.5		006		25-Jun-2018		Corrected ItemState Udt Insertion
* 1.0.6 	007		09-Aug-2018		Added fix for duplicate update of sourceid in ADJ posting by adding ParentSourceId
* 1.0.7		008		04-Sep-2018		Restructured PES table update to be on SKID
* 1.0.8		009		07-Jan-2019		Added PostingState condition with PostingCreatedState
* 1.0.9		004     08-Apr-2019		Populated @item with Window2BusinessDate #200277 
*******************************************************************************************************/
AS
DECLARE  
	@participantType VARCHAR(15),  
	@PayloadLevel VARCHAR(255),
	@IsQueueBased BIT,
	@ExternalMsgType CHAR(5),
	@DestinationSubSystem VARCHAR(20)
BEGIN

SET NOCOUNT ON;

SET XACT_ABORT ON;

BEGIN TRY

	DECLARE @sourceSkId BIGINT
	DECLARE @CurrentDate DATETIME
	DECLARE @EntityStateForCMCM01 VARCHAR(10) = [$(MoConfigDatabase)].[Config].sfn_ReadScalarConfigEAVValue('CMPaidDecision', 'CMCM01');
	DECLARE @PayloadCreatedState VARCHAR(10) = [$(MoConfigDatabase)].[Config].sfn_ReadScalarConfigEAVValue('PostingStates','PTMAPayloadCreated');
	DECLARE @IsWebAPIBased VARCHAR(50) = [$(MoConfigDatabase)].[Config].sfn_ReadScalarConfigEAVValue('Postings','WebAPIBasedMessages');

	EXEC Base.usp_GetCurrentDateTime @CurrentDate OUTPUT;
	-- If the file name is not provided then it is queue based system. Update the state to intermediate in  that case
	IF (@FileName IS NULL) 
	BEGIN
		SET @IsQueueBased = 1
	END
	ELSE
	BEGIN
		SET @IsQueueBased = 0
	END
	IF(CHARINDEX(@messageType ,@IsWebAPIBased) > 0)
	BEGIN 
		SET @IsQueueBased = 0
	END
	--Get the batch size,participant type and system  type for the message type from messageParameter table  
	SELECT   
		@participantType=ParticipantRole,  
		@PayloadLevel = PayloadLevelIndicator,
		@ExternalMsgType=ExternalMessageID,
		@DestinationSubSystem=DestinationSubsystem
	FROM 
		[$(MoConfigDatabase)].[Config].[tfn_ReadMessageParameters](@messageType)  
	
	-- Create copy of transactionset into a table variable
	DECLARE @CopyTransactionSet [Base].[udt_TransactionSet]

	INSERT INTO
		@CopyTransactionSet
		(
			TsetID
			,ISOContent
			,SourceSKID
			,OperationType
			,NodeType
			,InternalMessageType
			,[State]
			,StateRevision
		)
		SELECT 
			tSet.TsetID
			,tSet.ISOContent
			,tset.SourceSKID
			,tSet.OperationType
			,tSet.NodeType
			,tset.InternalMessageType
			,tSet.[State]
			,tSet.StateRevision
		FROM 
			@TransactionSet tSet
	
	-- Delete duplicate TSet Records
	;WITH CTE AS (
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY TsetID ORDER BY (SELECT 0)) RowNumber 
		FROM 
			@CopyTransactionSet
	)
	DELETE FROM 
		CTE
	WHERE 
		RowNumber > 1;	

	-- Create copy of ItemState into a table variable and select only the items having correct state transitions.
	DECLARE @CopyItemState [Base].[udt_ItemState]

	INSERT INTO 
		@CopyItemState
		(
			[CollectorRoleFlag]
			,[PayerRoleFlag]
			,[BeneficiaryRoleFlag]
			,[CollectorItemState]
			,[PayerItemState]
			,[BeneficiaryItemState]
			,[CollectorItemDirtyFlag]
			,[PayerItemDirtyFlag]
			,[BeneficiaryItemDirtyFlag]
			,[CollectorItemBatchedFlag]
			,[PayerItemBatchedFlag]
			,[BeneficiaryItemBatchedFlag]
			,[ItemID]
			,[OperationType]
			,[Gender]
			,[TsetID]
			,[CollectorSourceDateTime]
			,[PayerSourceDateTime]
			,[BeneficiarySourceDateTime]
			,[Window1BusinessDate]
			,[Window2BusinessDate]
			,[AlwaysUpdateWindowDates]
			,[PayerUpdatedDatetime]
			,[BeneficiaryUpdatedDatetime]
			,[CollectorUpdatedDatetime]
			,[ItemType]
			,[MSG06Flag]
			,[MSG13Flag]
			,[IcsAmount]
			,[RowId]
		)
		SELECT 
			itemStateInput.[CollectorRoleFlag]
			,itemStateInput.[PayerRoleFlag]
			,itemStateInput.[BeneficiaryRoleFlag]
			,itemStateInput.[CollectorItemState]
			,itemStateInput.[PayerItemState]
			,itemStateInput.[BeneficiaryItemState]
			,itemStateInput.[CollectorItemDirtyFlag]
			,itemStateInput.[PayerItemDirtyFlag]
			,itemStateInput.[BeneficiaryItemDirtyFlag]
			,itemStateInput.[CollectorItemBatchedFlag]
			,itemStateInput.[PayerItemBatchedFlag]
			,itemStateInput.[BeneficiaryItemBatchedFlag]
			,itemStateInput.[ItemID],itemStateInput.[OperationType]
			,itemStateInput.[Gender]
			,itemStateInput.[TsetID]
			,itemStateInput.[CollectorSourceDateTime]
			,itemStateInput.[PayerSourceDateTime]
			,itemStateInput.[BeneficiarySourceDateTime] 
			,itemStateInput.[Window1BusinessDate]
			,itemStateInput.[Window2BusinessDate]
			,itemStateInput.[AlwaysUpdateWindowDates]
			,itemStateInput.[PayerUpdatedDatetime]
			,itemStateInput.[BeneficiaryUpdatedDatetime]
			,itemStateInput.[CollectorUpdatedDatetime]
			,itemStateInput.[ItemType]
			,itemStateInput.[MSG06Flag]
			,itemStateInput.[MSG13Flag]
			,itemStateInput.[IcsAmount]
			,itemStateInput.[RowId]
		FROM 
			@ItemState itemStateInput
		LEFT OUTER JOIN 
			[Base].ItemState 
		ON 
			[Base].ItemState.ItemID = itemStateInput.ItemID 
		WHERE	
			(
				itemStateInput.PayerItemState IS NOT NULL 
			AND 
				[Base].ItemState.PayerItemState IN	(
														SELECT 
															StringColumnB 
														FROM 
															@PreviousState 
														WHERE 
															StringColumnA = itemState.Gender
													)
			) 
		OR
			(
				itemStateInput.CollectorItemState IS NOT NULL 
			AND 
				[Base].ItemState.CollectorItemState IN	(
															SELECT 
																StringColumnB 
															FROM 
																@PreviousState  
															WHERE 
																StringColumnA = itemState.Gender
														)
			) 
		OR
			(
				itemStateInput.BeneficiaryItemState IS NOT NULL 
			AND 
				[Base].ItemState.BeneficiaryItemState IN	(
																SELECT 
																	StringColumnB 
																FROM 
																	@PreviousState  
																WHERE 
																	StringColumnA = itemState.Gender
															)
			)
		OR 
			NOT EXISTS	(
							SELECT 
								StringColumnB 
							FROM 
								@PreviousState  
							WHERE 
								StringColumnA = itemState.Gender
						)
	
	-- Delete duplicate Item Records
	;WITH CTE AS (
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY ItemID ORDER BY (SELECT 0)) RowNumber 
		FROM 
			@CopyItemState
	)
	DELETE FROM 
		CTE
	WHERE 
		RowNumber > 1;

	--Update the UpdatedDatetime based on Role
	UPDATE 
		@CopyItemState
	SET 
		PayerUpdatedDatetime = 	CASE
									WHEN PayerRoleFlag =1
									THEN @CurrentDate 
									ELSE PayerUpdatedDatetime
								END,
	BeneficiaryUpdatedDatetime = 	CASE
										WHEN BeneficiaryRoleFlag =1
										THEN @CurrentDate 
										ELSE BeneficiaryUpdatedDatetime
									END,
	CollectorUpdatedDatetime = 	CASE
									WHEN CollectorRoleFlag =1
									THEN @CurrentDate 
									ELSE CollectorUpdatedDatetime
								END

	-- Select only the transactions with correct state transition

	DECLARE 
		@CopyTransactionSetState [Base].[udt_TransactionSetState]
	INSERT INTO 
		@CopyTransactionSetState
	SELECT 
		transactionSetStateInput.[CollectorRoleFlag]
		,transactionSetStateInput.[CollectorTsetState]
		,transactionSetStateInput.[CollectorTsetDirtyFlag]
		,transactionSetStateInput.[CollectorTsetBatchedFlag]
		,transactionSetStateInput.[PayerRoleFlag]
		,transactionSetStateInput.[PayerTsetState]
		,transactionSetStateInput.[PayerTsetDirtyFlag]
		,transactionSetStateInput.[PayerTsetBatchedFlag]
		,transactionSetStateInput.[BeneficiaryRoleFlag]
		,transactionSetStateInput.[BeneficiaryTsetState]
		,transactionSetStateInput.[BeneficiaryTsetDirtyFlag]
		,transactionSetStateInput.[BeneficiaryTsetBatchedFlag]
		,transactionSetStateInput.[TsetID]
		,transactionSetStateInput.[OperationType]
		,transactionSetStateInput.[CollectorSourceDateTime]
		,transactionSetStateInput.[PayerSourceDateTime]
		,transactionSetStateInput.[BeneficiarySourceDateTime]
		,transactionSetStateInput.[Window1BusinessDate]
		,transactionSetStateInput.[Window2BusinessDate]
		,transactionSetStateInput.[NewTsetID] 
		,transactionSetStateInput.[PayerUpdatedDatetime]
		,transactionSetStateInput.[BeneficiaryUpdatedDatetime]
		,transactionSetStateInput.[CollectorUpdatedDatetime]
		,transactionSetStateInput.[RowId] 
	FROM 
		@TransactionSetState transactionSetStateInput
	LEFT JOIN 
		[Base].TransactionSetState transactionSetState
	ON 
		transactionSetState.TsetID = transactionSetStateInput.TsetID 
	WHERE 
		(
			transactionSetStateInput.PayerTsetState IS NOT NULL 
		AND 
			transactionSetState.PayerTsetState IN	(
														SELECT 
															StringColumnB 
														FROM 
															@PreviousState 
														WHERE 
															StringColumnA = 2
													)
		) 
	OR
		(
			transactionSetStateInput.CollectorTsetState IS NOT NULL 
		AND 
			transactionSetState.CollectorTsetState IN	(
															SELECT 
																StringColumnB 
															FROM 
																@PreviousState 
															WHERE 
																StringColumnA  = 2
														)
		) 
	OR
		(
			transactionSetStateInput.BeneficiaryTsetState  IS NOT NULL 
		AND 
			transactionSetState.BeneficiaryTsetState IN	(
															SELECT 
																StringColumnB 
															FROM 
																@PreviousState 
															WHERE 
																StringColumnA  = 2
														)
		)
	OR 
		NOT EXISTS	(
						SELECT 
							StringColumnB 
						FROM 
							@PreviousState 
						WHERE 
							StringColumnA  = 2
					)

	;WITH CTE AS 
	(
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY TsetID ORDER BY (SELECT 0)) RowNumber 
		FROM 
			@CopyTransactionSetState
	)

	DELETE FROM 
		CTE
	WHERE 
		RowNumber > 1;

	--Update the UpdatedDatetime based on Role

	UPDATE 
		@CopyTransactionSetState
	SET 
		PayerUpdatedDatetime = 	CASE
									WHEN PayerRoleFlag =1
									THEN @CurrentDate 
									ELSE PayerUpdatedDatetime
								END,
	  BeneficiaryUpdatedDatetime = 	CASE
										WHEN BeneficiaryRoleFlag =1
										THEN @CurrentDate 
										ELSE BeneficiaryUpdatedDatetime
									END,
	   CollectorUpdatedDatetime = 	CASE
										WHEN CollectorRoleFlag =1
										THEN @CurrentDate 
										ELSE CollectorUpdatedDatetime
									END

	-- Create copy of item into a table variable
	DECLARE @CopyItem [Base].[udt_Item]

	INSERT INTO 
		@CopyItem
	SELECT 
		item.ISOContent,
		item.ICNContent,
		item.ItemID,
		item.SourceSKID,
		item.TsetID,
		item.OperationType,
		item.NodeType,
		item.InternalMessageType,
		item.[State],
		item.[StateRevision],
		item.[Window2BusinessDate]
	FROM 
		@Item item
	
	-- Delete duplicate Itemstate records
	;WITH CTE AS (
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY ItemID, NodeType ORDER BY (SELECT 0)) RowNumber 
		FROM 
			@CopyItem
	)
	DELETE FROM 
		CTE
	WHERE 
		RowNumber > 1;

	-- Get TransactionSetId and state for all the items from the Item table
	UPDATE 
		@CopyItem
	SET 
		TsetID = sta.TsetID,
		Window2BusinessDate = sta.Window2BusinessDate,
		State =	CASE 
					WHEN @participantType = 'Payer' AND copyItem.[State] IS NULL 
					THEN sta.PayerItemState
					WHEN @participantType = 'Collector' AND copyItem.[State] IS NULL 
					THEN sta.CollectorItemState
					WHEN @participantType = 'Beneficiary' AND copyItem.[State] IS NULL 
					THEN sta.BeneficiaryItemState
					WHEN @participantType = 'ALL' 
					THEN copyItem.State 
					WHEN @participantType = 'Holdover' 
					THEN copyItem.State
					ELSE copyItem.[State]
				END
	FROM 
		[Base].ItemState sta
	INNER JOIN 
		@CopyItem copyItem
	ON 
		sta.ItemID = copyItem.ItemID

	-- Update State when set in the ItemState variable
	UPDATE 
		@CopyItem
	SET State =	CASE 
					WHEN @participantType = 'Payer' AND sta.PayerItemState IS NOT NULL 
					THEN sta.PayerItemState
					WHEN @participantType = 'Collector' AND sta.CollectorItemState IS NOT NULL 
					THEN sta.CollectorItemState
					WHEN @participantType = 'Beneficiary' AND sta.BeneficiaryItemState IS NOT NULL 
					THEN sta.BeneficiaryItemState
					WHEN @participantType = 'ALL' AND copyItem.State IS NOT NULL 
					THEN copyItem.State 
					WHEN @participantType = 'Holdover' AND copyItem.State IS NOT NULL 
					THEN copyItem.State
				END
	FROM 
		@CopyItemState sta
	INNER JOIN 
		@CopyItem copyItem
	ON 
		sta.ItemID = copyItem.ItemID
     
    --Code to update EntityPostingState table
	DECLARE @EntityPostingState [Base].[udt_PostingEntryState]

	IF (@ExternalMsgType='PSTNG' AND @DestinationSubSystem IN ('DEW','IA')	)
		BEGIN	

			DECLARE @SourceId VARCHAR(100);

		    SELECT 
				@SourceId=SourceID 
			FROM 
				@Source;			

			IF(@messageType='PTMA01' )
				BEGIN					
					INSERT INTO 
						@EntityPostingState
						(
							SourceID
							,ItemID
							,InternalMessageType
							,PostingState
							,OperationType
							,RowId
							,PostingEntryStateSKID
						)  
					SELECT 
						@SourceId
						,'NULL'
						,@messageType
						,945
						,1
						,ROW_NUMBER() OVER(ORDER BY (SELECT 0)) as 'RowId'
						,pes.PostingEntryStateSKID 
					FROM 
						Base.PostingEntryState pes 
					INNER JOIN 
						@CopyItem cpy 
					ON 
						pes.ItemID = cpy.ItemID 
					AND 
						pes.ClearingState = cpy.[State] 
					AND 
						pes.PostingState = @PayloadCreatedState
					AND 
						pes.TsetID = cpy.TsetID
				END
			ELSE IF (@messageType ='POTMA1')
				BEGIN
					INSERT INTO 
						@EntityPostingState
							(
								SourceID
								,[ItemID]
								,TsetID
								,InternalMessageType
								,ClearingState
								,PostingState
								,OperationType
								,RowId
								,PostingEntryStateSKID
							)  
					SELECT 
						@SourceId
						,'NULL'
						,tset.[TsetID]
						,@messageType
						,tset.[State]
						,945
						,1
						,ROW_NUMBER() OVER(ORDER BY (SELECT 0)) as 'RowId'
						,pes.PostingEntryStateSKID 
					FROM
						Base.PostingEntryState pes 
					INNER JOIN 
						@CopyTransactionSet tset 
					ON 
						pes.TsetID = tset.TsetID 
					AND 
						pes.ClearingState = tset.[State] 
					AND 
						pes.PostingState = @PayloadCreatedState
				END	

			-- Modified condition for PEMA02 to fix duplicate sourceid update happening in ADJ posting
			ELSE IF(@messageType='PEMA01' OR @messageType ='POEMA1' OR @messageType = 'PEMA02' OR @messageType = 'PSMA01')
				BEGIN
					DECLARE @ParentSourceIds VARCHAR(100)
					SELECT @ParentSourceIds =  CAST(il.StringColumnB AS VARCHAR(100)) FROM @IdsList  il WHERE il.StringColumnA = 'Document';
					
					INSERT INTO 
						@EntityPostingState
							(
								SourceID
								,ItemID
								,InternalMessageType
								,OperationType
								,RowId
								,PostingEntryStateSKID
							)					
					SELECT 
						@SourceId
						,'NULL'
						,@messageType
						,1
						,ROW_NUMBER() OVER(ORDER BY (SELECT 0)) as 'RowId'
						, PostingEntryStateSKID
					FROM
						[Base].PostingEntryState pes
					WHERE 
						pes.SourceID = @ParentSourceIds
					AND 
						pes.PostingState IN	(
												SELECT 
													StringColumnB 
												FROM 
													@PreviousState
											)
				END
		    ELSE IF(@messageType='PRMA01' OR @messageType ='PORMA1')
				BEGIN		 
					 DECLARE @ParentSourceId VARCHAR(100)
					 SELECT @ParentSourceId=  CAST(il.StringColumnB AS VARCHAR(100)) FROM @IdsList  il WHERE il.StringColumnA = 'Document';
					
					 INSERT INTO 
						@EntityPostingState
							(
								SourceID
								,ItemID
								,InternalMessageType
								,OperationType
								,PostingEntryStateSKID
								,RowId
							) 
					 SELECT 
						@SourceId
						,'NULL'
						,@messageType
						,1
						,PostingEntryStateSKID
						,ROW_NUMBER() OVER(ORDER BY (SELECT 0)) as 'RowId' 
					 FROM
						[Base].PostingEntryState pes
					 WHERE 
						pes.SourceID = @ParentSourceId	
				END
			ELSE IF(@messageType='PRMD01')
				BEGIN

					DECLARE @PreviousSkId VARCHAR(100)

					SET @PreviousSkId =	(
											SELECT 
												SourceSKID 
											FROM 
												base.Source 
											WHERE 
												SourceID 
											IN 
												(
													SELECT 
														CAST(il.StringColumnB AS VARCHAR(100)) 
													FROM 
														@IdsList  il 
													WHERE 
														il.StringColumnA = 'Document'
												)
										)

					INSERT INTO 
						@EntityPostingState
							(
								SourceID
								,ItemID
								,InternalMessageType
								,PostingEntryStateSKID
								,OperationType
								,RowId
							) 
					SELECT 
						@SourceId
						,'NULL'
						,@messageType
						,tmp.PostingEntryStateSKID
						,1
						,ROW_NUMBER() OVER(ORDER BY (SELECT 0)) AS 'RowId'
					FROM
						(
							SELECT 
								pes.PostingEntryStateSKID
								,ROW_NUMBER() OVER( PARTITION BY pe.PostingEntryID ORDER BY pes.PostingEntryStateSKID DESC) AS RowNumber
							FROM
								[Base].PostingEntry pe
							INNER JOIN 
								[Base].PostingEntryState pes 
							ON 
								pe.PostingEntryID = pes.PostingEntryID
							WHERE 
								pe.SourceSKID = @PreviousSkId
							AND	
								RIGHT(pe.PostingEntryID, 3)='DEB'
						) AS tmp 
					WHERE 
						tmp.RowNumber = 1		 
				END
			ELSE IF(@messageType='PSMA02')
				BEGIN

					DECLARE @PreviousSrcId VARCHAR(100)

					SET @PreviousSrcId =	(
												SELECT 
													CAST(il.StringColumnB AS VARCHAR(100)) 
												FROM 
													@IdsList  il 
												WHERE 
													il.StringColumnA = 'Document'
											)

					INSERT INTO 
						@EntityPostingState
							(
								SourceID
								,ItemID
								,InternalMessageType
								,PostingEntryStateSKID
								,OperationType
								,RowId
							) 					
					SELECT 
						@SourceId
						,'NULL'
						,@messageType
						,pes.PostingEntryStateSKID
						,1
						,ROW_NUMBER() OVER(ORDER BY (SELECT 0)) as 'RowId'
					FROM
						[Base].PostingEntryState pes
					WHERE 
						pes.SourceID = @PreviousSrcId 
				END
	END

	IF (@ExternalMsgType = 'CSMGT' AND @DestinationSubSystem = 'IA' )         
	BEGIN     
		-- Added ParentSourceId to fix duplicate sourceid update happening in ADJ posting
		DECLARE @ParentSourceIds_IA VARCHAR(100)
		SELECT @ParentSourceIds_IA = CAST(il.StringColumnB AS VARCHAR(100)) FROM @IdsList  il WHERE il.StringColumnA = 'Document';
		
		SELECT 
			@SourceId = SourceID 
		FROM 
			@Source;           

		INSERT INTO 
			@EntityPostingState
				(
					SourceID
					,InternalMessageType
					,PostingEntryStateSKID
					,PostingState
					,OperationType
					,RowId
					,ItemID
				)        
		SELECT 
			@SourceId
			,@messageType
			,PostingEntryStateSKID
			,995
			,1
			,1 AS RowId
			,'NULL' 
		FROM 
			Base.PostingEntryState
		WHERE 
			SourceID = @ParentSourceIds_IA      
	END 
	
	BEGIN TRANSACTION

	-- Update Sourcestate with flag to be 30, If any
	IF (CHARINDEX('Source',@PayloadLevel) > 0)
	BEGIN
		EXEC [Base].[usp_UpdateSourceState] 
			@messageType
			,@IdsList
			,@IsQueueBased
			,@ActivityId
	END
	
	--Update the flag
	UPDATE 
		@CopyTransactionSetState
	SET 
		OperationType = 1
	FROM 
		@CopyTransactionSetState input
	INNER JOIN 
		[Base].TransactionSetState actual
	ON 
		input.TsetID = actual.TsetID

	--Upsert data into TransactionSetState table
	EXEC [Base].[usp_Fwk_UpsertTransactionSetState] 
		@CopyTransactionSetState
		,@ActivityId

	DELETE FROM @CopyTransactionSetState

	--Upsert data into Source table
	EXEC [Base].[usp_Fwk_UpsertSourceForSendLogger] 
		@Source
		,@ActivityId
		,@sourceSkId OUTPUT

	-- Update TransactionSetState with flag to be 30
	IF (CHARINDEX('TSet',@PayloadLevel) > 0)
	BEGIN
		EXEC [Base].[usp_UpdateTransactionState] 
			@messageType
			,@IdsList
			,@IsQueueBased
			,@ActivityId
	END

	-- Update SourceSKID into transactionSet variable
	UPDATE 
		@CopyTransactionSet
	SET 
		SourceSKID = @sourceSkId

		--Update TransactionSet's state field from the table
	UPDATE 
		ts
	SET 
		State =	CASE 
					WHEN @participantType = 'Payer' AND ts.[State] IS NULL 
					THEN tss.PayerTsetState
					WHEN @participantType = 'Collector' AND ts.[State] IS NULL 
					THEN tss.CollectorTsetState
					WHEN @participantType = 'Beneficiary' AND ts.[State] IS NULL 
					THEN tss.BeneficiaryTsetState 
					WHEN @participantType = 'Holdover' 
					THEN ts.[State]
					ELSE ts.[State]		
				END
	FROM 
		@CopyTransactionSet ts 
	INNER JOIN 
		[Base].TransactionSetState tss 
	ON 
		tss.TsetID = ts.TsetID
	
	-- Insert data into TransactionSet table
	EXEC [Base].[usp_Fwk_UpsertTransactionSetForSendLogger] 
		@CopyTransactionSet
		,@ActivityId
	
	DELETE FROM @CopyTransactionSet

	-- Update ItemState with flag to be 30
	IF (CHARINDEX('Item',@PayloadLevel) > 0)
	BEGIN
		EXEC [Base].[usp_UpdateItemState] 
			@messageType
			,@IdsList
			,@IsQueueBased
			,@ActivityId
	END

	-- Update the Operation flag of ItemState variable, if the Item already exists
	Update 
		@CopyItemState
	SET 
		OperationType = 1
	FROM 
		@CopyItemState input
	INNER JOIN 
		[Base].ItemState actual
	ON 
		input.ItemID = actual.ItemID

	--Upsert data into ItemState table
	EXEC [Base].[usp_Fwk_UpsertItemState] 
		@CopyItemState
		,@ActivityId

	DELETE FROM @CopyItemState

	-- Update Sourceskid into item variable
	UPDATE 
		@CopyItem
	SET
		SourceSKID = @sourceSkId

	--Upsert data into Item table
	EXEC [Base].[usp_Fwk_UpsertItemForSendLogger] 
		@CopyItem
		,@ActivityId

	DELETE FROM @CopyItem

	--Update SourceTracker to processed
	EXEC [Base].[usp_Fwk_UpdateSourceTracker] 
		@ActivityId = @ActivityId
		,@Processed=1
		,@FileName = @FileName
		,@SourceSkid = @sourceSkId
		,@IsQueueBased = @IsQueueBased

	--update EntityPostingState table
	IF (EXISTS (SELECT TOP 1 1 FROM @EntityPostingState))
		BEGIN

			EXEC Base.usp_Fwk_UpsertPostingEntryState 
				@EntityPostingState
				,@ActivityId

			DELETE FROM @EntityPostingState

		END

	COMMIT TRANSACTION;	
END TRY

BEGIN CATCH
	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	DECLARE @ErrorLine INT;

	SELECT 		
		@ErrorSeverity = ERROR_SEVERITY(),
		@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),
		@ErrorMessage = ERROR_MESSAGE();
	
	--If transaction fails, roll back insert			
	IF XACT_STATE() <> 0
		ROLLBACK TRANSACTION;
	EXEC [Logging].usp_LogError NULL,@ActivityId;
	RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine);

END CATCH

SET NOCOUNT OFF;
END

GO

EXEC [sys].[sp_addextendedproperty] @name = N'Component',
    @value = N'iPSL.ICS.MO.DB',
    @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE',
    @level1name = N'usp_Fwk_WriteDataForSendLogger';
GO

EXEC [sys].[sp_addextendedproperty] @name = N'MS_Description',
    @value = N'Caller: Framework DAL.
			   Description: Stored Procedure to save data into the MO database for Send Logger pattern.
				udt_TransactionSet is saved into TransactionSet table,
				udt_Item is saved into Item table,
				udt_TransactionSetState is saved into TransactionSetState table
				udt_ItemState is saved into ItemState table,
				udt_SourceTracker is saved into SourceTracker table by invoking respective table wise upsert stored procedure',
    @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE',
    @level1name = N'usp_Fwk_WriteDataForSendLogger';
GO

EXEC [sys].[sp_addextendedproperty] @name = N'Version', @value = [$(Version)],
   @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE',
    @level1name = N'usp_Fwk_WriteDataForSendLogger';
GO

GRANT
    EXECUTE
    ON [Base].[usp_Fwk_WriteDataForSendLogger]
    TO
    [WebRole]
    AS [dbo];
GO