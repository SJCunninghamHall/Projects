CREATE TYPE [Base].[tv_STGCore_XML] AS TABLE (
    [CoreId]                  BIGINT       NOT NULL,
    [BusinessDate]            VARCHAR (10) NULL,
    [ExtractId]               VARCHAR (26) NULL,
    [ProcessingParticipantId] VARCHAR (6)  NULL,
    [ExtMessageType]          VARCHAR (6)  NULL,
    [IntMessageType]          VARCHAR (6)  NULL,
    [MessageSource]           VARCHAR (5)  NULL,
    [MessageDestination]      VARCHAR (5)  NULL,
    [RecordCounts]            INT          NULL,
    [ICN_Id]                  BIGINT       NOT NULL,
    PRIMARY KEY NONCLUSTERED ([ICN_Id] ASC))
    WITH (MEMORY_OPTIMIZED = ON);

