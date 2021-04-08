

/*
	-- -------------------------------------------------------------------------------------------
	-- TODO Base.TXSet
	-- -------------------------------------------------------------------------------------------
	--INSERT INTO [Base].[TXSet]
	--(
	--	[DocumentId],
	--	[InternalTxId],
	--	[CollectingPId],
	--	[TXIdDate],
	--	[Source],
	--	[Sequence],
	--	[Version],
	--	[CollectingParticipantId],
	--	[AltSource],
	--	[CaptureDate],
	--	[TSetSubmissionDateTime],
	--	[NumberOfItems],
	--	[EndPointId],
	--	[CollectingBranchLocation],
	--	[CollectingLocation],
	--	[ChannelRiskType],
	--	[ChannelDescription],
	--	[CollectionPoint],
	--	[CollectionBranchRef],
	--	[FraudCheckOnly],
	--	[TransactionSetIdWithVersion],
	--	[TransactionSetId]
	--)

	-- -------------------------------------------------------------------------------------------
	-- TODO Base.Credit
	-- -------------------------------------------------------------------------------------------
	--INSERT INTO [Base].[Credit]
	--(
	--	[ItemId],
	--	[Reference],
	--	[CreditId],
	--	[InternalTxId],
	--	[Revision],
	--	[ItemType],
	--	[Sortcode],
	--	[AccountNumber],
	--	[Amount],
	--	[Currency],
	--	[ReasonCode],
	--	[Narrative],
	--	[TranCode],
	--	[DefaultedSortcode],
	--	[DefaultedAccount],
	--	[AlternateSortCode],
	--	[AlternateAccount],
	--	[SwitchedSortCode],
	--	[SwitchedAccount],
	--	[RicherDataRef],
	--	[OnUs],
	--	[RepairedSortcode],
	--	[RepairedAccount],
	--	[RepairedAmount],
	--	[RepairedSerial],
	--	[RepairedReference],
	--	[DefaultedReference],
	--	[TSetID],
	--	[TSetIDWithVersion],
	--)
	--------------------------------------------------------------------------------------------------------------

	--A. Clear Down before starting
	DELETE FROM [Test].[TVPTrace];  --Optional
	DELETE FROM [Base].[Core];
	DELETE FROM [Base].[TXSet];
	DELETE FROM [Base].[Credit];
	DELETE FROM [Base].[Debit];
	DELETE FROM [Base].[DebitFraudData];
	DELETE FROM [Base].[DuplicateDebit];
	DELETE FROM [Base].[Entity];
	GO

	--P. After Processing Review
	--P1. Trace Profile
	SELECT [Step] , COUNT(*) AS TALLY FROM [Test].[TVPTrace] GROUP BY Step ORDER BY Step;  --View the counts of [Test].[TVPTrace]
	SELECT * FROM [Test].[TVPTrace] WHERE Step = 'tv_Amt_XML' ORDER BY TVPTrace;
	SELECT * FROM [Test].[TVPTrace] WHERE Step = 'tv_CdtItmFrdDate_XML' ORDER BY TVPTrace;
	SELECT * FROM [Test].[TVPTrace] WHERE Step = 'tv_Core_XML' ORDER BY TVPTrace;
	SELECT * FROM [Test].[TVPTrace] WHERE Step = 'tv_CrdItm_XML' ORDER BY TVPTrace;
	SELECT * FROM [Test].[TVPTrace] WHERE Step = 'tv_DbtItm_XML' ORDER BY TVPTrace;
	SELECT * FROM [Test].[TVPTrace] WHERE Step = 'tv_Entities_XML' ORDER BY TVPTrace;
	SELECT * FROM [Test].[TVPTrace] WHERE Step = 'tv_Entity_XML' ORDER BY TVPTrace;
	SELECT * FROM [Test].[TVPTrace] WHERE Step = 'tv_GrpHdr_XML' ORDER BY TVPTrace;
	SELECT * FROM [Test].[TVPTrace] WHERE Step = 'tv_ItmImgData_XML' ORDER BY TVPTrace;
	SELECT * FROM [Test].[TVPTrace] WHERE Step = 'tv_RprdItm_XML' ORDER BY TVPTrace;
	SELECT * FROM [Test].[TVPTrace] WHERE Step = 'tv_TxSet_XML' ORDER BY TVPTrace;

	--P2. Output Tables
	SELECT * FROM [Base].[Core] ORDER BY [CoreId];	-- AB 2019/07/26 [XMLMessageId] needs clarificsation
	SELECT * FROM [Base].[Document];	

	SELECT * FROM [Base].[TXSet];					-- Not Complete
	SELECT * FROM [Base].[Credit];					-- Not Complete
	SELECT * FROM [Base].[Debit];					-- Not Complete
	SELECT * FROM [Base].[DebitFraudData];			-- Not Complete
	SELECT * FROM [Base].[DuplicateDebit];			-- Not Complete
	SELECT * FROM [Base].[Entity];					-- Not Complete
	GO
*/
--DROP PROCEDURE   [Base].[XML_06MA01Message_v2]
CREATE PROCEDURE [Base].[XML_06MA01Message_v2]
	@tv_GrpHdr_XML			base.tv_GrpHdr_XML			READONLY, 
	@tv_Core_XML			base.tv_Core_XML			READONLY,		
	@tv_TxSet_XML			base.tv_TxSet_XML			READONLY,
	@tv_DbtItm_XML			base.tv_DbtItm_XML			READONLY,
	@tv_ItmImgData_XML		base.tv_ItmImgData_XML		READONLY, 	
	@tv_CrdItm_XML			base.tv_CrdItm_XML			READONLY,	
	@tv_CdtItmFrdDate_XML   base.tv_CdtItmFrdDate_XML	READONLY,
	--@tv_DfltdItm_XML		base.tv_DfltdItm_XML		READONLY,	
	@tv_RprdItm_XML			base.tv_RprdItm_XML			READONLY,	
	--@tv_SwtchdItm_XML		base.tv_SwtchdItm_XML		READONLY	No such item in sample data
	@tv_Amt_XML				base.tv_Amt_XML				READONLY,
	@tv_Entities_XML		base.tv_Entities_XML		READONLY,		
	@tv_Entity_XML			base.tv_Entity_XML			READONLY

	--@tv_DbtItmFrdData_XML   base.tv_DbtItmFrdData_XML	READONLY
	--tv_Entities_XML
	--tv_Entity_XML
	--@tv_DfltdItm_XML		base.tv_DfltdItm_XML		READONLY,	
	--@tv_HghstAmt_XML		base.tv_HghstAmt_XML		READONLY,		
	--@tv_DbtDplctItm_XML		base.tv_DbtDplctItm_XML		READONLY,		
	--@tv_DbtStopdItm_XML		base.tv_DbtStopdItm_XML		READONLY,		
	--@tv_ICN_XML				base.tv_ICN_XML				READONLY,			
	--@tv_Entities_XML		base.tv_Entities_XML		READONLY,		
	--@tv_Entity_XML			base.tv_Entity_XML			READONLY	
AS
BEGIN
	DECLARE @DoAudit bit=1;

	IF @DoAudit = 1
	BEGIN
		-- Start Of Auditing
		EXEC [Base].[XML_06MA01Message_v2_Audit_tv_GrpHdr_XML]			@tv_GrpHdr_XML;
		EXEC [Base].[XML_06MA01Message_v2_Audit_tv_Core_XML]			@tv_Core_XML;			
		EXEC [Base].[XML_06MA01Message_v2_Audit_tv_TxSet_XML]			@tv_TxSet_XML;
		EXEC [Base].[XML_06MA01Message_v2_Audit_tv_DbtItm_XML]			@tv_DbtItm_XML;
		EXEC [Base].[XML_06MA01Message_v2_Audit_tv_ItmImgData_XML]		@tv_ItmImgData_XML;
		EXEC [Base].[XML_06MA01Message_v2_Audit_tv_CrdItm_XML]			@tv_CrdItm_XML;
		EXEC [Base].[XML_06MA01Message_v2_Audit_tv_CdtItmFrdDate_XML]	@tv_CdtItmFrdDate_XML;
		EXEC [Base].[XML_06MA01Message_v2_Audit_RprdItm_XML]			@tv_RprdItm_XML;	
		EXEC [Base].[XML_06MA01Message_v2_Audit_tv_Amt_XML]				@tv_Amt_XML;
	 	EXEC [Base].[XML_06MA01Message_v2_Audit_tv_Entities_XML]		@tv_Entities_XML;
		EXEC [Base].[XML_06MA01Message_v2_Audit_tv_Entity_XML]			@tv_Entity_XML;
	END

	DECLARE @tv_DfltdItm_XML	AS base.tv_DfltdItm_XML;
	DECLARE @CoreId				AS BIGINT;
	DECLARE @DocumentId         AS BIGINT;
	DECLARE @BusinessDate		AS date;
	DECLARE @DocumentType		AS Varchar(10);
    DECLARE @RowPattern			AS VARCHAR(150);
    Declare @iDoc				AS INT;-- input parameter of main SP
	Declare @XMLMessageID		AS BIGINT; -- input parameter of main SP
    
	SET @RowPattern += '/doc:GrpHdr';
    SET @BusinessDate ='2019-07-26';
	SET @CoreId = CAST(CONCAT(CONVERT(VARCHAR(8), @BusinessDate, 112), REPLICATE('0', 11)) AS BIGINT) + NEXT VALUE FOR [Base].[sqn_MsgID];
	SET @DocumentId = CAST(CONCAT(CONVERT(VARCHAR(8), @BusinessDate, 112), REPLICATE('0', 11)) AS BIGINT) + NEXT VALUE FOR [Base].[sqn_MsgID];
	SET @DocumentType = 'MSG06'
    SET @RowPattern = Base.cfn_XML_Get_WrapperXPath(@DocumentType)
		
	--Generate the unique DocumentId
	-- ----------------------------------------------------------------------------------------------
	-- Write The Core
	-- ----------------------------------------------------------------------------------------------
	EXEC [Base].[XML_06MA01Message_Core] @tv_Core_XML, @BusinessDate, @CoreId;
	
	EXEC [Base].[XML_06MA01Message_Document] @tv_GrpHdr_XML, @BusinessDate, @DocumentId, @XMLMessageID, @DocumentType;
	--EXEC [Base].[XML_06MA01Message_Txset] @tv_TxSet_XML, @DocumentId, @CoreId;


	--EXEC [Base].[XML_06MA01Message_TXSet]
	EXEC [Base].[XML_06MA01Message_Credit] @tv_CrdItm_XML, @tv_CdtItmFrdDate_XML, @tv_RprdItm_XML,@tv_DbtItm_XML,@tv_Amt_XML,  @CoreId;
	--EXEC [Base].[XML_06MA01Message_Debit]  @tv_DbtItm_XML, @tv_ItmImgData_XML, @tv_Amt_XML, @tv_TxSet_XML, tv_RprdItm_XML,  @BusinessDate, @CoreId;  --DbtItmFrdData, @tv_HghstAmt_XML, @tv_DbtDplctItm_XML, @tv_DbtStopdItm_XML, @tv_DfltdItm_XML? Missing
	EXEC [Base].[XML_06MA01Message_Entity] @tv_Entity_XML, @CoreId;
   
END