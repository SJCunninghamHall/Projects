CREATE PROCEDURE [Base].[usp_Fwk_WriteData]
	(
		@ActivityId				VARCHAR(60),
		@Source					[Base].[udt_Source]					READONLY,
		@TransactionSet			[Base].[udt_TransactionSet]			READONLY,
		@Item					[Base].[udt_Item]					READONLY,
		@TransactionSetState	[Base].[udt_TransactionSetState]	READONLY,
		@ItemState				[Base].[udt_ItemState]				READONLY,
		@PreviousState			[Base].[udt_WithTwoStringColumns]	READONLY
	)
/*****************************************************************************************************  
* Name    : [Base].[usp_Fwk_WriteData]  
* Description  :		Stored Procedure to save data into the MO database  
						Data from udt_Source is saved into Source table,  
						udt_TransactionSet is saved into TransactionSet table,  
						udt_Item is saved into Item table,  
						udt_TransactionSetState is saved into TransactionSetState table  
						udt_ItemState is saved into ItemState table by invoking respective table wise upsert stored procedure.  
						PreviousState UDT is two string column table used to check whether data that is updated have the  
						required previous states.  
						Upsert SourceTracker stored procedure is invoked to track the saved document.  
* Type of Procedure :   User-defined stored procedure  
* Author   :            Gaurav Choudhary  
* Creation Date  :      28-Dec-2016   
* Last Modified  :      Abhishek Pandey  
* Parameters  :  
*******************************************************************************************************  
*Parameter Name    Type    Description  
*------------------------------------------------------------------------------------------------------  
  
*******************************************************************************************************  
* Returns    :   
* Important Notes : N/A   
* Dependencies  :   
*******************************************************************************************************  
*          History  
*------------------------------------------------------------------------------------------------------  
* Version ID          Date                    Reason  
*******************************************************************************************************  
* 1.0.0  001         28-Dec-2016		Initial version  
* 1.0.1  002         29-Aug-2017		Changed logic to consider opearion type also when checking  
										for duplicates in ItemState and TransactionSetState. Also   
										changed logic to pick tsetid from item table if it is present  
* 1.0.2  003		 12-Oct-2017		Added new logic to add all the records eligible   
										for postings into the updated PostingEntryState table  
* 1.0.3  004         30-Oct-2017		Added new logic related to UpdatedDateTime   
										Based on Role   
* 1.0.4  004	     06-Nov-2017		Added logic for 04SM01 and 04MM01 to be updated   
										in ReceiveStagingTset and other tables  
* 1.0.5  005         22-Dec-2017		Removed the logic to Insert Posting Data in receive service.   
										Logic is moved to SendLoggerIA.  
* 1.0.6  006		 16-Jan-2018		Added ItemType column in ItemState UDT  
* 1.0.7  007		 03-Jul-2018		Reverted changes related to temporary table and varable done by NFR for live issue  
* 1.0.8  008		 25-Jun-2018		Corrected ItemState Udt Insertion
* 1.0.9  009		 17-Aug-2018		Added column PostingState for insert in PostingEntryState table for CM Posting
* 1.0.10 010		 22-Aug-2018		Corrected itemstate represent scennarios  
* 1.0.11 011         12-Mar-2019        Bug 203878 : Swapping the SP call to avoid Page Lock on tables resulting to deadlocks.
* 1.0.10 012		 08-Apr-2019		Populated @item with Window2BusinessDate #200277 
*******************************************************************************************************/
AS
	BEGIN

		SET NOCOUNT ON;

		SET XACT_ABORT ON;

		BEGIN TRY

			DECLARE @sourceSkId BIGINT;
			DECLARE @MessageType VARCHAR(6);
			DECLARE @CurrentDate DATETIME;
			DECLARE @PostingDirtyFlag SMALLINT;
			SELECT
				@PostingDirtyFlag	= CurrentVal
			FROM
				[$(MoConfigDatabase)].[Config].[tfn_GetEntityFlowFromConfig]('DF_CR');

			CREATE TABLE #ItemState
				(
					[CollectorRoleFlag]				[BIT]				NULL,
					[PayerRoleFlag]					[BIT]				NULL,
					[BeneficiaryRoleFlag]			[BIT]				NULL,
					[CollectorItemState]			[SMALLINT]			NULL,
					[PayerItemState]				[SMALLINT]			NULL,
					[BeneficiaryItemState]			[SMALLINT]			NULL,
					[CollectorItemDirtyFlag]		[BIT]				NULL,
					[PayerItemDirtyFlag]			[BIT]				NULL,
					[BeneficiaryItemDirtyFlag]		[BIT]				NULL,
					[CollectorItemBatchedFlag]		[BIT]				NULL,
					[PayerItemBatchedFlag]			[BIT]				NULL,
					[BeneficiaryItemBatchedFlag]	[CHAR](18)			NULL,
					[ItemID]						[CHAR](25)			NOT NULL,
					[OperationType]					[INT]				NULL,
					[Gender]						[SMALLINT]			NULL,
					[TsetID]						[CHAR](24)			NULL,
					[CollectorSourceDateTime]		[DATETIME2](3)		NULL,
					[PayerSourceDateTime]			[DATETIME2](3)		NULL,
					[BeneficiarySourceDateTime]		[DATETIME2](3)		NULL,
					[Window1BusinessDate]			[DATE]				NULL,
					[Window2BusinessDate]			[DATE]				NULL,
					[AlwaysUpdateWindowDates]		[BIT]				NULL,
					[PayerUpdatedDatetime]			[DATETIME2](3)		NULL,
					[BeneficiaryUpdatedDatetime]	[DATETIME2](3)		NULL,
					[CollectorUpdatedDatetime]		[DATETIME2](3)		NULL,
					[ItemType]						[CHAR](4)			NULL,
					[MSG06Flag]						[INT]				NULL,
					[MSG13Flag]						[INT]				NULL,
					[IcsAmount]						[DECIMAL](11, 2)	NULL,
					[RowId]							[INT]				NOT NULL
				);


			DECLARE @configAutoPostingClearingState SMALLINT = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigEAVValue('CMPaidDecision', 'CMCM01');

			EXEC Base.usp_GetCurrentDateTime
				@CurrentDate OUTPUT;

			DECLARE @CopySource [Base].[udt_Source];

			INSERT INTO
				@CopySource
			SELECT
				sourceInput.[SourceID],
				sourceInput.[MessageType],
				sourceInput.[ICNContent],
				sourceInput.[SourceState],
				sourceInput.[SourceStateRevision],
				sourceInput.[SourceDirtyFlag],
				sourceInput.[SourceBatchedFlag],
				sourceInput.[ISOContent],
				sourceInput.[CreatedDatetime],
				sourceInput.[UpdatedDatetime],
				sourceInput.[RelatedSourceID],
				sourceInput.[OperationType]
			FROM
				@Source AS sourceInput;

			-- Select only the transactions with correct state transition  
			DECLARE @CopyTransactionSetState [Base].[udt_TransactionSetState];

			INSERT INTO
				@CopyTransactionSetState
			SELECT
				transactionSetStateInput.[CollectorRoleFlag],
				transactionSetStateInput.[CollectorTsetState],
				transactionSetStateInput.[CollectorTsetDirtyFlag],
				transactionSetStateInput.[CollectorTsetBatchedFlag],
				transactionSetStateInput.[PayerRoleFlag],
				transactionSetStateInput.[PayerTsetState],
				transactionSetStateInput.[PayerTsetDirtyFlag],
				transactionSetStateInput.[PayerTsetBatchedFlag],
				transactionSetStateInput.[BeneficiaryRoleFlag],
				transactionSetStateInput.[BeneficiaryTsetState],
				transactionSetStateInput.[BeneficiaryTsetDirtyFlag],
				transactionSetStateInput.[BeneficiaryTsetBatchedFlag],
				transactionSetStateInput.[TsetID],
				transactionSetStateInput.[OperationType],
				transactionSetStateInput.[CollectorSourceDateTime],
				transactionSetStateInput.[PayerSourceDateTime],
				transactionSetStateInput.[BeneficiarySourceDateTime],
				transactionSetStateInput.[Window1BusinessDate],
				transactionSetStateInput.[Window2BusinessDate],
				transactionSetStateInput.[NewTsetID],
				transactionSetStateInput.[PayerUpdatedDatetime],
				transactionSetStateInput.[BeneficiaryUpdatedDatetime],
				transactionSetStateInput.[CollectorUpdatedDatetime],
				transactionSetStateInput.[RowId]
			FROM
				@TransactionSetState AS transactionSetStateInput;
			WITH
				CTE
			AS
				(
					SELECT
						ROW_NUMBER	() OVER (PARTITION BY
											TsetID,
											OperationType
											ORDER BY
											(
												SELECT
													0
											)
										) AS RowNumber
					FROM
						@CopyTransactionSetState
				)
			DELETE	FROM
			CTE
			WHERE
				[CTE].[RowNumber] > 1;

			--Update the UpdatedDatetime based on Role  

			UPDATE
				@CopyTransactionSetState
			SET
			PayerUpdatedDatetime	= CASE
											WHEN PayerRoleFlag = 1
											THEN @CurrentDate
											ELSE PayerUpdatedDatetime
									END,
				BeneficiaryUpdatedDatetime = CASE
												WHEN BeneficiaryRoleFlag = 1
												THEN @CurrentDate
												ELSE BeneficiaryUpdatedDatetime
											END,
				CollectorUpdatedDatetime = CASE
											WHEN	CollectorRoleFlag = 1
												THEN @CurrentDate
												ELSE CollectorUpdatedDatetime
										END;

			--Update SourceSkId for the TransactionSet table  
			DECLARE @CopyTransactionSet [Base].[udt_TransactionSet];

			INSERT INTO
				@CopyTransactionSet
				(
					TsetID,
					ISOContent,
					SourceSKID,
					OperationType,
					NodeType,
					InternalMessageType,
					[State],
					[ColltngPtcptId]
				)
			SELECT
				CASE
					WHEN tSetState.NewTsetID IS NOT NULL
					THEN tSetState.[NewTsetID]
					ELSE tSet.[TsetID]
				END,
				tSet.[ISOContent],
				tSet.[SourceSKID],
				tSet.[OperationType],
				tSet.[NodeType],
				tSet.[InternalMessageType],
				tSet.[State],
				tSet.[ColltngPtcptId]
			FROM
				@TransactionSet				AS tSet
			INNER JOIN
				@CopyTransactionSetState	AS tSetState
			ON
				tSet.TsetID = tSetState.TsetID;
			WITH
				CTE
			AS
				(
					SELECT
						ROW_NUMBER	() OVER (PARTITION BY
											TsetID
											ORDER BY
											(
												SELECT
													0
											)
										) AS RowNumber
					FROM
						@CopyTransactionSet
				)
			DELETE	FROM
			CTE
			WHERE
				[CTE].[RowNumber] > 1;

			UPDATE
				@CopyTransactionSet
			SET
			State	= CASE
							WHEN sta.PayerTsetState IS NOT NULL
							THEN sta.PayerTsetState
							WHEN sta.CollectorTsetState IS NOT NULL
							THEN sta.CollectorTsetState
							WHEN sta.BeneficiaryTsetState IS NOT NULL
							THEN sta.BeneficiaryTsetState
						END
			FROM
				@TransactionSetState	AS sta
			INNER JOIN
				@CopyTransactionSet		AS copyTransaction
			ON
				sta.TsetID = copyTransaction.TsetID;

			IF EXISTS
				(
					SELECT
						1
					FROM
						@ItemState
					WHERE
						OperationType = 0
				)
				BEGIN

					INSERT	INTO
						#ItemState
						(
							[CollectorRoleFlag],
							[PayerRoleFlag],
							[BeneficiaryRoleFlag],
							[CollectorItemState],
							[PayerItemState],
							[BeneficiaryItemState],
							[CollectorItemDirtyFlag],
							[PayerItemDirtyFlag],
							[BeneficiaryItemDirtyFlag],
							[CollectorItemBatchedFlag],
							[PayerItemBatchedFlag],
							[BeneficiaryItemBatchedFlag],
							[ItemID],
							[OperationType],
							[Gender],
							[TsetID],
							[CollectorSourceDateTime],
							[PayerSourceDateTime],
							[BeneficiarySourceDateTime],
							[Window1BusinessDate],
							[Window2BusinessDate],
							[AlwaysUpdateWindowDates],
							[PayerUpdatedDatetime],
							[BeneficiaryUpdatedDatetime],
							[CollectorUpdatedDatetime],
							[ItemType],
							[MSG06Flag],
							[MSG13Flag],
							[IcsAmount],
							[RowId]
						)
					SELECT
						itemStateInput	.[CollectorRoleFlag],
						itemStateInput.[PayerRoleFlag],
						itemStateInput.[BeneficiaryRoleFlag],
						itemStateInput.[CollectorItemState],
						itemStateInput.[PayerItemState],
						itemStateInput.[BeneficiaryItemState],
						itemStateInput.[CollectorItemDirtyFlag],
						itemStateInput.[PayerItemDirtyFlag],
						itemStateInput.[BeneficiaryItemDirtyFlag],
						itemStateInput.[CollectorItemBatchedFlag],
						itemStateInput.[PayerItemBatchedFlag],
						itemStateInput.[BeneficiaryItemBatchedFlag],
						itemStateInput.[ItemID],
						itemStateInput.[OperationType],
						itemStateInput.[Gender],
						itemStateInput.TsetID,
						itemStateInput.[CollectorSourceDateTime],
						itemStateInput.[PayerSourceDateTime],
						itemStateInput.[BeneficiarySourceDateTime],
						itemStateInput.[Window1BusinessDate],
						itemStateInput.[Window2BusinessDate],
						itemStateInput.[AlwaysUpdateWindowDates],
						itemStateInput.[PayerUpdatedDatetime],
						itemStateInput.[BeneficiaryUpdatedDatetime],
						itemStateInput.[CollectorUpdatedDatetime],
						itemStateInput.[ItemType],
						itemStateInput.[MSG06Flag],
						itemStateInput.[MSG13Flag],
						itemStateInput.[IcsAmount],
						itemStateInput.[RowId]
					FROM
						@ItemState AS itemStateInput
					WHERE
						itemStateInput.OperationType = 0;

					UPDATE
						tmp
					SET
					[tmp]	.[CollectorRoleFlag] = ISNULL([tmp].[CollectorRoleFlag], itemStateInput.[CollectorRoleFlag]),
						[tmp].[PayerRoleFlag] = ISNULL([tmp].[PayerRoleFlag], itemStateInput.[PayerRoleFlag]),
						[tmp].[BeneficiaryRoleFlag] = ISNULL([tmp].[BeneficiaryRoleFlag], itemStateInput.[BeneficiaryRoleFlag]),
						[tmp].[CollectorItemState] = ISNULL([tmp].[CollectorItemState], itemStateInput.[CollectorItemState]),
						[tmp].[PayerItemState] = ISNULL([tmp].[PayerItemState], itemStateInput.[PayerItemState]),
						[tmp].[BeneficiaryItemState] = ISNULL([tmp].[BeneficiaryItemState], itemStateInput.[BeneficiaryItemState]),
						[tmp].[CollectorItemDirtyFlag] = ISNULL([tmp].[CollectorItemDirtyFlag], itemStateInput.[CollectorItemDirtyFlag]),
						[tmp].[PayerItemDirtyFlag] = ISNULL([tmp].[PayerItemDirtyFlag], itemStateInput.[PayerItemDirtyFlag]),
						[tmp].[BeneficiaryItemDirtyFlag] = ISNULL([tmp].[BeneficiaryItemDirtyFlag], itemStateInput.[BeneficiaryItemDirtyFlag]),
						[tmp].[CollectorItemBatchedFlag] = ISNULL([tmp].[CollectorItemBatchedFlag], itemStateInput.[CollectorItemBatchedFlag]),
						[tmp].[PayerItemBatchedFlag] = ISNULL([tmp].[PayerItemBatchedFlag], itemStateInput.[PayerItemBatchedFlag]),
						[tmp].[BeneficiaryItemBatchedFlag] = ISNULL([tmp].[BeneficiaryItemBatchedFlag], itemStateInput.[BeneficiaryItemBatchedFlag]),
						[tmp].[ItemID] = ISNULL([tmp].[ItemID], itemStateInput.[ItemID]),
						[tmp].[OperationType] = ISNULL([tmp].[OperationType], itemStateInput.[OperationType]),
						[tmp].[Gender] = ISNULL([tmp].[Gender], itemStateInput.[Gender]),
						[tmp].[TsetID] = ISNULL([tmp].[TsetID], itemStateInput.TsetID),
						[tmp].[CollectorSourceDateTime] = ISNULL([tmp].[CollectorSourceDateTime], itemStateInput.[CollectorSourceDateTime]),
						[tmp].[PayerSourceDateTime] = ISNULL([tmp].[PayerSourceDateTime], itemStateInput.[PayerSourceDateTime]),
						[tmp].[BeneficiarySourceDateTime] = ISNULL([tmp].[BeneficiarySourceDateTime], itemStateInput.[BeneficiarySourceDateTime]),
						[tmp].[Window1BusinessDate] = ISNULL([tmp].[Window1BusinessDate], itemStateInput.[Window1BusinessDate]),
						[tmp].[Window2BusinessDate] = ISNULL([tmp].[Window2BusinessDate], itemStateInput.[Window2BusinessDate]),
						[tmp].[AlwaysUpdateWindowDates] = ISNULL([tmp].[AlwaysUpdateWindowDates], itemStateInput.[AlwaysUpdateWindowDates]),
						[tmp].[PayerUpdatedDatetime] = ISNULL([tmp].[PayerUpdatedDatetime], itemStateInput.[PayerUpdatedDatetime]),
						[tmp].[BeneficiaryUpdatedDatetime] = ISNULL([tmp].[BeneficiaryUpdatedDatetime], itemStateInput.[BeneficiaryUpdatedDatetime]),
						[tmp].[CollectorUpdatedDatetime] = ISNULL([tmp].[CollectorUpdatedDatetime], itemStateInput.[CollectorUpdatedDatetime]),
						[tmp].[ItemType] = ISNULL([tmp].[ItemType], itemStateInput.[ItemType]),
						[tmp].[MSG06Flag] = ISNULL([tmp].[MSG06Flag], itemStateInput.[MSG06Flag]),
						[tmp].[MSG13Flag] = ISNULL([tmp].[MSG13Flag], itemStateInput.[MSG13Flag]),
						[tmp].[IcsAmount] = ISNULL([tmp].[IcsAmount], itemStateInput.[IcsAmount]),
						[tmp].[RowId] = ISNULL([tmp].[RowId], itemStateInput.[RowId])
					FROM
						@ItemState	AS itemStateInput
					INNER JOIN
						#ItemState	AS tmp
					ON
						[tmp].[ItemID] = itemStateInput.ItemID
					AND itemStateInput.OperationType = 1;

					INSERT INTO
						#ItemState
						(
							[CollectorRoleFlag],
							[PayerRoleFlag],
							[BeneficiaryRoleFlag],
							[CollectorItemState],
							[PayerItemState],
							[BeneficiaryItemState],
							[CollectorItemDirtyFlag],
							[PayerItemDirtyFlag],
							[BeneficiaryItemDirtyFlag],
							[CollectorItemBatchedFlag],
							[PayerItemBatchedFlag],
							[BeneficiaryItemBatchedFlag],
							[ItemID],
							[OperationType],
							[Gender],
							[TsetID],
							[CollectorSourceDateTime],
							[PayerSourceDateTime],
							[BeneficiarySourceDateTime],
							[Window1BusinessDate],
							[Window2BusinessDate],
							[AlwaysUpdateWindowDates],
							[PayerUpdatedDatetime],
							[BeneficiaryUpdatedDatetime],
							[CollectorUpdatedDatetime],
							[ItemType],
							[MSG06Flag],
							[MSG13Flag],
							[IcsAmount],
							[RowId]
						)
					SELECT
						itemStateInput	.[CollectorRoleFlag],
						itemStateInput.[PayerRoleFlag],
						itemStateInput.[BeneficiaryRoleFlag],
						itemStateInput.[CollectorItemState],
						itemStateInput.[PayerItemState],
						itemStateInput.[BeneficiaryItemState],
						itemStateInput.[CollectorItemDirtyFlag],
						itemStateInput.[PayerItemDirtyFlag],
						itemStateInput.[BeneficiaryItemDirtyFlag],
						itemStateInput.[CollectorItemBatchedFlag],
						itemStateInput.[PayerItemBatchedFlag],
						itemStateInput.[BeneficiaryItemBatchedFlag],
						itemStateInput.[ItemID],
						itemStateInput.[OperationType],
						itemStateInput.[Gender],
						itemStateInput.TsetID,
						itemStateInput.[CollectorSourceDateTime],
						itemStateInput.[PayerSourceDateTime],
						itemStateInput.[BeneficiarySourceDateTime],
						itemStateInput.[Window1BusinessDate],
						itemStateInput.[Window2BusinessDate],
						itemStateInput.[AlwaysUpdateWindowDates],
						itemStateInput.[PayerUpdatedDatetime],
						itemStateInput.[BeneficiaryUpdatedDatetime],
						itemStateInput.[CollectorUpdatedDatetime],
						itemStateInput.[ItemType],
						itemStateInput.[MSG06Flag],
						itemStateInput.[MSG13Flag],
						itemStateInput.[IcsAmount],
						itemStateInput.[RowId]
					FROM
						@ItemState AS itemStateInput
					WHERE
						itemStateInput.OperationType = 1
					AND NOT EXISTS
						(
							SELECT
								1
							FROM
								#ItemState AS itemState
							WHERE
								itemStateInput.ItemID = [itemState].[ItemID]
						);

				END;

			ELSE
				BEGIN

					INSERT	INTO
						#ItemState
						(
							[CollectorRoleFlag],
							[PayerRoleFlag],
							[BeneficiaryRoleFlag],
							[CollectorItemState],
							[PayerItemState],
							[BeneficiaryItemState],
							[CollectorItemDirtyFlag],
							[PayerItemDirtyFlag],
							[BeneficiaryItemDirtyFlag],
							[CollectorItemBatchedFlag],
							[PayerItemBatchedFlag],
							[BeneficiaryItemBatchedFlag],
							[ItemID],
							[OperationType],
							[Gender],
							[TsetID],
							[CollectorSourceDateTime],
							[PayerSourceDateTime],
							[BeneficiarySourceDateTime],
							[Window1BusinessDate],
							[Window2BusinessDate],
							[AlwaysUpdateWindowDates],
							[PayerUpdatedDatetime],
							[BeneficiaryUpdatedDatetime],
							[CollectorUpdatedDatetime],
							[ItemType],
							[MSG06Flag],
							[MSG13Flag],
							[IcsAmount],
							[RowId]
						)
					SELECT
						itemStateInput	.[CollectorRoleFlag],
						itemStateInput.[PayerRoleFlag],
						itemStateInput.[BeneficiaryRoleFlag],
						itemStateInput.[CollectorItemState],
						itemStateInput.[PayerItemState],
						itemStateInput.[BeneficiaryItemState],
						itemStateInput.[CollectorItemDirtyFlag],
						itemStateInput.[PayerItemDirtyFlag],
						itemStateInput.[BeneficiaryItemDirtyFlag],
						itemStateInput.[CollectorItemBatchedFlag],
						itemStateInput.[PayerItemBatchedFlag],
						itemStateInput.[BeneficiaryItemBatchedFlag],
						itemStateInput.[ItemID],
						itemStateInput.[OperationType],
						itemStateInput.[Gender],
						itemStateInput.TsetID,
						itemStateInput.[CollectorSourceDateTime],
						itemStateInput.[PayerSourceDateTime],
						itemStateInput.[BeneficiarySourceDateTime],
						itemStateInput.[Window1BusinessDate],
						itemStateInput.[Window2BusinessDate],
						itemStateInput.[AlwaysUpdateWindowDates],
						itemStateInput.[PayerUpdatedDatetime],
						itemStateInput.[BeneficiaryUpdatedDatetime],
						itemStateInput.[CollectorUpdatedDatetime],
						itemStateInput.[ItemType],
						itemStateInput.[MSG06Flag],
						itemStateInput.[MSG13Flag],
						itemStateInput.[IcsAmount],
						itemStateInput.[RowId]
					FROM
						@ItemState AS itemStateInput
					WHERE
						itemStateInput.OperationType = 1;

				END;
			WITH
				CTE
			AS
				(
					SELECT
						ROW_NUMBER	() OVER (PARTITION BY
											ItemID,
											OperationType
											ORDER BY
											(
												SELECT
													0
											)
										) AS RowNumber
					FROM
						#ItemState
				)
			DELETE	FROM
			CTE
			WHERE
				[CTE].[RowNumber] > 1;

			-- select the items having correct transitions.  
			DECLARE @CopyItemState [Base].[udt_ItemState];

			INSERT INTO
				@CopyItemState
				(
					[CollectorRoleFlag],
					[PayerRoleFlag],
					[BeneficiaryRoleFlag],
					[CollectorItemState],
					[PayerItemState],
					[BeneficiaryItemState],
					[CollectorItemDirtyFlag],
					[PayerItemDirtyFlag],
					[BeneficiaryItemDirtyFlag],
					[CollectorItemBatchedFlag],
					[PayerItemBatchedFlag],
					[BeneficiaryItemBatchedFlag],
					[ItemID],
					[OperationType],
					[Gender],
					[TsetID],
					[CollectorSourceDateTime],
					[PayerSourceDateTime],
					[BeneficiarySourceDateTime],
					[Window1BusinessDate],
					[Window2BusinessDate],
					[AlwaysUpdateWindowDates],
					[PayerUpdatedDatetime],
					[BeneficiaryUpdatedDatetime],
					[CollectorUpdatedDatetime],
					[ItemType],
					[MSG06Flag],
					[MSG13Flag],
					[IcsAmount],
					[RowId]
				)
			SELECT
				[itemStateInput].[CollectorRoleFlag],
				[itemStateInput].[PayerRoleFlag],
				[itemStateInput].[BeneficiaryRoleFlag],
				[itemStateInput].[CollectorItemState],
				[itemStateInput].[PayerItemState],
				[itemStateInput].[BeneficiaryItemState],
				[itemStateInput].[CollectorItemDirtyFlag],
				[itemStateInput].[PayerItemDirtyFlag],
				[itemStateInput].[BeneficiaryItemDirtyFlag],
				[itemStateInput].[CollectorItemBatchedFlag],
				[itemStateInput].[PayerItemBatchedFlag],
				[itemStateInput].[BeneficiaryItemBatchedFlag],
				[itemStateInput].[ItemID],
				[itemStateInput].[OperationType],
				[itemStateInput].[Gender],
				[itemStateInput].[TsetID],
				[itemStateInput].[CollectorSourceDateTime],
				[itemStateInput].[PayerSourceDateTime],
				[itemStateInput].[BeneficiarySourceDateTime],
				[itemStateInput].[Window1BusinessDate],
				[itemStateInput].[Window2BusinessDate],
				[itemStateInput].[AlwaysUpdateWindowDates],
				[itemStateInput].[PayerUpdatedDatetime],
				[itemStateInput].[BeneficiaryUpdatedDatetime],
				[itemStateInput].[CollectorUpdatedDatetime],
				[itemStateInput].[ItemType],
				[itemStateInput].[MSG06Flag],
				[itemStateInput].[MSG13Flag],
				[itemStateInput].[IcsAmount],
				[itemStateInput].[RowId]
			FROM
				#ItemState AS itemStateInput;

			--Update the UpdatedDatetime based on Role  
			UPDATE
				@CopyItemState
			SET
			PayerUpdatedDatetime	= CASE
											WHEN PayerRoleFlag = 1
											THEN @CurrentDate
											ELSE PayerUpdatedDatetime
									END,
				BeneficiaryUpdatedDatetime = CASE
												WHEN BeneficiaryRoleFlag = 1
												THEN @CurrentDate
												ELSE BeneficiaryUpdatedDatetime
											END,
				CollectorUpdatedDatetime = CASE
											WHEN	CollectorRoleFlag = 1
												THEN @CurrentDate
												ELSE CollectorUpdatedDatetime
										END;

			--Update SourceSkId for the Item table  
			DECLARE @CopyItem [Base].[udt_Item];

			INSERT INTO
				@CopyItem
			SELECT
				item.[ISOContent],
				item.[ICNContent],
				item.[ItemID],
				item.[SourceSKID],
				item.[TsetID],
				item.[OperationType],
				item.[NodeType],
				item.[InternalMessageType],
				item.[State],
				item.[StateRevision],
				[itemState].[Window2BusinessDate]
			FROM
				@Item		AS item
			INNER JOIN
				#ItemState	AS itemState
			ON
				item.ItemID = [itemState].[ItemID];
			WITH
				CTE
			AS
				(
					SELECT
						ROW_NUMBER	() OVER (PARTITION BY
											ItemID,
											NodeType
											ORDER BY
											(
												SELECT
													0
											)
										) AS RowNumber
					FROM
						@CopyItem
				)
			DELETE	FROM
			CTE
			WHERE
				[CTE].[RowNumber] > 1;

			-- Get TransactionSetId for all the items from the Item table  
			UPDATE
				@CopyItem
			SET
			TsetID	= CASE
							WHEN copyItem.TsetID IS NULL
							THEN sta.TsetID
							ELSE copyItem.TsetID
						END,
				Window2BusinessDate = CASE
										WHEN copyItem.Window2BusinessDate IS NULL
										THEN sta.Window2BusinessDate
										ELSE copyItem.Window2BusinessDate
									END
			FROM
				[Base].ItemState	AS sta
			INNER JOIN
				@CopyItem			AS copyItem
			ON
				sta.ItemID = copyItem.ItemID
			WHERE
				sta.TsetID IS NOT NULL;

			UPDATE
				@CopyItem
			SET
			[State] = CASE
							WHEN [sta].[PayerItemState] IS NOT NULL
							THEN [sta].[PayerItemState]
							WHEN [sta].[CollectorItemState] IS NOT NULL
							THEN [sta].[CollectorItemState]
							WHEN [sta].[BeneficiaryItemState] IS NOT NULL
							THEN [sta].[BeneficiaryItemState]
						END,
				TsetID = CASE
							WHEN [sta].[TsetID] IS NOT NULL
							THEN [sta].[TsetID]
							ELSE copyItem.TsetID
						END
			FROM
				#ItemState	AS sta
			INNER JOIN
				@CopyItem	AS copyItem
			ON
				[sta].[ItemID] = copyItem.ItemID;

			--Create a udt to be used to upsert EntityPostingState table   
			DECLARE @EntityStateFROM VARCHAR(400);

			--Read the postable entity states from Message Parameters  
			SELECT
				@EntityStateFROM	= EntityStateTransitionFrom
			FROM
				[$(MoConfigDatabase)].[Config].[tfn_ReadMessageParameters]('PTMA01');

			--Read the Business Date from Config  
			DECLARE @configBusinessDate DATE = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigEAVValue('ControlM', 'BD');

			-- Insert Posting Data for Case Management ( CMCM01)  
			DECLARE @CopyPostingEntryState [Base].[udt_PostingEntryState];

			INSERT INTO
				@CopyPostingEntryState
				(
					[SourceID],
					[ItemID],
					[TsetID],
					[InternalMessageType],
					[ClearingState],
					[PostingState],
					[Window1BusinessDate],
					[Window2BusinessDate],
					[OperationType],
					[PostingDirtyFlag],
					[RowId]
				)
			SELECT	DISTINCT
					[source].[SourceID],
					'NULL',
					NULL,
					[source].[MessageType],
					[source].[SourceState],
					995,
					@configBusinessDate,
					NULL,
					[source].[OperationType],
					@PostingDirtyFlag,
					ROW_NUMBER() OVER (ORDER BY
										[source].[SourceID]
									) AS RowId
			FROM
					@CopySource AS [source]
			WHERE
					[source].SourceState IN ( @configAutoPostingClearingState );	--CMCM01 source entity state  

			IF EXISTS
				(
					SELECT
						1
					FROM
						@CopyPostingEntryState
				)
				BEGIN
					UPDATE
						@CopyPostingEntryState
					SET
					SourceID	=
							(
								SELECT
									SourceID
								FROM
									@CopySource
							);
				END;

			DECLARE @CopyReceiveStagingTset [Base].[udt_ReceiveStagingTset];

			INSERT INTO
				@CopyReceiveStagingTset
				(
					[TsetID],
					[ISOContent],
					[ColltngPtcptId],
					[OperationType],
					[CollectorRoleFlag],
					[BeneficiaryRoleFlag]
				)
			SELECT
				[transSet]	.[TsetID],
				[transSet].[ISOContent],
				[transSet].[ColltngPtcptId],
				[transSet].[OperationType],
				NULL,
				NULL
			FROM
				@CopyTransactionSet AS [transSet]
			WHERE
				[transSet].[InternalMessageType] = '04SM01'
			UNION ALL
			SELECT
				[transSetState].[TsetID],
				NULL,
				NULL,
				[transSetState].[OperationType],
				[transSetState].[CollectorRoleFlag],
				[transSetState].[BeneficiaryRoleFlag]
			FROM
				@CopyTransactionSetState	AS [transSetState]
			JOIN
				@CopyItem					AS [itm]
			ON
				[transSetState].[TsetID] = [itm].[TsetID]
			WHERE
				[itm].[InternalMessageType] = '04MM01';


			BEGIN TRANSACTION;

			--Updating Message Type when Upsert for Item is called and TransactionSet is not to be Upserted  
			SET @MessageType =
				(
					SELECT	TOP 1
							InternalMessageType
					FROM
							@CopyItem
				);

			--Updating Message Type when Upsert for TransactionSet is called and Item is not to be Upserted  
			IF (@MessageType IS NULL)
				BEGIN
					SET @MessageType =
						(
							SELECT	TOP 1
									InternalMessageType
							FROM
									@CopyTransactionSet
						);
				END;

			--Do not process source insert for 04MM01 as handled in UpsertReceiveStaginTset  
			IF (
				@MessageType <> '04MM01'
			OR		@MessageType IS NULL
			)
				BEGIN
					--Upsert data into Source table    
					EXEC [Base].[usp_Fwk_UpsertSource]
						@CopySource,
						@ActivityId,
						@sourceSkId OUTPUT;
					DELETE	FROM
					@CopySource;
				END;

			--Do not process insert into TransactionSetState or TransactionSet for 04SM01 as not required  
			IF (
				@MessageType <> '04SM01'
			OR		@MessageType IS NULL
			)
				BEGIN

					--Update the flag  
					UPDATE
						@CopyTransactionSetState
					SET
					OperationType	= 1
					FROM
						@CopyTransactionSetState	AS input
					INNER JOIN
						[Base].TransactionSetState	AS actual
					ON
						input.TsetID = actual.TsetID;

					--Upsert data into TransactionSetState table  
					EXEC [Base].[usp_Fwk_UpsertTransactionSetState]
						@CopyTransactionSetState,
						@ActivityId;
					DELETE	FROM
					@CopyTransactionSetState;

					--Retreive Source SKID from [Base].[usp_Fwk_UpsertSource] called above and update into @CopyTransactionSet  
					UPDATE
						@CopyTransactionSet
					SET
					SourceSKID	= @sourceSkId;

					--Upsert data into TransactionSet table  
					EXEC [Base].[usp_Fwk_UpsertTransactionSet]
						@CopyTransactionSet,
						@ActivityId;
					DELETE	FROM
					@CopyTransactionSet;

				END;

			--Update the flag  
			UPDATE
				@CopyItemState
			SET
			OperationType	= 1
			FROM
				@CopyItemState		AS input
			INNER JOIN
				[Base].ItemState	AS actual
			ON
				input.ItemID = actual.ItemID;

			--Upsert data into ItemState table  
			EXEC [Base].[usp_Fwk_UpsertItemState]
				@CopyItemState,
				@ActivityId;
			DELETE	FROM
			@CopyItemState;

			--Do not process Item or SourceTracker insert for 04MM01 as handled in UpsertReceiveStagingTset  
			IF (
				@MessageType <> '04MM01'
			OR		@MessageType IS NULL
			)
				BEGIN

					--Upsert data into Item table  
					UPDATE
						@CopyItem
					SET
					SourceSKID	= @sourceSkId;

					EXEC [Base].[usp_Fwk_UpsertItem]
						@CopyItem,
						@ActivityId;
					DELETE	FROM
					@CopyItem;

					--Upsert data into EntityPostingState table  
					EXEC [Base].[usp_Fwk_UpsertPostingEntryState]
						@CopyPostingEntryState,
						@ActivityId;
					DELETE	FROM
					@CopyPostingEntryState;

					--Update SourceTracker to processed  
					EXEC [Base].[usp_Fwk_UpdateSourceTracker]
						@ActivityId = @ActivityId,
						@Processed = 1,
						@SourceSkid = @sourceSkId;

				END;

			--Upsert data into ReceiveStagingTset table  
			UPDATE
				@CopyReceiveStagingTset
			SET
			SourceSKID	= @sourceSkId;

			EXEC [Base].[usp_Fwk_UpsertReceiveStagingTset]
				@CopyReceiveStagingTset,
				@CopyItem,
				@ActivityId = @ActivityId;
			DELETE	FROM
			@CopyReceiveStagingTset;

			COMMIT TRANSACTION;

		END TRY
		BEGIN CATCH
			DECLARE @ErrorMessage NVARCHAR(4000);
			DECLARE @ErrorSeverity INT;
			DECLARE @ErrorState INT;
			DECLARE @ErrorLine INT;

			SELECT
				@ErrorSeverity	= ERROR_SEVERITY(),
				@ErrorState		= ERROR_STATE(),
				@ErrorLine		= ERROR_LINE(),
				@ErrorMessage	= ERROR_MESSAGE();

			--If transaction fails, roll back insert     
			IF XACT_STATE() <> 0
				ROLLBACK TRANSACTION;
			EXEC [Logging].[usp_LogError]
				NULL,
				@ActivityId;
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
	@level1name = N'usp_Fwk_WriteData';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Caller: Framework DAL.
			   Description: Stored Procedure to save data into the MO database Data from udt_Source is saved into Source table,
				udt_TransactionSet is saved into TransactionSet table,
				udt_Item is saved into Item table,
				udt_TransactionSetState is saved into TransactionSetState table
				udt_ItemState is saved into ItemState table,
				udt_SourceTracker is saved into SourceTracker table by invoking respective table wise upsert stored procedure',
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Fwk_WriteData';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = [$(Version)],
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Fwk_WriteData';
GO

GRANT
	EXECUTE
ON OBJECT::[Base].[usp_Fwk_WriteData]
TO
	[WebRole]
AS [dbo];
GO