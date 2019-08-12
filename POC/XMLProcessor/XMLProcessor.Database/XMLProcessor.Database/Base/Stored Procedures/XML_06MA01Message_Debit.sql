CREATE PROCEDURE [Base].[XML_06MA01Message_Debit]
	@tv_DbtItm_XML_X				[Base].[tv_DbtItm_XML]	READONLY,
	@tv_ItmImgData_X				[Base].[tv_ItmImgData_Xml]	READONLY,
	@tv_Amt_X						[Base].[tv_Amt_XML]	READONLY,
	@tv_TxSet_X						[Base].[tv_TxSet_XML]	READONLY,
	@tv_RprdItm_X   				[Base].[tv_RprdItm_XML]	READONLY,
	@BusinessDate varchar(10),
	@CoreId bigint
	--DbtItmFrdData, @tv_HghstAmt_XML, @tv_DbtDplctItm_XML, @tv_DbtStopdItm_XML, @tv_DfltdItm_XML

WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER  
AS BEGIN ATOMIC WITH  (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE=N'us_english')  
	-- PART 1
--	DECLARE @tv_DebitNative Base.[tv_Debit_NativeX];
 
--	INSERT INTO @tv_DebitNative
--	(
--	--	[TxSetId] , 
--	--	[TxSetVrsn],
--		[DbtItmId],
--		[DbtItmTp],
--		[DbtItmTxCd],
--		[RpresntdItmInd],
--		[Amt],
--		[AmtCcy],
--		[BkCd],
--		[AcctNb],
--		[SrlNb],
--		[HghValItm],
--		[DayOneRspnWndwStartDtTm], 
--		[DayOneRspnWndwEndDtTm],
--		[DayTwoRspnWndwStartDtTm],
--		[DayTwoRspnWndwEndDtTm],
--		[XtrnlDataRef],
--		[Img],
--		[FrntImgQltyIndctnInd],
--		[BckImgQltyIndctnInd],
--		[ChqAtRskInd],
--		[DtOfFrstChq],
--		[DtOfLstChq],
--		[NbOfCtrPtys],
--		[NbOfVldChqs],
--		[NbOfFrdChqs],
--		[HghstAmt],
--		[HghstAmtCcy],
--		[RskInd],
--		[BkCdRprdInd],
--		[AcctNbRprdInd],
--		[AmtRprdInd],
--		[SrlNbRprdInd],
--		[RefNbRprdInd],
--		[BkCdDfltdInd],
--		[AcctNbDfltdInd],
--		[SrlNbDfltdInd],
--		[sBkCd],
--		[sAcctNb],
--		[DplctItmId],
--		[DbtDplctSts],
--		[DtFirstPresntd],
--		[MmbId],
--		[OrgnlCaptrDt],
--		[OrgnlSrc],
--		[StopdDt],
--		[StopdSts],
--		[StopedAmt],
--		[StopedAmtCcy],
--		[BnfcryNm],
--		[StopItmStartRg],
--		[StopItmEndRg] ,

--		[DbtItm_Id] , --?
--		[DbtStopdItm_Id] , --?
--		[CrdtItm_Id] , --?
--		[Amt_text] , --?
--		[Ccy] ,
--		[DbtItmFrdData_Id], --?
--		[HghstAmt_text] --?
--		--TxSet_Id [int] IDENTITY(1,1) NOT NULL
--	)
--	SELECT 	
----		TxSetId					As [TxSetId],
----		TxSetId + TxSetVrsn		As [TxSetVrsn],
--		DbtItmId				As [DbtItmId],
--		DbtItmTp				As [DbtItmTp],
--		DbtItmTxCd				As [DbtItmTxCd],
--		RpresntdItmInd			As [RpresntdItmInd],
--		Amt						As [Amt],
--		AmtCcy					As [AmtCcy],
--		BkCd					As [BkCd],
--		AcctNb					As [AcctNb],
--		SrlNb					As [SrlNb],
--		HghValItm				As [HghValItm],
--		DayOneRspnWndwStartDtTm	As [DayOneRspnWndwStartDtTm],
--		DayOneRspnWndwEndDtTm	As [DayOneRspnWndwEndDtTm],
--		DayTwoRspnWndwStartDtTm	As [DayTwoRspnWndwStartDtTm],
--		DayTwoRspnWndwEndDtTm	As [DayTwoRspnWndwEndDtTm],
--		XtrnlDataRef			As [XtrnlDataRef],
--		Img						As [Img],
--		FrntImgQltyIndctnInd	As [FrntImgQltyIndctnInd],
--		BckImgQltyIndctnInd		As [BckImgQltyIndctnInd],
--		ChqAtRskInd				As [ChqAtRskInd],
--		DtOfFrstChq				As [DtOfFrstChq],
--		DtOfLstChq				As [DtOfLstChq],
--		NbOfCtrPtys				As [NbOfCtrPtys],
--		NbOfVldChqs				As [NbOfVldChqs],
--		NbOfFrdChqs				As [NbOfFrdChqs],
--		HghstAmt				As [HghstAmt],
--		HghstAmtCcy				As [HghstAmtCcy],
--		RskInd					As [RskInd],
--		BkCdRprdInd				As [BkCdRprdInd],
--		AcctNbRprdInd			As [AmtRprdInd],
--		AmtRprdInd				As [AmtRprdInd],
--		SrlNbRprdInd			As [SrlNbRprdInd],
--		RefNbRprdInd			As [RefNbRprdInd],
--		BkCdDfltdInd			As [BkCdDfltdInd],
--		AcctNbDfltdInd			As [AcctNbDfltdInd],
--		SrlNbDfltdInd			As [SrlNbDfltdInd],
--		sBkCd					As [sBkCd],
--		sAcctNb					As [sAcctNb],
--		DplctItmId				As [DplctItmId],
--		DbtDplctSts				As [DplctItmId],
--		DtFirstPresntd			As [DtFirstPresntd],
--		MmbId					As [MmbId],
--		OrgnlCaptrDt			As [OrgnlCaptrDt],
--		OrgnlSrc				As [OrgnlSrc],
--		StopdDt					As [StopdDt],
--		StopdSts				As [StopdSts],
--		StopedAmt				As [StopedAmt],
--		StopedAmtCcy			As [StopedAmtCcy],
--		BnfcryNm				As [BnfcryNm],
--		StopItmStartRg			As [StopItmStartRg],
--		StopItmEndRg			As [StopItmEndRg] ,
--		NULL					As [DbtItm_Id],
--		NULL					As [DbtStopdItm_Id] ,
--		NULL					As [CrdtItm_Id] ,
--		NULL					As [Amt_text] ,
--		NULL					As [Ccy] ,
--		NULL					As [DbtItmFrdData_Id],
--		NULL					As [HghstAmt_text]
		
--	FROM 
--		@tv_DbtItm_XML_X  dbi
--		INNER JOIN	@tv_ItmImgData_X  iid	ON dbi.[dbtitm_Id] = iid.[dbtitem_Id]  
--		LEFT JOIN	@tv_Amt_X	amt			ON dbi.[dbtitm_Id] = amt.[dbtitm_Id]
	
	
 	-- PART 2

	INSERT INTO [Base].[Debit]
	(
		TSetID,
		TSetIDWithVersion,
		DebitId,
		ItemType,
	--	TranCode, missing
		Represent,
		Sortcode,
		AccountNumber,
		SerialNumber,
		HighValue,
		Day1ResponseStartDateTime,
		Day1ResponseEndDateTime,
		Day2ResponseStartDatetime,
		Day2ResponseEndDateTime,
		RicherDataRef,
		Amount,
		Currency,
		RepairedSortcode,
		RepairedAccount,
		RepairedAmount,
		RepairedSerial,
		RepairedReference,
	--	DefaultedSortcode,  -- Data source  @tv_DfltdItm_XML not yet created
		--DefaultedAccount,  -- Data source  @tv_DfltdItm_XML not yet created
	--	DefaultedSerialNumber, -- Data source  @@tv_DfltdItm_XML not yet created 
		SwitchedSortCode,
		SwitchedAccount,
		ItemId,
		Revision,
		ReasonCode,
		Narrative,
		AlternateSortCode,
		AlternateAccount,
		InternalTxId,
		PayReason,
		FraudStatusCode,
		FraudReasonCode,
		SettlementPeriodId,
		OnUs,
		PayDecision,
		DocumentId
	)
	SELECT 
		TxSetId,
		TxSetId+TxSetVrsn,
		DbtItmId,
		DbtItmTp,
		--DbtItmTxCd,  missing
		RpresntdItmInd,
		BkCd,
		AcctNb,
		SrlNb,
		HghValItm,
		DayOneRspnWndwStartDtTm,
		DayOneRspnWndwEndDtTm,
		DayTwoRspnWndwStartDtTm,
		DayTwoRspnWndwEndDtTm,
		XtrnlDataRef,
		Amt_Text, --Should be AMT instead --Amt,
		Ccy,  --Should be Ccy instead --Amt,'GBP' As AmtCcy,  -- 
		BkCdRprdInd,
		AcctNbRprdInd,
		AmtRprdInd,
		SrlNbRprdInd,
		RefNbRprdInd,
		--BkCdDfltdInd, -- Data source  @tv_DfltdItm_XML not yet created
		-- AcctNbDfltdInd, -- Data source  @tv_DfltdItm_XML not yet created
		-- SrlNbDfltdInd,  -- Data source  @@tv_DfltdItm_XML not yet created 
		BkCd,
		AcctNb,
		@coreID,
		Null as Revision,
		Null as ReasonCode,
		Null as Narrative,
		Null as AlternateSortCode,
		Null as AlternateAccount,
		Null as InternalTxId,
		Null as PayReason,
		Null as FraudStatusCode,
		Null as FraudReasonCode,
		Null as SettlementPeriodId,
		Null as OnUs,
		Null as PayDecision,
		Null as DocumentId
	FROM 
		@tv_DbtItm_XML_X  dbi
		INNER JOIN	@tv_ItmImgData_X  iid	ON dbi.[dbtitm_Id] = iid.[dbtitem_Id]  
		LEFT JOIN	@tv_Amt_X	amt			ON dbi.[dbtitm_Id] = amt.[dbtitm_Id]
		LEFT JOIN @tv_TxSet_X tst			ON dbi.[TxSet_ID] = tst.[TxSet_ID] 
		LEFT JOIN @tv_RprdItm_X rpd			ON dbi.[TxSet_ID] = rpd.[dbtitm_Id]
		--DbtItmFrdData, @tv_HghstAmt_XML, @tv_DbtDplctItm_XML, @tv_DbtStopdItm_XML, @tv_DfltdItm_XML
END