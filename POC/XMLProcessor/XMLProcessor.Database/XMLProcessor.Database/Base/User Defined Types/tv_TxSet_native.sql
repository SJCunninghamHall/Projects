CREATE TYPE [Base].[tv_TxSet_native] AS TABLE
(
	TxSetId VARCHAR(22)					  NULL
	,TxSetVersion TINYINT				  NULL
	,CollectionParticipantId VARCHAR(6)	  NULL
	,CapturedDateTime DATETIME2(7)		  NULL
	,TxSetSubmissionDateTime DATETIME2(2) NULL
	,[Source] SMALLINT					  NULL
	,CollectionBranchLocation VARCHAR(8)  NULL
	,CollectingLocation VARCHAR(10)		  NULL
	,ChannelRsktp VARCHAR(4)			  NULL
	,ChannelDescription VARCHAR(256)	  NULL
	,CollectionPoint VARCHAR(20)		  NULL
	,CollectionBranchRef VARCHAR(256)	  NULL
	,NoOfItems INT						  NULL
	,EndPtId VARCHAR(6)					  NULL
	,TxSet_Id BIGINT					  
	,ReqToPay_Id BIGINT					  
--	,FrdChckOnlyInd BIT					  NULL

	--PRIMARY KEY(TxSet_Id,ReqToPay_Id)
		,INDEX [IX_TxSet_ReqToPay_Id] NONCLUSTERED HASH ([TxSet_Id],[ReqToPay_Id]) WITH (BUCKET_COUNT = 8) 

)WITH(MEMORY_OPTIMIZED = ON);
 GO