CREATE TYPE [Base].[tv_Entity_STG2] AS TABLE (
    [Alpa_ID]        BIGINT        IDENTITY (1, 1) NOT NULL,
    [EntityType]     CHAR (1)      NULL,
    [EntityId]       BIGINT        NULL,
    [StateRevision]  INT           NULL,
    [EntityState]    SMALLINT      NULL,
    [SourceDateTime] DATETIME2 (3) NULL,
    [Entities_Id]    BIGINT        NULL,
    INDEX [Entities_Id] NONCLUSTERED HASH ([Entities_Id]) WITH (BUCKET_COUNT = 8))
    WITH (MEMORY_OPTIMIZED = ON);

