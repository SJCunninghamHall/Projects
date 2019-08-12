CREATE TYPE [Base].[tv_HighestAmount_native] AS TABLE
(
	Ccy VARCHAR(MAX)		NULL
	,HghstAmt_Txt VARCHAR(30) NULL
	,DbtItmFrdData_Id BIGINT PRIMARY KEY  NONCLUSTERED  -- this line has changed from 	,DbtItmFrdData_Id BIGINT PRIMARY KEY(DbtItmFrdData_Id)
)WITH(MEMORY_OPTIMIZED = ON);
GO