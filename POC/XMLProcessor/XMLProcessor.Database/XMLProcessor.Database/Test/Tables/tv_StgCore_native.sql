CREATE TABLE [Test].[tv_StgCore_native] (
    [BusinessDate]            VARCHAR (10) NULL,
    [ExtractId]               VARCHAR (26) NULL,
    [ProcessingParticipantId] VARCHAR (6)  NULL,
    [ExtMessageType]          VARCHAR (6)  NULL,
    [IntMessageType]          VARCHAR (6)  NULL,
    [MessageSource]           VARCHAR (5)  NULL,
    [MessageDestination]      VARCHAR (5)  NULL,
    [RecordCount]             INT          NULL,
    [ICN_Id]                  BIGINT       NOT NULL,
    CONSTRAINT [PK_MemoryOptTempTable] PRIMARY KEY NONCLUSTERED ([ICN_Id] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);

