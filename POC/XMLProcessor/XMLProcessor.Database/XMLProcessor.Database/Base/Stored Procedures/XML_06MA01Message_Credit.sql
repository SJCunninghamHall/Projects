CREATE PROCEDURE [Base].[XML_06MA01Message_Credit]
	@tv_CrdItm_X				[Base].[tv_CrdItm_XML]	READONLY,
	@tv_CdtItmFrdDate_X			 base.tv_CdtItmFrdDate_XML READONLY, 	 --[Base].[tv_CreditItemFraudData_XML]	READONLY, 
	@tv_RprdItm_X				[Base].[tv_RprdItm_XML]	READONLY,
	@tv_DbtItm_X				[Base].[tv_DbtItm_XML]	READONLY,
	@tv_Amt_X					[Base].[tv_Amt_XML]	READONLY,
	@BusinessDate varchar(10),
	@CoreId bigint

WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER  
AS BEGIN ATOMIC WITH  (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE=N'us_english')  
	-- PART 1
	DECLARE @tv_CreditNative Base.[tv_Credit_Native];
 
	INSERT INTO @tv_CreditNative
	(
			--[Credit_ID] ,                
            [TxSetId],
            [TxSetVrsn],
            [CdtItmId],
            [CdtItmTp],
          --  [Amt],
            [AmtCcy],
            [BkCd],
            [AcctNb],
            [RefNb],
            [BnfcryNm],
            [VrtlCdtInd],
            [RefData],
            [BkCdRprdInd],
            [AcctNbRprdInd],
            [AmtRprdInd],
            [SrlNbRprdInd],
		--	[BkCdDfltdInd],
			[RefNbRprdInd],
        --    [AcctNbDfltdInd],
        --    [RefNbDfltdInd],
			[sBkCd],
			[sAcctNb],  -->  Not sure mapping
			[Ccy],  --> -- From XML definition? (HARDCODE TO 0)
			[Amt_text],                                        
            [CrdtItm_Id],
            [DbtStopdItm_Id],  --Data value missing
            [DbtItm_Id],
            [TxSet_Id]
	)
	SELECT 	
			--@CoreId						AS [CoreId],
			--@BusinessDate					AS [BusinessDate],	
			NULL As [TxSetId], --> [TxSetId],-> missing
			NULL AS [TxSetVrsn], --> [TxSetVrsn] -> missing
			crd.[CreditItemId] AS [CdtItmTp],   --> [CdtItmId],
			crd.[CreditItemTp] AS [CdtItmTp],  --> [CdtItmTp],
		--	NULL As [Amt], -->[[Amt],?
			NULL As [AmtCcy], -->[AmtCcy]?,
			crd.[BkCd] As [BkCd],
			crd.[AcctNb] As [AcctNb],
			crd.[RefNo] As [RefNb],
			cfd.[BnfcryNm] As [BnfcryNm],
			cfd.[VrtlCdtInd] As [VrtlCdtInd],
			cfd.[RefData] As [RefData],
			rpd.[BkCdRprdInd] As [BkCdRprdInd], 
			rpd.[AcctNbRprdInd] As [AcctNbRprdInd],
			rpd.[AmtRprdInd] AS [AmtRprdInd],
			rpd.[SrlNbRprdInd] As [SrlNbRprdInd],
			--dbi.[BkCdDfltdInd] As [BkCdDfltdInd],?
			rpd.[RefNbRprdInd] As [RefNbRprdInd], 
			--dbi.[AcctNbDfltdInd] As [AcctNbDfltdInd],
			--dbi.[RefNbDfltdInd] As [RefNbDfltdInd],
			NULL As [sBkCd], --> src.[sBkCd] ?
			NULL As [sAcctNb], --[sAcctNb],  -->  Not sure mapping
			amt.[Ccy] As [Ccy], -- From XML definition? (HARDCODE TO 0),
			amt.[Amt_Text] As [Amt_text],
			rpd.[CrdtItm_Id] As [CrdtItm_Id],
			0, -- amt.[DbtStopdItm_Id] As [DbtStopdItm_Id],   --Data value missing --src.DbtStopdItm_Id data missing from AMT XML 
			
			rpd.[DbtItm_Id] As [DbtItm_Id],
			crd.[TxSet_Id] As [TxSet_Id]

			--Following columns have no matching 
			--src.[SrlNbRprdInd] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			--src.[DbtItm_Id] [bigint] NULL,
			--src.[CreditItem_Id] [bigint] NULL,
			--src.[CrdtItm_Id] [varchar](max), int or big int
			--CRD.[CrdtItm_Id] need to have primary key or index on this column
			--@tv_CdtItmFrdDate_XML Date misleading -> should be data
	FROM 
		@tv_CrdItm_X crd  
		INNER JOIN	@tv_CdtItmFrdDate_X  cfd	ON crd.[CreditItem_Id] = cfd.[CrdtItm_Id]  -- data type not same int vs bigint
		LEFT JOIN	@tv_RprdItm_X	rpd			ON crd.[CreditItem_Id] = rpd.[CrdtItm_Id]
		LEFT JOIN	@tv_DbtItm_X dbi			ON crd.[TxSet_Id] = dbi.[TxSet_Id]
		LEFT JOIN	@tv_Amt_X	amt				ON crd.[TxSet_Id] = dbi.[TxSet_Id]
	
 	-- PART 2

	--INSERT INTO [Base].[Credit]
	--(
	--   [ItemId]
 --     ,[Reference]
 --     ,[CreditId]
 --     ,[InternalTxId]
 --     ,[Revision]
 --     ,[ItemType]
 --     ,[Sortcode]
 --     ,[AccountNumber]
 --     ,[Amount]
 --     ,[Currency]
 --     ,[ReasonCode]
 --     ,[Narrative]
 --     ,[TranCode]
 --     ,[DefaultedSortcode]
 --     ,[DefaultedAccount]
 --     ,[AlternateSortCode]
 --     ,[AlternateAccount]
 --     ,[SwitchedSortCode]
 --     ,[SwitchedAccount]
 --     ,[RicherDataRef]
 --     ,[OnUs]
 --     ,[RepairedSortcode]
 --     ,[RepairedAccount]
 --     ,[RepairedAmount]
 --     ,[RepairedSerial]
 --     ,[RepairedReference]
 --     ,[DefaultedReference]
 --     ,[TSetID]
 --     ,[TSetIDWithVersion]

	--)
	--SELECT 
	--				--[Credit_ID] ,                
 --           [TxSetId],
 --           [TxSetVrsn],
 --           [CdtItmId],
 --           [CdtItmTp],
 --         --  [Amt],
 --           [AmtCcy],
 --           [BkCd],
 --           [AcctNb],
 --           [RefNb],
 --           [BnfcryNm],
 --           [VrtlCdtInd],
 --           [RefData],
 --           [BkCdRprdInd],
 --           [AcctNbRprdInd],
 --           [AmtRprdInd],
 --           [SrlNbRprdInd],
	--	--	[BkCdDfltdInd],
	--		[RefNbRprdInd],
 --       --    [AcctNbDfltdInd],
 --       --    [RefNbDfltdInd],
	--		[sBkCd],
	--		[sAcctNb],  -->  Not sure mapping
	--		[Ccy],  --> -- From XML definition? (HARDCODE TO 0)
	--		[Amt_text],                                        
 --           [CrdtItm_Id],
 --           [DbtStopdItm_Id],  --Data value missing
 --           [DbtItm_Id],
 --           [TxSet_Id]
	--FROM 
	--	@tv_CreditNative crd
	--	-- LEFT OUTER JOIN [Lookup].[MessageType] LkpDocType ON core.ExtMessageType = LkpDocType.MessageType;

END