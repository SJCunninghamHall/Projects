CREATE TYPE [Base].[ICNEntity_New] AS TABLE (
    [EntityId]         BIGINT        NULL,
    [CoreId]           BIGINT        NOT NULL,
    [EntityType]       CHAR (1)      NOT NULL,
    [EntityIdentifier] VARCHAR (99)  NOT NULL,
    [Revision]         INT           NOT NULL,
    [EntityState]      SMALLINT      NOT NULL,
    [SourceDateTime]   DATETIME2 (3) NULL,
    [ErrorCode]        VARCHAR (4)   NULL,
    [ErrorDescription] VARCHAR (256) NULL,
    INDEX [IX_EntityStateID] ([EntityId]))
    WITH (MEMORY_OPTIMIZED = ON);
GO 