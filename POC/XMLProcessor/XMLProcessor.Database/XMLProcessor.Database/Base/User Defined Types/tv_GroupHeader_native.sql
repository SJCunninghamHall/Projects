CREATE TYPE [Base].tv_GroupHeader_native AS TABLE
(
	MsgId VARCHAR(50)					NULL
	,CreatedDatetime DATETIME2(7)		NULL
	,NoOftransactions SMALLINT			NULL
	,ReceiverId VARCHAR(6)				NULL
--	,SndrId VARCHAR(MAX) 			NULL
	--,DrctPtcpt VARCHAR(MAX) 		NULL
	,TstInd BIT							NULL
	--,DocTp VARCHAR(6)					NULL
	,[Signature] VARCHAR(MAX)			NULL
	,ReqToPay_Id BIGINT PRIMARY KEY NONCLUSTERED

)WITH(MEMORY_OPTIMIZED = ON);
GO