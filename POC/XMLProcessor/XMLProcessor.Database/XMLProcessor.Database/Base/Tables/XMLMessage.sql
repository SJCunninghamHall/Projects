CREATE TABLE [Base].[XMLMessage] (
    [Id]            BIGINT        NOT NULL,
    [MessageName]   VARCHAR (150) NOT NULL,
    [MessageSeen]   DATETIME2 (2) NOT NULL,
    [StartTime]     DATETIME2 (2) NOT NULL,
    [ShredTime]     DATETIME2 (2) NULL,
    [TransformTime] DATETIME2 (2) NULL,
    [EndTime]       DATETIME2 (2) NULL,
    CONSTRAINT [XMLFile_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([Id]) WITH (BUCKET_COUNT = 8388608),
    INDEX [NCI_MessageName] NONCLUSTERED ([MessageName])
)
WITH (MEMORY_OPTIMIZED = ON);

