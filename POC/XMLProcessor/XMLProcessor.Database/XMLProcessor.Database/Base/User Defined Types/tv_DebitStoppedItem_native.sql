--8.tv_DebitStoppedItem_native
CREATE TYPE [Base].[tv_DebitStoppedItem_native] AS TABLE
(
	StoppedDate VARCHAR(MAX)			NULL
	,StoppedStatus VARCHAR(MAX)			NULL
	,DbtStoppedItem_Id INT				NULL
	,BeneficiaryName VARCHAR(MAX)		NULL
	,StoppedItemStartFlg VARCHAR(MAX)	NULL
	,StoppedItemEndFlg VARCHAR(MAX)		NULL
	--,Amt DECIMAL(14,2)					NULL
	,DbtItem_Id INT PRIMARY KEY		NONCLUSTERED	
)WITH(MEMORY_OPTIMIZED = ON);
GO