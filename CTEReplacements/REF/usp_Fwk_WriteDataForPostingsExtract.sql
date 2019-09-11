CREATE PROCEDURE [Base].[usp_Fwk_WriteDataForPostingsExtract]
	(
		@ActivityId			VARCHAR(60),
		@Source				[Base].[udt_Source]					READONLY,
		@Item				[Base].[udt_Item]					READONLY,
		@postingEntryState	[Base].[udt_PostingEntryState]		READONLY,
		@PostingEntry		[Base].[udt_PostingEntry]			READONLY,
		@PreviousState		[Base].[udt_WithTwoStringColumns]	READONLY,	--NOT USED
		@TransactionSet		[Base].[udt_TransactionSet]			READONLY	--NOT USED
	)
/*****************************************************************************************************
* Name				: [Base].[usp_Fwk_WriteDataForPostingsExtract]
* Description		: Stored Procedure to save data into the MO database
					  Upsert SP's are also executed
* Type of Procedure : User-defined stored procedure
* Author			: Gaurav Choudhary
* Creation Date		: 19-Dec-2017
* Last Modified		: Mega Malika
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
* 1.0.0						001         28-Dec-2016   			Initial version
* 1.0.1						002			29-Aug-2017				Changed Item table select query to join with 
													Itemstate on TSetID. This is done to avoid taking old data. 
													Part of MSG06 Represent change fix.
* 1.0.2                     003         19-Dec-2017             Updated the selection criteria for Debit and Credit items
                                                                for Collector and Beneficiary postings
* 1.0.3                     004         04-Jun-2018             Updated the SP for optimisation as a part of timeouts , replaced 
                                                                table variables with temp tables ,making primary key on temp tables,
																updating select queries and replacing sub strings.	 
* 1.0.4						005			21-Jun-2018				No Posting Extract Credit Select Statment Logic changed to include 
																appropriate PostingEntryID aginst the extract	
* 1.0.5						006			14-Jun-2018				Added TransactionSet & PreviousState Udts to keep the framework code consistent
* 1.0.6						007			04-Sep-2018				Restructured PES table update to be on SKID
																Handled parallel PERMs
* 1.0.7						008			11-Sep-2018				Refactored queries for performance
* 1.0.8						009			30-Jan-2019				PBI000000105320 for bug 205838
* 1.0.9						010         08-Apr-2019			    Populated @item with Window2BusinessDate #200277 
*******************************************************************************************************/
AS
	BEGIN

		SET NOCOUNT ON;

		SET XACT_ABORT ON;

		BEGIN TRY

			DECLARE @configPERMNoExtract VARCHAR(50) = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigEAVValue('PERMNoExtract', 'PERM01');

			--Checking for no extract at document level
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
					BEGIN TRANSACTION;
					UPDATE
						PostingEntryState
					SET
					PostingState	= @configPERMNoExtract
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
					COMMIT TRANSACTION;
				END;
			ELSE
				BEGIN

					DECLARE @sourceSkId BIGINT;

					DECLARE
						@configPTMATrigger			VARCHAR(50) = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigEAVValue('PTMATrigger', 'PTMA01'),
						@configPTMARetrigger		VARCHAR(50) = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigEAVValue('PTMARetrigger', 'PTMA01'),
						@configPERMFailure			VARCHAR(50) = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigEAVValue('PERMFailure', 'PERM01'),
						@configPERMAggregateState	VARCHAR(50) = [$(MoConfigDatabase)].[config].sfn_ReadScalarConfigEAVValue('PostingState', 'PERMAggregateState');

					CREATE TABLE #configPTMATrigger
						(
							PostingItemState	SMALLINT
						);

					INSERT INTO
						#configPTMATrigger
					SELECT
						value	AS StringColumn
					FROM
						STRING_SPLIT(@configPTMATrigger, ',');

					DECLARE @ExtractId VARCHAR(MAX) =
								(
									SELECT
										source	.SourceID
									FROM
										@Source AS source
									WHERE
										source.OperationType = 1
								);

					DECLARE @ExtractSourceSkId BIGINT =
								(
									SELECT
										SourceSKID
									FROM
										[Base].Source
									WHERE
										SourceID = @ExtractId
								);

					--Making Temp table for PostingEntry with a column storing substring 
					CREATE TABLE #PostingEntry
						(
							[PostingEntryID]	VARCHAR(30)		NULL,
							[ItemID]			CHAR(25)		NULL,
							[SourceSKID]		BIGINT			NULL,
							[MessageType]		VARCHAR(6)		NULL,
							[Amount]			MONEY			NULL,
							[State]				SMALLINT		NULL,
							[ICNContent]		VARCHAR(MAX)	NULL,
							[OperationType]		INT				NULL,
							[SortCode]			INT				NULL,
							[AccountNumber]		INT				NULL,
							[SubPostingEntryID] VARCHAR(25)		NULL,
							INDEX idx_PostingEntryID_SubPostingEntryID NONCLUSTERED ([SubPostingEntryID], [PostingEntryID])
						);

					INSERT INTO
						#PostingEntry
					SELECT
						[PostingEntryID],
						[ItemID],
						[SourceSKID],
						[MessageType],
						[Amount],
						[State],
						[ICNContent],
						[OperationType],
						[SortCode],
						[AccountNumber],
						SUBSTRING(PostingEntryID, 1, 25)
					FROM
						@PostingEntry;

					--Inserting Records in @CopyItem From Input Item andPostingEntryState table
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
						item.[Window2BusinessDate]
					FROM
						@Item				AS item
					INNER JOIN
						@postingEntryState	AS pstState
					ON
						item.ItemID = pstState.ItemID;

					-- Get TransactionSetId for all the items from the Item table
					UPDATE
						@CopyItem
					SET
					TsetID	= itemState.TsetID,
						Window2BusinessDate = itemState.Window2BusinessDate
					FROM
						@CopyItem			AS copyItem
					LEFT JOIN
						[Base].ItemState	AS itemState
					ON
						itemState.ItemID = copyItem.ItemID;

					--------
					DECLARE @CopyPostingEntity [Base].[udt_PostingEntry];

					INSERT INTO
						@CopyPostingEntity
						(
							[PostingEntryID],
							[ItemID],
							[SourceSKID],
							[MessageType],
							[Amount],
							[State],
							[ICNContent],
							[OperationType],
							[SortCode],
							[AccountNumber]
						)
					SELECT
						[PostingEntryID],
						[ItemID],
						[SourceSKID],
						[MessageType],
						[Amount],
						[State],
						[ICNContent],
						[OperationType],
						[SortCode],
						[AccountNumber]
					FROM
						#PostingEntry;

					------ Get the Operation and Posting Entry in PostingEntryState table
					DECLARE @CopyPostingEntryState [Base].[udt_PostingEntryState];
					DECLARE @CopyPostingEntryStateDebit [Base].[udt_PostingEntryState];
					DECLARE @CopyPostingEntryStateCredit [Base].[udt_PostingEntryState];
					DECLARE @CopyPostingEntryStateFinal [Base].[udt_PostingEntryState];

					INSERT INTO
						@CopyPostingEntryState
						(
							[ItemID],
							[TsetID],
							[InternalMessageType],
							[PostingState],
							[OperationType],
							[PostingSourceDateTime],
							[ClearingState],
							[Window1BusinessDate],
							[Window2BusinessDate],
							[PostingDirtyFlag],
							[RowId],
							[PostingEntryStateSKID]
						)
					SELECT
						pp	.[ItemID],
						itmState.TsetID,
						pp.[InternalMessageType],
						pp.[PostingState],
						pp.[OperationType],
						pp.[PostingSourceDateTime],
						pst.ClearingState,
						pst.Window1BusinessDate,
						pst.Window2BusinessDate,
						pst.PostingDirtyFlag,
						ROW_NUMBER() OVER (ORDER BY
											(
												SELECT
													0
											)
										) AS RowId,
						pst.[PostingEntryStateSKID]
					FROM
						@postingEntryState			AS pp
					INNER JOIN
						[Base].PostingEntryState	AS pst
					ON
						pp.ItemID = pst.ItemID
					INNER JOIN
						[Base].ItemState			AS itmState
					ON
						itmState.ItemID = pst.ItemID
					WHERE
						(
							EXISTS
						(
							SELECT
								1
							FROM
								#configPTMATrigger
							WHERE
								PostingItemState = pst.PostingState
						)
					AND		pst.SourceID IN
								(
									SELECT
										SourceID
									FROM
										@Source
									WHERE
										OperationType = 1
								)
						)
					OR	pst.PostingState = @configPERMAggregateState;	-- Todo Check later how aggregation will impact parallel trigerring

					UPDATE
						@CopyPostingEntryState
					SET
					SourceID	=
							(
								SELECT
									SourceID
								FROM
									@Source
								WHERE
									MessageType = 'PERM01'
							);

					IF EXISTS
						(
							SELECT
								*
							FROM
								@CopyPostingEntryState
							WHERE
								PostingState IN ( @configPTMARetrigger,
													@configPERMFailure,
													@configPERMNoExtract,
													@configPERMAggregateState
												)
							AND PostingEntryID IS NULL
						)
						BEGIN
							INSERT	INTO
								@CopyPostingEntryStateFinal
								(
									[SourceID],
									[ItemID],
									[TsetID],
									[InternalMessageType],
									[PostingEntryID],
									[ClearingState],
									[PostingState],
									[OperationType],
									[PostingSourceDateTime],
									[Window1BusinessDate],
									[Window2BusinessDate],
									[PostingDirtyFlag],
									[RowId],
									[PostingEntryStateSKID]
								)
							SELECT
								copyState.SourceID,
								copyState.ItemID,
								copyState.TsetID,
								copyState.InternalMessageType,
								copyState.PostingEntryID,
								copyState.ClearingState,
								copyState.PostingState,
								copyState.OperationType,
								copyState.PostingSourceDateTime,
								copyState.Window1BusinessDate,
								copyState.Window2BusinessDate,
								copyState.PostingDirtyFlag,
								ROW_NUMBER() OVER (ORDER BY
													(
														SELECT
															0
													)
												) AS RowId,
								copyState.PostingEntryStateSKID
							FROM
								@CopyPostingEntryState AS copyState
							WHERE
								PostingState IN ( @configPTMARetrigger,
													@configPERMFailure,
													@configPERMNoExtract,
													@configPERMAggregateState
												)
							AND PostingEntryID IS NULL;

						END;

					-- Get the final count in the credit items table variable.
					DECLARE @EntryStateFinalCount INT = @@ROWCOUNT;

					--Added Join on ItemState and Gender so that only Debit Items are selected
					SELECT
						ROW_NUMBER	() OVER (PARTITION BY
											copyPst.ItemID
											ORDER BY
											(
												SELECT
													0
											)
										) AS SNo,
						copyPst.ItemID,
						[pst].[PostingEntryID]
					INTO
						#Temp
					FROM
						#PostingEntry			AS pst
					INNER JOIN
						@CopyPostingEntryState	AS copyPst
					ON
						copyPst.ItemID = [pst].[SubPostingEntryID]
					INNER JOIN
						Base.ItemState			AS ist
					ON
						ist.ItemID = copyPst.ItemID
					WHERE
						ist.Gender = 1;

					CREATE CLUSTERED INDEX ci_ItemID
					ON #Temp (ItemID);

					INSERT INTO
						@CopyPostingEntryStateDebit
						(
							[SourceID],
							[ItemID],
							[TsetID],
							[InternalMessageType],
							[PostingEntryID],
							[ClearingState],
							[PostingState],
							[OperationType],
							[PostingSourceDateTime],
							[Window1BusinessDate],
							[Window2BusinessDate],
							[PostingDirtyFlag],
							[RowId],
							[PostingEntryStateSKID]
						)
					SELECT
						copyState.SourceID,
						copyState.ItemID,
						copyState.TsetID,
						copyState.InternalMessageType,
						[tem].[PostingEntryID],
						copyState.ClearingState,
						copyState.PostingState,
						copyState.OperationType,
						copyState.PostingSourceDateTime,
						copyState.Window1BusinessDate,
						copyState.Window2BusinessDate,
						copyState.PostingDirtyFlag,
						ROW_NUMBER() OVER (ORDER BY
											(
												SELECT
													0
											)
										) AS RowId,
						copyState.PostingEntryStateSKID
					FROM
						@CopyPostingEntryState	AS copyState
					INNER JOIN
						#Temp					AS tem
					ON
						copyState.ItemID = [tem].[ItemID];

					--Updated the condition to select the Items where we get Extracts for Credit Items. 
					SELECT
						ROW_NUMBER	() OVER (PARTITION BY
											copyPst.ItemID
											ORDER BY
											(
												SELECT
													0
											)
										) AS SNo,
						copyPst.ItemID,
						[pst].[PostingEntryID]
					INTO
						#TA
					FROM
						#PostingEntry			AS pst
					INNER JOIN
						Base.ItemState			AS ist
					ON
						ist.ItemID = [pst].[SubPostingEntryID]
					INNER JOIN
						@CopyPostingEntryState	AS copyPst
					ON
						copyPst.ItemID = ist.ItemID
					WHERE
						ist.Gender = 0
					AND EXISTS
						(
							SELECT
								1
							FROM
								#PostingEntry
							WHERE
								SubPostingEntryID = copyPst.ItemID
						);

					CREATE CLUSTERED INDEX ci_ItemID
					ON #TA (ItemID);

					INSERT INTO
						@CopyPostingEntryStateCredit
						(
							[SourceID],
							[ItemID],
							[TsetID],
							[InternalMessageType],
							[PostingEntryID],
							[ClearingState],
							[PostingState],
							[OperationType],
							[PostingSourceDateTime],
							[Window1BusinessDate],
							[Window2BusinessDate],
							[PostingDirtyFlag],
							[RowId],
							[PostingEntryStateSKID]
						)
					SELECT
						copyState.SourceID,
						copyState.ItemID,
						copyState.TsetID,
						copyState.InternalMessageType,
						[tem].[PostingEntryID],
						copyState.ClearingState,
						copyState.PostingState,
						copyState.OperationType,
						copyState.PostingSourceDateTime,
						copyState.Window1BusinessDate,
						copyState.Window2BusinessDate,
						copyState.PostingDirtyFlag,
						ROW_NUMBER() OVER (ORDER BY
											(
												SELECT
													0
											)
										) AS RowId,
						copyState.PostingEntryStateSKID
					FROM
						@CopyPostingEntryState	AS copyState
					INNER JOIN
						#TA						AS tem
					ON
						copyState.ItemID = [tem].[ItemID];

					-- Get the final count in the credit items table variable.
					DECLARE @creditItemCount INT = @@ROWCOUNT;

					--Added new selection to select Credit Item Extracts against Debits ( for Single Debit Multi Credit scenario in Beneficiary)
					SELECT
						[rankedTable].[ItemID],
						[rankedTable].[PostingEntryID],
						[rankedTable].[State]
					INTO
						#TA2
					FROM
						(
							SELECT
								copyPst.ItemID,
								[pst].[PostingEntryID],
								[pst].[State],
								ROW_NUMBER() OVER (PARTITION BY ([pst].[PostingEntryID])
													ORDER BY
													(
														SELECT
															0
													)
												) AS RowId
							FROM
								#PostingEntry			AS pst
							INNER JOIN
								Base.ItemState			AS ist
							ON
								ist.ItemID = [pst].[SubPostingEntryID]
							INNER JOIN
								@CopyPostingEntryState	AS copyPst
							ON
								copyPst.TsetID = ist.TsetID
							WHERE
								ist.Gender = 0
						) AS rankedTable
					WHERE
						[rankedTable].[RowId] = 1;

					CREATE CLUSTERED INDEX ci_ItemID
					ON #TA2 (ItemID);

					INSERT INTO
						@CopyPostingEntryStateCredit
						(
							[SourceID],
							[ItemID],
							[TsetID],
							[InternalMessageType],
							[PostingEntryID],
							[ClearingState],
							[PostingState],
							[OperationType],
							[PostingSourceDateTime],
							[Window1BusinessDate],
							[Window2BusinessDate],
							[PostingDirtyFlag],
							[RowId],
							[PostingEntryStateSKID]
						)
					SELECT
						copyState.SourceID,
						copyState.ItemID,
						copyState.TsetID,
						copyState.InternalMessageType,
						[tem].[PostingEntryID],
						copyState.ClearingState,
						[tem].[State],
						copyState.OperationType,
						copyState.PostingSourceDateTime,
						copyState.Window1BusinessDate,
						copyState.Window2BusinessDate,
						copyState.PostingDirtyFlag,
						@creditItemCount + ROW_NUMBER() OVER (ORDER BY
																(
																	SELECT
																		0
																)
															) AS RowId,
						copyState.PostingEntryStateSKID
					FROM
						@CopyPostingEntryState	AS copyState
					INNER JOIN
						#TA2					AS tem
					ON
						copyState.ItemID = [tem].[ItemID];

					INSERT INTO
						@CopyPostingEntryStateFinal
						(
							[SourceID],
							[ItemID],
							[TsetID],
							[InternalMessageType],
							[PostingEntryID],
							[ClearingState],
							[PostingState],
							[OperationType],
							[PostingSourceDateTime],
							[Window1BusinessDate],
							[Window2BusinessDate],
							[PostingDirtyFlag],
							[RowId],
							[PostingEntryStateSKID]
						)
					SELECT
						copyStateFinal	.SourceID,
						copyStateFinal.ItemID,
						copyStateFinal.TsetID,
						copyStateFinal.InternalMessageType,
						copyStateFinal.PostingEntryID,
						copyStateFinal.ClearingState,
						copyStateFinal.PostingState,
						copyStateFinal.OperationType,
						copyStateFinal.PostingSourceDateTime,
						copyStateFinal.Window1BusinessDate,
						copyStateFinal.Window2BusinessDate,
						copyStateFinal.PostingDirtyFlag,
						@EntryStateFinalCount + ROW_NUMBER() OVER (ORDER BY
																	(
																		SELECT
																			0
																	)
																) AS RowId,
						copyStateFinal.PostingEntryStateSKID
					FROM
						(
							SELECT	DISTINCT
									copyStateDebit.SourceID,
									copyStateDebit.ItemID,
									copyStateDebit.TsetID,
									copyStateDebit.InternalMessageType,
									copyStateDebit.PostingEntryID,
									copyStateDebit.ClearingState,
									copyStateDebit.PostingState,
									copyStateDebit.OperationType,
									copyStateDebit.PostingSourceDateTime,
									copyStateDebit.Window1BusinessDate,
									copyStateDebit.Window2BusinessDate,
									copyStateDebit.PostingDirtyFlag,
									copyStateDebit.PostingEntryStateSKID
							FROM
									@CopyPostingEntryStateDebit AS copyStateDebit
							INNER JOIN
									[Base]	.PostingEntryState	AS postState
							ON
								copyStateDebit.ItemID = postState.ItemID
							UNION ALL
							SELECT	DISTINCT
									copyStateCredit.SourceID,
									copyStateCredit.ItemID,
									copyStateCredit.TsetID,
									copyStateCredit.InternalMessageType,
									copyStateCredit.PostingEntryID,
									copyStateCredit.ClearingState,
									copyStateCredit.PostingState,
									copyStateCredit.OperationType,
									copyStateCredit.PostingSourceDateTime,
									copyStateCredit.Window1BusinessDate,
									copyStateCredit.Window2BusinessDate,
									copyStateCredit.PostingDirtyFlag,
									copyStateCredit.PostingEntryStateSKID
							FROM
									@CopyPostingEntryStateCredit	AS copyStateCredit
							INNER JOIN
									[Base]	.PostingEntryState		AS postState
							ON
								copyStateCredit.ItemID = postState.ItemID
						) AS copyStateFinal;
					WITH
						CTE
					AS
						(
							SELECT
								ROW_NUMBER	() OVER (PARTITION BY
													cp.ItemID
													ORDER BY
													(
														SELECT
															0
													)
												) AS RowNum,
								cp.OperationType
							FROM
								@CopyPostingEntryStateFinal AS cp
						)
					UPDATE
						CTE
					SET
					OperationType	= 0
					WHERE
						[CTE].[RowNum] > 1;

					BEGIN TRANSACTION;

					--Upsert data into Source table
					EXEC [Base].[usp_Fwk_UpsertSource]
						@Source,
						@ActivityId,
						@sourceSkId OUTPUT;

					UPDATE
						@CopyItem
					SET
					SourceSKID	= @sourceSkId;

					EXEC [Base].[usp_Fwk_UpsertItem]
						@CopyItem,
						@ActivityId;

					UPDATE
						@CopyPostingEntity
					SET
					SourceSKID	= @sourceSkId;

					EXEC [Base].[usp_Fwk_UpsertPostingEntry]
						@CopyPostingEntity,
						@ActivityId;

					--Update SourceTracker to processed
					EXEC [Base].[usp_Fwk_UpdateSourceTracker]
						@ActivityId = @ActivityId,
						@Processed = 1,
						@SourceSkid = @sourceSkId;

					EXEC [Base].[usp_Fwk_UpsertPostingEntryState]
						@CopyPostingEntryStateFinal,
						@ActivityId;

					COMMIT TRANSACTION;
				END;
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
		--deleting the temp table
		IF OBJECT_ID('tempdb..#PostingEntry') IS NOT NULL
			DROP TABLE #PostingEntry;

		SET NOCOUNT OFF;
	END;
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'iPSL.ICS.MO.DB',
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Fwk_WriteDataForPostingsExtract';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Stored Procedure to save data into the MO database',
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Fwk_WriteDataForPostingsExtract';
GO

EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = [$(Version)],
	@level0type = N'SCHEMA',
	@level0name = N'Base',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Fwk_WriteDataForPostingsExtract';
GO

GRANT
	EXECUTE
ON OBJECT::[Base].[usp_Fwk_WriteDataForPostingsExtract]
TO
	[WebRole]
AS [dbo];
GO