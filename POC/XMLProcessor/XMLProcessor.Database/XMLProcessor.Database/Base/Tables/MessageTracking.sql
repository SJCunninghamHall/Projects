CREATE TABLE [Base].[MessageTracking] (
    [Id]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [Timestamp]   DATETIME2 (3) DEFAULT (getdate()) NOT NULL,
    [Queue]       VARCHAR (100) NOT NULL,
    [MessageType] VARCHAR (250) NULL,
    [Message]     VARCHAR (MAX) NOT NULL,
    CONSTRAINT [MessageTracking_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([Id]) WITH (BUCKET_COUNT = 16384)
)
WITH (MEMORY_OPTIMIZED = ON);

