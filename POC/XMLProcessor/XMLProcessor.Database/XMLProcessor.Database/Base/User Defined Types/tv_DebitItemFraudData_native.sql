-- 7 tv_DebitItemFraudData_native
CREATE TYPE [Base].[tv_DebitItemFraudData_native] AS TABLE
(
	ChqAtRskInd VARCHAR(MAX)			NULL
	,DtOfFrstChq VARCHAR(MAX)			NULL
	,DtOfLstChq VARCHAR(MAX)			NULL
	,NbOfCtrPtys VARCHAR(MAX)			NULL
	,NbOfVldChqs VARCHAR(MAX)			NULL
	,NofFrdChqs VARCHAR(MAX)			NULL
	--,HghstAmt DECIMAL(14,2)				NULL
	,DbtItmFrdData_Id BIGINT			NULL
	,RskInd VARCHAR(MAX)				NULL
	,DbtItm_Id BIGINT PRIMARY KEY NONCLUSTERED
)WITH(MEMORY_OPTIMIZED = ON);
GO