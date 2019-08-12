CREATE TYPE [Base].[tv_Entity_XML] AS TABLE (
    [EntityType]     CHAR (1)     NULL,
    [EntityId]       VARCHAR (35) NULL,
    [StateRevision]  VARCHAR (35) NULL,
    [EntityState]    VARCHAR (35) NULL,
    [SourceDateTime] VARCHAR (35) NULL,
    [Entities_Id]    BIGINT       NULL,
    INDEX [Entities_Id] NONCLUSTERED HASH ([Entities_Id]) WITH (BUCKET_COUNT = 8))
    WITH (MEMORY_OPTIMIZED = ON);





