CREATE TABLE [Base].[Entity] (
    [EntityId]         BIGINT        NOT NULL,
    [CoreId]           BIGINT        NOT NULL,
    [EntityType]       CHAR (1)      NOT NULL,
    [EntityIdentifier] VARCHAR (99)  NOT NULL,
    [Revision]         INT           NULL,
    [EntityState]      SMALLINT      NOT NULL,
    [SourceDateTime]   DATETIME2 (3) NULL,
    CONSTRAINT [EntityUpdate_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([EntityId]) WITH (BUCKET_COUNT = 8388608),
    CONSTRAINT [FK_Entity_Core] FOREIGN KEY ([CoreId]) REFERENCES [Base].[Core] ([CoreId]),
    INDEX [NCI_CoreId] NONCLUSTERED ([CoreId]),
    INDEX [IDX_EntityUpdateID] UNIQUE NONCLUSTERED ([EntityId]),
    INDEX [IDX_Entity_Type] NONCLUSTERED HASH ([EntityType], [EntityIdentifier]) WITH (BUCKET_COUNT = 8388608),
    INDEX [IDX_Entity_State] NONCLUSTERED ([EntityState], [EntityIdentifier]),
    INDEX [IDX_Entity_Identifier] NONCLUSTERED ([EntityIdentifier], [Revision] DESC, [EntityId] DESC),
    INDEX [IDX_Entity_EntityIdentifier_EntityState] NONCLUSTERED ([EntityIdentifier], [EntityState]),
    INDEX [IDX_Base_Entity_EntityIdentifier_Multi] NONCLUSTERED ([EntityIdentifier], [EntityType], [Revision] DESC, [EntityId] DESC)
)
WITH (MEMORY_OPTIMIZED = ON);

