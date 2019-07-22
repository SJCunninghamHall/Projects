CREATE PROCEDURE [Base].[usp_Fwk_WriteDataForPostings]
	(
		@ActivityId				VARCHAR(60),
		@Source					[Base].[udt_Source]					READONLY,
		@TransactionSet			[Base].[udt_TransactionSet]			READONLY,
		@Item					[Base].[udt_Item]					READONLY,
		@TransactionSetState	[Base].[udt_TransactionSetState]	READONLY,	--Not to be used
		@ItemState				[Base].[udt_ItemState]				READONLY,	--Not to be used
		@PreviousState			[Base].[udt_WithTwoStringColumns]	READONLY,
		@postingEntryState		[Base].[udt_PostingEntryState]		READONLY,
		@PostingEntry			[Base].[udt_PostingEntry]			READONLY
	)
/*****************************************************************************************************
* Name				: [Base].[usp_Fwk_WriteDataForPostings]
* Description		: Stored Procedure to save data into the MO database for Posting messages. Data will be inserted into Source,TransactionSet,Item,
						PostingEntry & PostingEntryState
					  Data from udt_Source is saved into Source table,
					  udt_TransactionSet is saved into TransactionSet table,
					  udt_Item is saved into Item table,
					  udt_postingEntryState into PostingEntryState table
					  udt_PostingEntry into PostingEntry table
					  PreviousState UDT is two string column table used to check whether data that is updated have the
					  required previous states.
					  Upsert SourceTracker stored procedure is invoked to track the saved document.
* Type of Procedure : User-defined stored procedure
* Author			: Sabarish Jayaraman
* Creation Date		: 14-Jun-2018
* Last Modified		: 
* Parameters		:
*******************************************************************************************************
*Parameter Name				Type				Description
*------------------------------------------------------------------------------------------------------

*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************
*										History
*------------------------------------------------------------------------------------------------------
* Version 					ID          Date                    Reason
*******************************************************************************************************
* 1.0.0						001         14-Jun-2018			   	Initial version
* 1.0.1						002			06-Aug-2018				Changed PES table update logic to avoid 
																  wrong updation of inclearing entries
* 1.0.2						003			04-Sep-2018				Restructured PES table update to be on SKID
																also handled mutiple PEID scenario
* 1.0.3						004         08-Apr-2019			    Populated @item with Window2BusinessDate #200277 
*******************************************************************************************************/
AS
	BEGIN

		SET NOCOUNT ON;

		SET XACT_ABORT ON;

		BEGIN TRY

			DECLARE @sourceSkId BIGINT;
			DECLARE @CopyTransactionSet [Base].[udt_TransactionSet];
			DECLARE @CopyItem [Base].[udt_Item];
			DECLARE @CopyPostingEntryState [Base].[udt_PostingEntryState];
			DECLARE @CopyPostingEntry [Base].[udt_PostingEntry];

			-- Get Not Extracted state from configDB
			DECLARE @configPERMNoExtract VARCHAR(50) = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigEAVValue('PERMNoExtract', 'PERM01');
			DECLARE @configPTMATrigger VARCHAR(50) = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigEAVValue('PTMATrigger', 'PTMA01');

			-- Get the posting status to be considered for loading response
			CREATE TABLE #PostingResponseWaitingStates
				(
					[StringColumnA] VARCHAR(100)	NULL
				);

			INSERT INTO
				#PostingResponseWaitingStates
			SELECT
				value
			FROM
				STRING_SPLIT([$(MoConfigDatabase)].[config].sfn_ReadScalarConfigEAVValue('Postings', 'WaitingForResponseStates'), ',');

			INSERT INTO
				#PostingResponseWaitingStates
			SELECT
				value
			FROM
				STRING_SPLIT([$(MoConfigDatabase)].[config].sfn_ReadScalarConfigEAVValue('Postings', 'WaitingForPSRMStates'), ',');

			-- Take copy of transactionSet and remove duplicates
			INSERT INTO
				@CopyTransactionSet
				(
					TsetID,
					ISOContent,
					OperationType,
					NodeType,
					InternalMessageType,
					[State],
					[ColltngPtcptId]
				)
			SELECT
				sourceInput.[TsetID],
				sourceInput.[ISOContent],
				sourceInput.[OperationType],
				sourceInput.[NodeType],
				sourceInput.[InternalMessageType],
				sourceInput.[State],
				sourceInput.[ColltngPtcptId]
			FROM
				@TransactionSet AS sourceInput;
			WITH
				CTE
			AS
				(
					SELECT
						ROW_NUMBER	() OVER (PARTITION BY
											TsetID,
											NodeType
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

			-- Take copy of Item and remove duplicates
			INSERT INTO
				@CopyItem
				(
					[ISOContent],
					[ICNContent],
					[ItemID],
					[SourceSKID],
					[TsetID],
					[OperationType],
					[NodeType],
					[InternalMessageType],
					[State],
					[StateRevision],
					[Window2BusinessDate]
				)
			SELECT
				sourceInput.[ISOContent],
				sourceInput.[ICNContent],
				sourceInput.[ItemID],
				sourceInput.[SourceSKID],
				sourceInput.[TsetID],
				sourceInput.[OperationType],
				sourceInput.[NodeType],
				sourceInput.[InternalMessageType],
				sourceInput.[State],
				sourceInput.[StateRevision],
				itemState.[Window2BusinessDate]
			FROM
				@Item				AS sourceInput
			LEFT JOIN
				[Base].ItemState	AS itemState
			ON
				itemState.ItemID = sourceInput.ItemID;


			;WITH
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

			-- Take copy of PostingEntry and remove duplicates
			INSERT INTO
				@CopyPostingEntry
				(
					[PostingEntryID],
					[ItemID],
					[MessageType],
					[State],
					[OperationType],
					[TSetID],
					[SourceDateTime]
				)
			SELECT
				postingInput.PostingEntryID,
				postingInput.ItemID,
				postingInput.MessageType,
				postingInput.State,
				postingInput.OperationType,
				postingInput.[TSetID],
				postingInput.[SourceDateTime]
			FROM
				@PostingEntry AS postingInput;
			WITH
				CTE
			AS
				(
					SELECT
						ROW_NUMBER	() OVER (PARTITION BY
											TsetID,
											ItemID,
											PostingEntryID
											ORDER BY
											(
												SELECT
													0
											)
										) AS RowNumber
					FROM
						@CopyPostingEntry
				)
			DELETE	FROM
			CTE
			WHERE
				[CTE].[RowNumber] > 1;

			-- Take copy of PostingEntryState
			INSERT INTO
				@CopyPostingEntryState
				(
					SourceID,
					ItemID,
					TsetID,
					InternalMessageType,
					PostingEntryID,
					PostingState,
					OperationType,
					PreviousPostingState,
					RowId
				)
			SELECT
				SourceID,
				ItemID,
				TsetID,
				InternalMessageType,
				PostingEntryID,
				PostingState,
				OperationType,
				PreviousPostingState,
				RowId
			FROM
				@postingEntryState AS postingStateInput;

			-- Update missing fields for the records. Join will be at TsetID
			IF EXISTS
				(
					SELECT
						1
					FROM
						@CopyPostingEntryState
					WHERE
						OperationType = 0
				)
				BEGIN
					UPDATE
						copypes
					SET
					copypes.ClearingState = pes.ClearingState,
						copypes.Window1BusinessDate = pes.Window1BusinessDate,
						copypes.Window2BusinessDate = pes.Window2BusinessDate,
						copypes.PostingDirtyFlag = pes.PostingDirtyFlag
					FROM
						@CopyPostingEntryState		AS copypes
					INNER JOIN
						[Base].[PostingEntryState]	AS pes
					ON
						copypes.TsetID = pes.TsetID
					WHERE
						copypes.OperationType = 0
					AND copypes.PreviousPostingState = pes.PostingState
					AND pes.SourceID IN
							(
								SELECT
									SourceID
								FROM
									@Source
								WHERE
									OperationType = 1
							);

					-- Change opeartion type to Update for items which are already available
					-- expecting only one posting type for each item
					UPDATE
						copypes
					SET
					OperationType	= 1,
						copypes.PostingEntryStateSKID = pes.PostingEntryStateSKID
					FROM
						@CopyPostingEntryState		AS copypes
					INNER JOIN
						[Base].[PostingEntryState]	AS pes
					ON
						copypes.TsetID = pes.TsetID
					AND copypes.ItemID = pes.ItemID
					AND copypes.ClearingState = pes.ClearingState
					AND
					(
							pes.PostingEntryId IS NULL
					OR		copypes.PostingEntryId = pes.PostingEntryId
						)

					-- Change operation type for the first matching entry for the tset 
					-- Rest of the tset's entries will be inserted

					;
					WITH
						FirstPostingEntry
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
												) AS RowNumber,
								*
							FROM
								@CopyPostingEntryState
							WHERE
								OperationType = 0
						)
					UPDATE
						copypes
					SET
					OperationType	= 1,
						copypes.PostingEntryStateSKID = pes.PostingEntryStateSKID
					FROM
						FirstPostingEntry			AS copypes
					INNER JOIN
						[Base].[PostingEntryState]	AS pes
					ON
						copypes.TsetID = pes.TsetID
					AND pes.ItemID IS NULL
					AND copypes.ClearingState = pes.ClearingState
					WHERE
						[copypes].[RowNumber] = 1;
				END;
			ELSE -- For response messages, pick the clearing state entry to update
				BEGIN
					UPDATE
						copy
					SET
					copy.PostingEntryStateSKID = pes.PostingEntryStateSKID
					FROM
						@CopyPostingEntryState		AS copy
					INNER JOIN
						[Base].[PostingEntryState]	AS pes
					ON
						copy.PostingEntryID = pes.PostingEntryID
					AND pes.PostingState IN
							(
								SELECT
									[StringColumnA]
								FROM
									#PostingResponseWaitingStates
							);
				END;

			-- If it is document level rejection, then update them to rejected state
			IF EXISTS
				(
					SELECT
						1
					FROM
						@Source
					WHERE
						SourceState = @configPERMNoExtract
				)
				BEGIN
					INSERT	INTO
						@CopyPostingEntryState
						(
							InternalMessageType,
							ItemID,
							PostingState,
							OperationType,
							RowId,
							PostingEntryStateSKID
						)
					SELECT
						(
							SELECT
								MessageType
							FROM
								@Source
							WHERE
								OperationType = 0
						),
						'NULL'	,
						@configPERMNoExtract,
						1,
						ROW_NUMBER	() OVER (ORDER BY
											(
												SELECT
													0
											)
										),
						PostingEntryStateSKID
					FROM
						BASE.PostingEntryState
					WHERE
						SourceID =
						(
							SELECT
								SourceId
							FROM
								@Source
							WHERE
								SourceState = @configPERMNoExtract
						);
				END;

			-- Update SourceID of the new entry into CopyPostingEntryState
			UPDATE
				@CopyPostingEntryState
			SET
			SourceID	=
					(
						SELECT	TOP (1)
								SourceID
						FROM
								@Source
						WHERE
								OperationType = 0
					);

			BEGIN TRANSACTION;

			-- Upsert data into Source table		
			EXEC [Base].[usp_Fwk_UpsertSource]
				@Source,
				@ActivityId,
				@sourceSkId OUTPUT;

			-- Update sourceskid into @CopyTransactionSet
			UPDATE
				@CopyTransactionSet
			SET
			SourceSKID	= @sourceSkId;

			-- Upsert data into TransactionSet table
			EXEC [Base].[usp_Fwk_UpsertTransactionSet]
				@CopyTransactionSet,
				@ActivityId;
			DELETE	FROM
			@CopyTransactionSet;

			-- Update sourceskid into @CopyItem
			UPDATE
				@CopyItem
			SET
			SourceSKID	= @sourceSkId;

			-- Upsert data into Item table
			EXEC [Base].[usp_Fwk_UpsertItem]
				@CopyItem,
				@ActivityId;
			DELETE	FROM
			@CopyItem;

			-- Update SourceTracker to processed
			EXEC [Base].[usp_Fwk_UpdateSourceTracker]
				@ActivityId = @ActivityId,
				@Processed = 1,
				@SourceSkid = @sourceSkId;

			-- Upsert data into PostingEntryState table
			EXEC [Base].[usp_Fwk_UpsertPostingEntryState]
				@CopyPostingEntryState,
				@ActivityId;

			--- Update sourceskid into CopyPostingEntry
			UPDATE
				@CopyPostingEntry
			SET
			SourceSKID	= @sourceSkId;

			-- Upsert data into PostingEntry table
			EXEC [Base].[usp_Fwk_UpsertPostingEntry]
				@CopyPostingEntry,
				@ActivityId;

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
	@level1name = N'usp_Fwk_WriteDataForPostings';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Stored Procedure to save data into the MO database related to posting messages',
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Fwk_WriteDataForPostings';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = [$(Version)],
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Fwk_WriteDataForPostings';
GO

GRANT
	EXECUTE
ON OBJECT::[Base].[usp_Fwk_WriteDataForPostings]
TO
	[WebRole]
AS [dbo];
GO