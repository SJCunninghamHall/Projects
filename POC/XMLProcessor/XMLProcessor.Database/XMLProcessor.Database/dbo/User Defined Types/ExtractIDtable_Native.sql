CREATE TYPE [dbo].[ExtractIDtable_Native] AS TABLE (
    [ExtractId]           VARCHAR (26) NULL,
    [MessageType]         VARCHAR (6)  NULL,
    [InternalMessageType] VARCHAR (6)  NULL,
    INDEX [IX_ExtractId] NONCLUSTERED HASH ([ExtractId]) WITH (BUCKET_COUNT = 8))
    WITH (MEMORY_OPTIMIZED = ON);
GO