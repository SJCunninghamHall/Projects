CREATE TABLE [Base].[EntityError] (
    [EntityId]         BIGINT        NOT NULL,
    [EntityStateID]    TINYINT       NOT NULL,
    [ErrorCode]        VARCHAR (4)   NOT NULL,
    [ErrorDescription] VARCHAR (256) NOT NULL,
    CONSTRAINT [EntityError_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([EntityStateID], [EntityId]) WITH (BUCKET_COUNT = 8388608),
    INDEX [IDX_EntityUpdateID] UNIQUE NONCLUSTERED ([EntityStateID], [EntityId])
)
WITH (MEMORY_OPTIMIZED = ON);

