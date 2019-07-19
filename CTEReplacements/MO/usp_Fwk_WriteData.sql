CREATE  PROCEDURE [Base].[usp_Fwk_WriteData]  
(  
	@ActivityId VARCHAR(60),  
	@Source [Base].[udt_Source] READONLY,  
	@TransactionSet [Base].[udt_TransactionSet] READONLY,  
	@Item [Base].[udt_Item] READONLY,  
	@TransactionSetState [Base].[udt_TransactionSetState] READONLY,  
	@ItemState [Base].[udt_ItemState] READONLY,  
	@PreviousState [Base].[udt_WithTwoStringColumns] READONLY  
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
  
		DECLARE @sourceSkId BIGINT  
		DECLARE @MessageType VARCHAR(6);  
		DECLARE @CurrentDate DATETIME  
		DECLARE @PostingDirtyFlag SMALLINT   
		SELECT  @PostingDirtyFlag= CurrentVal  From [$(MoConfigDatabase)].[Config].[tfn_GetEntityFlowFromConfig] ('DF_CR')  
	 
		CREATE TABLE #ItemState  
		(  
			[CollectorRoleFlag] [bit] NULL,  
			[PayerRoleFlag] [bit] NULL,  
			[BeneficiaryRoleFlag] [bit] NULL,  
			[CollectorItemState] [smallint] NULL,  
			[PayerItemState] [smallint] NULL,  
			[BeneficiaryItemState] [smallint] NULL,  
			[CollectorItemDirtyFlag] [bit] NULL,  
			[PayerItemDirtyFlag] [bit] NULL,  
			[BeneficiaryItemDirtyFlag] [bit] NULL,  
			[CollectorItemBatchedFlag] [bit] NULL,  
			[PayerItemBatchedFlag] [bit] NULL,  
			[BeneficiaryItemBatchedFlag] [char](18) NULL,  
			[ItemID] [char](25) NOT NULL,  
			[OperationType] [int] NULL,  
			[Gender] [smallint] NULL,  
			[TsetID] [char](24) NULL,  
			[CollectorSourceDateTime] [datetime2](3) NULL,  
			[PayerSourceDateTime] [datetime2](3) NULL,  
			[BeneficiarySourceDateTime] [datetime2](3) NULL,  
			[Window1BusinessDate] [date] NULL,  
			[Window2BusinessDate] [date] NULL,  
			[AlwaysUpdateWindowDates] [bit] NULL,  
			[PayerUpdatedDatetime] [datetime2](3) NULL,  
			[BeneficiaryUpdatedDatetime] [datetime2](3) NULL,  
			[CollectorUpdatedDatetime] [datetime2](3) NULL,  
			[ItemType] [char](4) NULL,  
			[MSG06Flag] [int] NULL,  
			[MSG13Flag] [int] NULL,  
			[IcsAmount] [decimal](11, 2) NULL,  
			[RowId] [int] NOT NULL  
		)  
	  
  
	DECLARE @configAutoPostingClearingState SMALLINT    
	 = [$(MoConfigDatabase)].[Config].sfn_ReadScalarConfigEAVValue('CMPaidDecision', 'CMCM01');   

	EXEC Base.usp_GetCurrentDateTime @CurrentDate OUTPUT;  

	DECLARE @CopySource [Base].[udt_Source]  

	INSERT INTO 
		@CopySource  
	SELECT   
		sourceInput.[SourceID]
		,sourceInput.[MessageType]
		,sourceInput.[ICNContent]
		,sourceInput.[SourceState]
		,sourceInput.[SourceStateRevision]
		,sourceInput.[SourceDirtyFlag]
		,sourceInput.[SourceBatchedFlag]
		,sourceInput.[ISOContent]
		,sourceInput.[CreatedDatetime]
		,sourceInput.[UpdatedDatetime]
		,sourceInput.[RelatedSourceID]
		,sourceInput.[OperationType]        
	FROM 
		@Source sourceInput  
  
 -- Select only the transactions with correct state transition  
	DECLARE @CopyTransactionSetState [Base].[udt_TransactionSetState]  

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
    
	;WITH CTE AS (  
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY TsetID,OperationType ORDER BY (SELECT 0)) RowNumber   
	FROM 
		@CopyTransactionSetState  
	)  
  
	DELETE FROM CTE  
	WHERE RowNumber > 1;  

	--Update the UpdatedDatetime based on Role  

	UPDATE 
		@CopyTransactionSetState  
	SET 
		PayerUpdatedDatetime =	CASE  
									WHEN PayerRoleFlag =1  
									THEN @CurrentDate ELSE PayerUpdatedDatetime  
								END,  
		BeneficiaryUpdatedDatetime =	CASE  
											WHEN BeneficiaryRoleFlag =1  
											THEN @CurrentDate ELSE BeneficiaryUpdatedDatetime  
										END,  
    CollectorUpdatedDatetime =	CASE  
									WHEN CollectorRoleFlag =1  
									THEN @CurrentDate ELSE CollectorUpdatedDatetime  
								END  
  
	 --Update SourceSkId for the TransactionSet table  
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
			,[ColltngPtcptId]
		)  
	SELECT  
		CASE   
			WHEN  tSetState.NewTsetID IS NOT NULL 
			THEN tSetState.[NewTsetID]  
			ELSE tSet.[TsetID] 
		END,               
		tSet.[ISOContent],           
		tSet.[SourceSKID],           
		tSet.[OperationType],        
		tSet.[NodeType],             
		tSet.[InternalMessageType],  
		tSet.[State],  
		tset.[ColltngPtcptId]  
	FROM 
		@TransactionSet tSet  
	INNER JOIN 
		@CopyTransactionSetState tSetState  
	ON 
		tSet.TsetID = tSetState.TsetID  
  
  
	;WITH CTE AS 
	(  
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY TsetID ORDER BY (SELECT 0)) RowNumber   
		FROM 
			@CopyTransactionSet  
	)  
  
	DELETE FROM 
		CTE  
	WHERE 
		RowNumber > 1;  
  
	UPDATE 
		@CopyTransactionSet  
	SET 
		State =	CASE   
					WHEN sta.PayerTsetState IS NOT NULL 
					THEN sta.PayerTsetState  
					WHEN sta.CollectorTsetState IS NOT NULL 
					THEN sta.CollectorTsetState  
					WHEN sta.BeneficiaryTsetState IS NOT NULL 
					THEN sta.BeneficiaryTsetState 
				END  
	FROM 
		@TransactionSetState sta  
	INNER JOIN 
		@CopyTransactionSet copyTransaction  
	ON 
		sta.TsetID = copyTransaction.TsetID  
  
	IF EXISTS(SELECT 1 FROM @ItemState where OperationType = 0)  
	BEGIN  
   
	INSERT INTO 
		#ItemState   
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
		,itemStateInput.[ItemID],itemStateInput.[OperationType],itemStateInput.[Gender]
		,itemStateInput.TsetID
		,itemStateInput.[CollectorSourceDateTime],itemStateInput.[PayerSourceDateTime],itemStateInput.[BeneficiarySourceDateTime]
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
	WHERE 
		itemStateInput.OperationType = 0  
  
	UPDATE 
		tmp 
	SET   
		CollectorRoleFlag = ISNULL(tmp.[CollectorRoleFlag], itemStateInput.[CollectorRoleFlag]),
		PayerRoleFlag = ISNULL( tmp.PayerRoleFlag, itemStateInput.[PayerRoleFlag]),
		BeneficiaryRoleFlag = ISNULL( tmp.BeneficiaryRoleFlag, itemStateInput.[BeneficiaryRoleFlag]),  
		CollectorItemState = ISNULL( tmp.CollectorItemState, itemStateInput.[CollectorItemState]),
		PayerItemState = ISNULL(tmp.PayerItemState, itemStateInput.[PayerItemState]), 
		BeneficiaryItemState = ISNULL(tmp.BeneficiaryItemState, itemStateInput.[BeneficiaryItemState]),         
		CollectorItemDirtyFlag = ISNULL(tmp.CollectorItemDirtyFlag, itemStateInput.[CollectorItemDirtyFlag]),
		PayerItemDirtyFlag = ISNULL(tmp.PayerItemDirtyFlag, itemStateInput.[PayerItemDirtyFlag]),
		BeneficiaryItemDirtyFlag = ISNULL(tmp.BeneficiaryItemDirtyFlag, itemStateInput.[BeneficiaryItemDirtyFlag]),   
		CollectorItemBatchedFlag = ISNULL(tmp.CollectorItemBatchedFlag, itemStateInput.[CollectorItemBatchedFlag]),
		PayerItemBatchedFlag = ISNULL(tmp.PayerItemBatchedFlag, itemStateInput.[PayerItemBatchedFlag]),
		BeneficiaryItemBatchedFlag = ISNULL(tmp.BeneficiaryItemBatchedFlag, itemStateInput.[BeneficiaryItemBatchedFlag]),  
		ItemID = ISNULL(tmp.ItemID,itemStateInput.[ItemID]),
		OperationType = ISNULL(tmp.OperationType,itemStateInput.[OperationType]),
		Gender = ISNULL(tmp.Gender,itemStateInput.[Gender]),                             
		TsetID = ISNULL(tmp.TsetID, itemStateInput.TsetID),
		CollectorSourceDateTime = ISNULL( tmp.CollectorSourceDateTime, itemStateInput.[CollectorSourceDateTime]),
		PayerSourceDateTime = ISNULL(tmp.PayerSourceDateTime,itemStateInput.[PayerSourceDateTime]),
		BeneficiarySourceDateTime = ISNULL(tmp.BeneficiarySourceDateTime, itemStateInput.[BeneficiarySourceDateTime]),   
		Window1BusinessDate = ISNULL(tmp.Window1BusinessDate,itemStateInput.[Window1BusinessDate]), 
		Window2BusinessDate =  ISNULL(tmp.Window2BusinessDate, itemStateInput.[Window2BusinessDate]),
		AlwaysUpdateWindowDates = ISNULL(tmp.AlwaysUpdateWindowDates, itemStateInput.[AlwaysUpdateWindowDates]),  
		PayerUpdatedDatetime = ISNULL(tmp.PayerUpdatedDatetime, itemStateInput.[PayerUpdatedDatetime]),
		BeneficiaryUpdatedDatetime = ISNULL( tmp.BeneficiaryUpdatedDatetime, itemStateInput.[BeneficiaryUpdatedDatetime]),
		CollectorUpdatedDatetime = ISNULL( tmp.CollectorUpdatedDatetime,itemStateInput.[CollectorUpdatedDatetime]),  
		ItemType = ISNULL(tmp.ItemType, itemStateInput.[ItemType]),
		MSG06Flag = ISNULL( tmp.MSG06Flag, itemStateInput.[MSG06Flag]),
		MSG13Flag = ISNULL(tmp.MSG13Flag, itemStateInput.[MSG13Flag]),
		IcsAmount = ISNULL(tmp.IcsAmount, itemStateInput.[IcsAmount]),
		RowId = ISNULL( tmp.RowId, itemStateInput.[RowId])  
	FROM 
		@ItemState itemStateInput  
	INNER JOIN 
		#ItemState tmp
	ON 
		tmp.ItemID = itemStateInput.ItemID 
	AND 
		itemStateInput.OperationType = 1
  
	INSERT INTO 
		#ItemState   
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
		itemStateInput.[CollectorRoleFlag],itemStateInput.[PayerRoleFlag],itemStateInput.[BeneficiaryRoleFlag],itemStateInput.[CollectorItemState],itemStateInput.[PayerItemState],itemStateInput.[BeneficiaryItemState],         
		itemStateInput.[CollectorItemDirtyFlag],itemStateInput.[PayerItemDirtyFlag],itemStateInput.[BeneficiaryItemDirtyFlag],           
		itemStateInput.[CollectorItemBatchedFlag],itemStateInput.[PayerItemBatchedFlag],itemStateInput.[BeneficiaryItemBatchedFlag],itemStateInput.[ItemID],itemStateInput.[OperationType],itemStateInput.[Gender],                             
		itemStateInput.TsetID
		,itemStateInput.[CollectorSourceDateTime],itemStateInput.[PayerSourceDateTime],itemStateInput.[BeneficiarySourceDateTime],   
		itemStateInput.[Window1BusinessDate],itemStateInput.[Window2BusinessDate],itemStateInput.[AlwaysUpdateWindowDates],  
		itemStateInput.[PayerUpdatedDatetime],itemStateInput.[BeneficiaryUpdatedDatetime],itemStateInput.[CollectorUpdatedDatetime], itemStateInput.[ItemType],itemStateInput.[MSG06Flag],itemStateInput.[MSG13Flag], itemStateInput.[IcsAmount], itemStateInput.[RowId]  
	FROM 
		@ItemState itemStateInput  
	WHERE 
		itemStateInput.OperationType = 1  
	AND 
		NOT EXISTS	(
						SELECT 
							1 
						FROM 
							#ItemState itemState 
						WHERE 
							ItemStateInput.ItemID = itemState.ItemID
					)
  
 END  

 ELSE  

 BEGIN  

	INSERT INTO #ItemState   
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
		,itemStateInput.[ItemID]
		,itemStateInput.[OperationType]
		,itemStateInput.[Gender]
		,itemStateInput.TsetID
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
	WHERE 
		itemStateInput.OperationType = 1  

END 
  
	;WITH CTE AS 
	(  
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY ItemID,OperationType  ORDER BY (SELECT 0)) RowNumber   
		FROM 
			#ItemState  
	)
	DELETE FROM 
		CTE  
	WHERE 
		RowNumber > 1;  

	-- select the items having correct transitions.  
	DECLARE @CopyItemState [Base].[udt_ItemState]  
	
	INSERT INTO @CopyItemState  
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
		,itemStateInput.[ItemID]
		,itemStateInput.[OperationType]
		,itemStateInput.[Gender]
		,itemStateInput.TsetID
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
		#ItemState itemStateInput     
  
	--Update the UpdatedDatetime based on Role  
	UPDATE 
		@CopyItemState  
	SET 
		PayerUpdatedDatetime =	CASE  
									WHEN PayerRoleFlag =1  
									THEN @CurrentDate 
									ELSE PayerUpdatedDatetime  
								END,  
		BeneficiaryUpdatedDatetime =	CASE  
										WHEN BeneficiaryRoleFlag =1  
										THEN @CurrentDate 
										ELSE BeneficiaryUpdatedDatetime  
									END,  
		CollectorUpdatedDatetime =	CASE  
									WHEN CollectorRoleFlag =1  
									THEN @CurrentDate 
									ELSE CollectorUpdatedDatetime  
								END  
   
	--Update SourceSkId for the Item table  
	DECLARE @CopyItem [Base].[udt_Item]  

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
		itemState.[Window2BusinessDate]     
	FROM 
		@Item item  
	INNER JOIN 
		#ItemState itemState  
	ON 
		item.ItemID = itemState.ItemID  
  
	;WITH CTE AS 
	(  
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY ItemID, NodeType ORDER BY (SELECT 0)) RowNumber   
		FROM 
			@CopyItem  
	)  
  
	DELETE FROM 
		CTE  
	WHERE 
		RowNumber > 1;  
  
	-- Get TransactionSetId for all the items from the Item table  
	UPDATE 
		@CopyItem  
	SET 
		TsetID =	CASE 
						WHEN copyItem.TsetID IS NULL 
						THEN sta.TsetID 
						ELSE copyItem.TsetID 
					END,
		Window2BusinessDate =	CASE 
									WHEN copyItem.Window2BusinessDate IS NULL 
									THEN sta.Window2BusinessDate 
									ELSE copyItem.Window2BusinessDate 
								END
	FROM 
		[Base].ItemState sta  
	INNER JOIN 
		@CopyItem copyItem  
	ON 
		sta.ItemID = copyItem.ItemID  
	WHERE 
		sta.TsetID IS NOT NULL  
  
	UPDATE 
		@CopyItem  
	SET 
		[State] =	CASE 
						WHEN sta.PayerItemState IS NOT NULL 
						THEN sta.PayerItemState  
						WHEN sta.CollectorItemState IS NOT NULL 
						THEN sta.CollectorItemState  
						WHEN sta.BeneficiaryItemState IS NOT NULL 
						THEN sta.BeneficiaryItemState 
					END,  
		TsetID =	CASE 
						WHEN sta.TsetID IS NOT NULL 
						THEN sta.TsetID 
						ELSE copyItem.TsetID 
					END  
	FROM 
		#ItemState sta  
	INNER JOIN 
		@CopyItem copyItem  
	ON 
		sta.ItemID = copyItem.ItemID  
  
	--Create a udt to be used to upsert EntityPostingState table   
	DECLARE @EntityStateFROM VARCHAR(400)  

	--Read the postable entity states from Message Parameters  
	SELECT  
		@EntityStateFROM = EntityStateTransitionFrom  
	FROM  
		[$(MoConfigDatabase)].[Config].[tfn_ReadMessageParameters]('PTMA01')   
   
	--Read the Business Date from Config  
	DECLARE @configBusinessDate DATE  
	= [$(MoConfigDatabase)].[Config].sfn_ReadScalarConfigEAVValue('ControlM', 'BD');  

	-- Insert Posting Data for Case Management ( CMCM01)  
	DECLARE @CopyPostingEntryState [Base].[udt_PostingEntryState]  

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
	SELECT  DISTINCT  
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
		ROW_NUMBER() OVER( ORDER BY [source].[SourceID]) as 'RowId'  
	FROM 
		@CopySource [source]  
	WHERE 
		[source].SourceState IN (@configAutoPostingClearingState)--CMCM01 source entity state  
  
	IF EXISTS(SELECT 1 FROM @CopyPostingEntryState)  
	BEGIN  
		UPDATE 
			@CopyPostingEntryState  
		SET 
			SourceID =	(
							SELECT 
								SourceID 
							FROM 
								@CopySource
						)  
	END  
  
	DECLARE @CopyReceiveStagingTset [Base].[udt_ReceiveStagingTset]  

	INSERT INTO 
		@CopyReceiveStagingTset  
		(  
			[TsetID] ,  
			[ISOContent],  
			[ColltngPtcptId],  
			[OperationType],  
			[CollectorRoleFlag],  
			[BeneficiaryRoleFlag]  
		)  
	SELECT   
		[transSet].[TsetID],            
		[transSet].[ISOContent],                
		[transSet].[ColltngPtcptId],               
		[transSet].[OperationType],  
		NULL,  
		NULL  
	FROM 
		@CopyTransactionSet [transSet]  
	WHERE 
		[transSet].[InternalMessageType]='04SM01'  

	UNION ALL  
	
		SELECT   
			[transSetState].[TsetID],            
			NULL,  
			NULL,  
			[transSetState].[OperationType],  
			[transSetState].[CollectorRoleFlag],  
			[transSetState].[BeneficiaryRoleFlag]  
		FROM 
			@CopyTransactionSetState [transSetState]  
		JOIN  
			@CopyItem [itm]  
		ON 
			[transSetState].[TsetID] = [itm].[TsetID]  
		WHERE      
			[itm].[InternalMessageType] = '04MM01'  
     
    
	BEGIN TRANSACTION  
    
		--Updating Message Type when Upsert for Item is called and TransactionSet is not to be Upserted  
		SET @MessageType = (SELECT TOP 1 InternalMessageType FROM @CopyItem)   

		--Updating Message Type when Upsert for TransactionSet is called and Item is not to be Upserted  
		If(@MessageType IS NULL)  
		BEGIN  
			SET @MessageType = (SELECT TOP 1 InternalMessageType FROM @CopyTransactionSet)  
		END  

		--Do not process source insert for 04MM01 as handled in UpsertReceiveStaginTset  
		If (@MessageType <> '04MM01' OR @MessageType IS NULL)  
		BEGIN  
			--Upsert data into Source table    
			EXEC [Base].[usp_Fwk_UpsertSource] @CopySource, @ActivityId, @sourceSkId OUTPUT    
			DELETE FROM @CopySource  
		END  

		--Do not process insert into TransactionSetState or TransactionSet for 04SM01 as not required  
		IF (@MessageType <> '04SM01' OR @MessageType IS NULL)  
		BEGIN  

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
			EXEC [Base].[usp_Fwk_UpsertTransactionSetState] @CopyTransactionSetState,@ActivityId  
			DELETE FROM @CopyTransactionSetState  

			--Retreive Source SKID from [Base].[usp_Fwk_UpsertSource] called above and update into @CopyTransactionSet  
			UPDATE 
				@CopyTransactionSet  
			SET 
				SourceSKID = @sourceSkId  

			--Upsert data into TransactionSet table  
			EXEC [Base].[usp_Fwk_UpsertTransactionSet] @CopyTransactionSet,@ActivityId  
			DELETE FROM @CopyTransactionSet  

		END  

		--Update the flag  
		UPDATE 
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
		EXEC [Base].[usp_Fwk_UpsertItemState] @CopyItemState,@ActivityId  
		DELETE FROM @CopyItemState  

		--Do not process Item or SourceTracker insert for 04MM01 as handled in UpsertReceiveStagingTset  
		IF (@MessageType <> '04MM01' OR @MessageType IS NULL)  
		BEGIN  

			--Upsert data into Item table  
			UPDATE 
				@CopyItem  
			SET 
				SourceSKID = @sourceSkId  

			EXEC [Base].[usp_Fwk_UpsertItem] @CopyItem,@ActivityId  
			DELETE FROM @CopyItem  

			--Upsert data into EntityPostingState table  
			EXEC [Base].[usp_Fwk_UpsertPostingEntryState] @CopyPostingEntryState,@ActivityId  
			DELETE FROM @CopyPostingEntryState  

			--Update SourceTracker to processed  
			EXEC [Base].[usp_Fwk_UpdateSourceTracker] @ActivityId = @ActivityId, @Processed=1, @SourceSkid = @sourceSkId  

		END 

		--Upsert data into ReceiveStagingTset table  
		UPDATE 
			@CopyReceiveStagingTset  
		SET 
			SourceSKID = @sourceSkId  

		EXEC [Base].[usp_Fwk_UpsertReceiveStagingTset] @CopyReceiveStagingTset, @copyItem, @ActivityId = @ActivityId  
		DELETE FROM @CopyReceiveStagingTset  

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
 EXEC [Logging].[usp_LogError] NULL,@ActivityId;  
 RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine);  
  
END CATCH  
  
SET NOCOUNT OFF;  
END  
GO

EXEC [sys].[sp_addextendedproperty] @name = N'Component',
    @value = N'iPSL.ICS.MO.DB',
    @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE',
    @level1name = N'usp_Fwk_WriteData';
GO

EXEC [sys].[sp_addextendedproperty] @name = N'MS_Description',
    @value = N'Caller: Framework DAL.
			   Description: Stored Procedure to save data into the MO database Data from udt_Source is saved into Source table,
				udt_TransactionSet is saved into TransactionSet table,
				udt_Item is saved into Item table,
				udt_TransactionSetState is saved into TransactionSetState table
				udt_ItemState is saved into ItemState table,
				udt_SourceTracker is saved into SourceTracker table by invoking respective table wise upsert stored procedure',
    @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE',
    @level1name = N'usp_Fwk_WriteData';
GO

EXEC [sys].[sp_addextendedproperty] @name = N'Version', @value = [$(Version)],
   @level0type = N'SCHEMA', @level0name = N'Base', @level1type = N'PROCEDURE',
    @level1name = N'usp_Fwk_WriteData';
GO

GRANT EXECUTE
    ON OBJECT::[Base].[usp_Fwk_WriteData] TO [WebRole]
    AS [dbo]
	GO