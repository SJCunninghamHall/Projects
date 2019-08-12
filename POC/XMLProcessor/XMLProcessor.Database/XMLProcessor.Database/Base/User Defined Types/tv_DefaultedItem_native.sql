--9 tv_DefaultedItem_native
CREATE TYPE [Base].[tv_DefaultedItem_native] AS TABLE
(
	BkCdDfltdInd VARCHAR(MAX)		NULL
	,AccNbDfltdInd VARCHAR(MAX)		NULL
	,RefNoDfltdInd VARCHAR(MAX)		NULL
	,CrdtItm_Id BIGINT				NULL
	,SrlNbDfltdInd VARCHAR(MAX)		NULL
	,DbtItm_Id BIGINT NULL
  , INDEX [IX_DbtItm_Id] NONCLUSTERED HASH ([DbtItm_Id]) WITH (BUCKET_COUNT = 8)  -- added this line
)WITH(MEMORY_OPTIMIZED = ON);
GO