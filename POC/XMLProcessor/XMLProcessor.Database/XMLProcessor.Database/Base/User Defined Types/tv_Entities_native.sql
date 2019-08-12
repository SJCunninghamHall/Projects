--10 tv_Entities_native
CREATE TYPE [Base].[tv_Entities_native] AS TABLE
(
	Entities_Id VARCHAR(99) NULL
	,ICN_Id BIGINT NULL
	,INDEX [ICN_Id] NONCLUSTERED HASH ([ICN_Id]) WITH (BUCKET_COUNT = 8)  -- added this line
)WITH(MEMORY_OPTIMIZED = ON);
GO