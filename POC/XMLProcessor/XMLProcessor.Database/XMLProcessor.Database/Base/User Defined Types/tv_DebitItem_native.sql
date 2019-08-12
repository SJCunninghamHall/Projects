CREATE TYPE [Base].[tv_DebitItem_native] AS TABLE
(
	DbtItmId VARCHAR(25) 				NULL
	--,Amt DECIMAL(14,2)							NULL
	,DbtItmTp CHAR(4)							NULL
	--,DbtItmTxCd CHAR(2)							NULL
	,RpresentdItmInd BIT						NULL
	,DbtItm_Id BIGINT primary key	 NONCLUSTERED			
	,BkCd INT									NULL
	,AcctNb INT									NULL
	,SrlNb INT									NULL
	,HghValItm BIT								NULL
	--,PayDcsnRsnCd CHAR(4)						NULL
	--,PayDcsnInd BIT								NULL
	--,SttlmPrdId BIGINT							NULL
	--,OnUsItmInd BIT								NULL
	--,FrdStsCd CHAR(4)							NULL
	--,FrdRsnCd CHAR(4)							NULL
	,DayOneRspnWndwStartDatetime DATETIME2(7)	NULL
	,DayOneRspnWndwEndDatetime DATETIME2(7)		NULL
	,DayTwoRspnWndwStartDatetime DATETIME2(7)	NULL
	,DayTwoRspnWndwEndDatetime DATETIME2(7)		NULL
	,XmlDataRef VARCHAR(256)					NULL
	,TxSet_Id INT 								NULL
)WITH(MEMORY_OPTIMIZED = ON);
GO