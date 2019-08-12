CREATE TYPE [Base].[tv_EntityError_native] AS TABLE
(
	Entities_Id BIGINT		NULL
	,ErrorCode VARCHAR(4) NULL
	,ErrorDescription VARCHAR(256) NULL
	,INDEX [Entities_Id] NONCLUSTERED HASH ([Entities_Id]) WITH (BUCKET_COUNT = 8)  -- added this line	
)WITH(MEMORY_OPTIMIZED = ON);
GO