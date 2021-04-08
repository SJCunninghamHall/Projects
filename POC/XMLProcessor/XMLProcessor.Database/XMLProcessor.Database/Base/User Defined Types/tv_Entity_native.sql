CREATE TYPE [Base].[tv_Entity_native] AS TABLE
(
	EntityType CHAR(1)			NULL
	,EntityId VARCHAR(99)		NULL
	,StateRevision INT			NULL
	,EntityState SMALLINT		NULL
	,SourceDateTime DATETIME2(3) NULL
	,Entities_Id BIGINT			NULL
	,INDEX [Entities_Id] NONCLUSTERED HASH ([Entities_Id]) WITH (BUCKET_COUNT = 8)  -- added this line	
)WITH(MEMORY_OPTIMIZED = ON);
GO