CREATE PROCEDURE [RNEReport].[usp_getDimCreditEntityStateHistory_Item] 
 @BusinessDateRangeStart BIGINT
,@BusinessDateRangeEnd BIGINT
/*****************************************************************************************************
* Name				: [RNEReport].[usp_getDimCreditEntityStateHistory_Item]
* Description		: This stored procedure exports the data for dimCreditEntityStateHistory from STAR to RnEReportDataWarehouse.
* Type of Procedure : Interpreted stored procedure
* Author			: Mahesh Kumar Suragani
* Creation Date		: 13/07/2018
* Last Modified		: N/A
*******************************************************************************************************/
AS 
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
BEGIN

	SELECT		
		EntityType AS EntityType
		,Tx5.TransactionSetIdWithVersion AS TransactionSetIdWithVersion
		,DocD5.DocumentMessageId AS DocumentMessageId
		,EntityIdentifier AS EntityIdentifier
		,EntityId AS EntityId
		,en.Revision AS Revision
		,EntityState  AS EntityState
		,CAST(
				CASE 
					WHEN ISNUMERIC(RIGHT(Co.IntMessageType,2)) = 1 
					THEN RIGHT(Co.IntMessageType,2)
					ELSE RIGHT(Co.IntMessageType,1)
				END AS TINYINT) 
		AS IntMessageTypeSeq
		,Co.IntMessageType AS IntMessageType
		,CASE 
			WHEN MsgType.MessageType = 'PSTNG' 
			THEN IntMessageType  
			ELSE MsgType.MessageType 
		END AS MessageType 
	INTO 
		#EntInternal						  			
	FROM    
		Base.Core Co
		--EntityType = 'I'
	INNER JOIN
		Lookup.MessageType MsgType 
	ON
		Co.MessageType = MsgType.MessageId
	INNER JOIN
		Base.Entity En
	ON
		En.CoreId = Co.CoreId
	LEFT JOIN
		Base.vw_Document DocD5
	ON
		DocD5.DocumentMessageId = En.EntityIdentifier
	LEFT JOIN
		Base.vw_TXSet Tx5
	ON
		Tx5.DocumentId = DocD5.DocumentId				
	WHERE
		En.EntityId BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd 
	AND 
		En.EntityType = 'I'

	SELECT 
		EntityIdentifier
	INTO 
		#UniqueItem
	FROM 
		#EntInternal 
	GROUP BY 
		EntityIdentifier;

	CREATE NONCLUSTERED INDEX nci_EntityIdentifier ON #UniqueItem (EntityIdentifier)

	SELECT
		ItemId,
		FraudReason,
		FraudResult,
		vc.IntMessageType,
		LM.MessageType, 
		ROW_NUMBER() OVER(PARTITION BY frsr.ItemId,vc.IntMessageType ORDER BY frsr.FraudStatusId DESC) Rnk 
	INTO 
		#tempFrdResult
	FROM
		Base.vw_Core vc
	INNER JOIN
		Base.FraudStatus FS 
	ON 
		vc.CoreId = FS.CoreId								 
	INNER JOIN 
		Base.FraudStatusResults frsr
	ON 
		FS.FraudStatusId = frsr.FraudStatusId
	INNER JOIN 
		#UniqueItem it 
	ON 
		frsr.ItemId = it.EntityIdentifier
	INNER JOIN 
		Lookup.MessageType lm 
	ON 
		LM.MessageId = vc.MessageType; 

	CREATE NONCLUSTERED INDEX nci_ItemId_IntMessageType_Rnk ON #tempFrdResult (ItemId, IntMessageType, Rnk)

	SELECT  
		I.FCMIdentifier
		,I.cf_NoPaySuspectRsn
		,I.cf_DeferredPosting
		,I.cf_BrandID
		,I.cf_ICSTransactionID
		,I.cf_LocationID
		,I.APGDIN
		,I.Comments
		,I.APGBusinessDate
		,I.RejectReason
		,I.ReturnReason
		,I.TransactionNumber
		,I.DebitReference AS DebitReference
		,I.cf_SourceID
		,I.JGAccount
		,c.IntMessageType
		,LM.MessageType
		,I.AdjustmentReason
		,I.cf_ChnlInsertReason
		,I.cf_ImageDateTime
		,I.cf_NPASortCode
		,I.Process
		,ROW_NUMBER() OVER(PARTITION BY I.FCMIdentifier,c.IntMessageType ORDER BY i.ItemId DESC) Rnk 
	INTO 
		#Item
	FROM 
		Base.Item i 
	INNER JOIN 
		Base.Core c 
	ON 
		i.CoreId = c.CoreId 
	INNER JOIN 
		#UniqueItem it 
	ON 
		i.FCMIdentifier = it.EntityIdentifier 
	INNER JOIN
		Lookup.MessageType lm 
	ON 
		LM.MessageId = c.MessageType;

	CREATE NONCLUSTERED INDEX nci_FCMIdentifier_MessageType_Rnk ON #item (FCMIdentifier, MessageType, Rnk)

	SELECT
		EntityIdentifier AS EntityIdentifier
		,EntityType AS EntityType
		,TransactionSetIdWithVersion AS TransactionSetIdWithVersion
		,DocumentMessageId AS DocumentMessageId
		,MessageType AS MessageType
		,CASE 
			WHEN MessageType IN ('MSG02','MSG03') 
			THEN 'MSG01' 
			ELSE MessageType 
		END AS MessageType_Derived
		,IntMessageType AS IntMessageType
		,EntityState AS EntityState
		,EntityId AS EntityId
		,Revision AS Revision
	INTO
		#ItemsEntities
	FROM
		(
			SELECT	
				EntityIdentifier AS EntityIdentifier
				,EntityType AS EntityType
				,TransactionSetIdWithVersion AS TransactionSetIdWithVersion
				,DocumentMessageId AS DocumentMessageId
				,MessageType AS MessageType
				,IntMessageType AS IntMessageType
				,EntityState AS EntityState
				,EntityId AS EntityId
				,Revision AS Revision
				,ROW_NUMBER() OVER ( PARTITION BY EntityType,EntityIdentifier,MessageType,IntMessageType ORDER BY Revision DESC, EntityId DESC ) RKD
			FROM 
				#EntInternal
			WHERE 
				EntityIdentifier IS NOT NULL
		)ENT
	WHERE 
		ENT.RKD = 1

	CREATE NONCLUSTERED INDEX nci_EntityIdentifier ON #ItemsEntities (EntityIdentifier)
	CREATE NONCLUSTERED INDEX nci_MessageType_Derived ON #ItemsEntities (MessageType_Derived)
	CREATE NONCLUSTERED INDEX nci_EntityId ON #ItemsEntities (EntityId)

	SELECT	
		CAST(LEFT(COALESCE(IMC.EntityId,FD.ItemId), 8)  AS INT) AS DateKey		 
		,FD.CreditId AS CreditId
		,COALESCE(IMC.EntityId,FD.ItemId) AS EntityId
		,COALESCE(IMC.Revision,0) AS Revision
		,U.OperatorId AS OperatorId
		,ISNULL(FD.AccountNumber,0) AS AccountNumber
		,ISNULL(FD.Sortcode,0) AS Sortcode
		,FD.Reference AS Reference
		,CASE 
			WHEN MultiDebitInd.CreditId IS NOT NULL 
			THEN 1 ELSE 0 
		END  AS isMultiDebit
		,FD.DefaultedSortcode  AS DefaultedSortcode
		,itmtyp.ItemTypeCode  AS ItemType		
		,CAST(LEFT(EntryDateCredit.EntryItemId, 8) AS DATE)  AS CreditEntryDate
		,CAST(LEFT(HoldoverItemEntry.EntityId, 8) AS DATE)  AS CreditHoldoverEntryDate
		,EntryDateCredit.OriginalSortcode  AS OriginalSortcode
		,I.cf_NoPaySuspectRsn  AS cf_NoPaySuspectRsn
		,CAST(COALESCE(IMC.EntityState,0) AS SMALLINT) AS EntityState
		,IMC.IntMessageType AS IntMessageType
		,IMC.MessageType AS MessageType
		,I.cf_DeferredPosting AS cf_DeferredPosting
		,I.cf_BrandID AS cf_BrandID
		,IMC.EntityType AS EntityType
		,FD.TSetIDWithVersion AS TransactionSetIdWithVersion
		,IMC.DocumentMessageId AS DocumentMessageId
		,I.cf_ICSTransactionID AS cf_ICSTransactionID
		,I.cf_LocationID AS cf_LocationID
		,CASE 
			WHEN [I].[AdjustmentReason] IS NOT NULL
			THEN [I].[AdjustmentReason]
			ELSE [FD].[AdjustmentReason]
		END AS [AdjustmentReason]
		,I.APGDIN AS APGDIN
		,FD.NoPayReason AS NoPayReason
		,FD.TranCode AS TranCode
		,I.Comments AS Comments
		,I.APGBusinessDate AS APGBusinessDate
		,I.RejectReason AS RejectReason
		,I.ReturnReason AS ReturnReason
		,I.TransactionNumber AS TransactionNumber
		,FD.EISCDPayingParticipantId  AS EISCDPayingParticipantId
		,I.JGAccount AS JGAccount
		,I.cf_SourceID AS cf_SourceID
		,FD.CollectingParticipantId AS CollectingParticipantId
		,FD.ICSAmount AS ICSAmount
		,fr.FraudReason as KappaFraudReason
		,fr.FraudResult as KappaFraudResult
		,I.cf_ChnlInsertReason
		,I.cf_ImageDateTime
		,I.cf_NPASortCode
		,I.Process
		,FD.FinalInclearingState
		,FD.FinalOutClearingState
		,FD.FinalclearingState
	FROM    
		#ItemsEntities IMC

	INNER JOIN 
		Base.FinalCredit FD 
	ON 
		FD.CreditId = IMC.EntityIdentifier

	INNER JOIN 
		Lookup.ItemType itmtyp 
	ON 
		FD.ItemType = itmtyp.Id

	LEFT JOIN 
		#Item I 
	ON 
		FD.CreditId = I.FCMIdentifier 
	AND 
		I.Rnk = 1 
	AND 
		I.MessageType = IMC.MessageType_Derived

	LEFT JOIN 
		Base.ItemUpdate U 
	ON 
		FD.ItemUpdateId = U.InternalId

	LEFT JOIN 
		#tempFrdResult fr 
	ON 
		fr.ItemId = IMC.EntityIdentifier 
	AND 
		fr.MessageType = IMC.MessageType_Derived 
	AND 
		fr.Rnk = 1

	LEFT JOIN 
		(
			SELECT 
				CreditId AS CreditId
			FROM 
				Base.FinalCredit FC
			INNER JOIN 
				Base.FinalDebit FD 
			ON 
				FC.TransactionSetId = FD.TransactionSetId
			WHERE 
				(FD.FinalOutClearingState!=25 OR FD.FinalOutClearingState IS NULL)
			GROUP BY 
				CreditId
			HAVING 
				COUNT(1) > 1
		) MultiDebitInd 
		
	ON 
	
		MultiDebitInd.CreditId = FD.CreditId

	LEFT JOIN 
		(
			SELECT 
				EntryItemId AS EntryItemId
				,CreditId AS CreditId
				,OriginalSortcode AS OriginalSortcode
			FROM
				(
					SELECT 
						ItemId AS EntryItemId
						,CreditId AS CreditId
						,Sortcode AS OriginalSortcode
						,ROW_NUMBER() OVER (PARTITION BY CreditId ORDER BY ItemId ASC) RKD
					FROM 
						Base.Credit
					WHERE 
						SortCode IS NOT NULL
				) EntryDateCreditInternal
			WHERE 
				EntryDateCreditInternal.RKD = 1

		) EntryDateCredit
	
	ON 
	
		EntryDateCredit.CreditId = FD.CreditId

	-- Holdover Item Date Catpture
	LEFT JOIN 
		(
			SELECT	 
				EntityId AS EntityId
				,CreditID AS CreditID
				,HoldoverDay1EntryRnk AS HoldoverDay1EntryRnk
			FROM 
			(
				SELECT	 
					En.EntityId AS EntityId
					,EntityType AS EntityType
					,msg.MessageType AS MessageType
					,CASE	
						WHEN EntityType = 'I' THEN EntityIdentifier
						WHEN EntityType = 'T' THEN DbT.CreditId
					END  AS CreditID
					,ROW_NUMBER() OVER (PARTITION BY 
											CASE 
												WHEN EntityType = 'I' THEN EntityIdentifier
												WHEN EntityType = 'T' THEN DbT.CreditID
											END 
										ORDER BY	
											CASE 
												WHEN msg.MessageType = 'MSG01' 
												THEN En.EntityId 
												ELSE 0 
											END DESC,
											CASE 
												WHEN co.IntMessageType  = '06MA01' 
												THEN En.EntityId 
												ELSE 0 
											END ASC,
											CASE 
												WHEN co.IntMessageType  != '06MA01' 
												THEN En.EntityId 
											END ASC 
										) AS HoldoverDay1EntryRnk
				FROM 
					Base.Core Co
				INNER JOIN 
					Lookup.MessageType msg 
				ON 
					Co.MessageType = msg.MessageId
				INNER JOIN 
					Base.Entity En 
				ON 
					En.CoreId = Co.CoreId
				LEFT JOIN 
					Base.vw_TXSet TXT 
				ON
					TXT.TransactionSetIdWithVersion = En.EntityIdentifier
				LEFT JOIN 
					Base.Credit DbT 
				ON 
					TXT.InternalTxId = DbT.InternalTxId
				WHERE 
					msg.MessageType  IN ('MSG01','MSG06') 
				AND
				(
					CASE	
						WHEN EntityType = 'I' THEN EntityIdentifier
						WHEN EntityType = 'T' THEN DbT.CreditId
					END
				) IS NOT NULL
				AND 
					En.EntityId BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd
			) Day1Entry
			WHERE 
				HoldoverDay1EntryRnk = 1 
		) AS HoldoverItemEntry
	ON 
		HoldoverItemEntry.CreditId = FD.CreditId

	WHERE 
		(FD.ItemId BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd)
	OR 
		(IMC.EntityId BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd)

END
GO

GRANT Execute ON [RNEReport].[usp_getDimCreditEntityStateHistory_Item] to [RNEReportAccess]

GO

EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)',
    @level0type = N'SCHEMA', @level0name = N'RNEReport', @level1type = N'PROCEDURE',
    @level1name = N'usp_getDimCreditEntityStateHistory_Item';
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'This stored procedure exports the data for dimCreditEntityStateHistory from STAR to RnEReportDataWarehouse.',
    @level0type = N'SCHEMA', @level0name = N'RNEReport', @level1type = N'PROCEDURE',
    @level1name = N'usp_getDimCreditEntityStateHistory_Item';
GO
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'STAR',
    @level0type = N'SCHEMA', @level0name = N'RNEReport', @level1type = N'PROCEDURE',
    @level1name = N'usp_getDimCreditEntityStateHistory_Item';
GO
		