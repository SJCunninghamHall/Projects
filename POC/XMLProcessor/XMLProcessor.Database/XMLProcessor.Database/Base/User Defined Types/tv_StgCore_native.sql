CREATE TYPE [Base].[tv_StgCore_native] AS TABLE 
(
    [BusinessDate]            VARCHAR (10) NULL,
    [ExtractId]               VARCHAR (26) NULL,
    [ProcessingParticipantId] VARCHAR (6)  NULL,
    [ExtMessageType]          VARCHAR (6)  NULL,
    [IntMessageType]          VARCHAR (6)  NULL,
    [MessageSource]           VARCHAR (5)  NULL,
    [MessageDestination]      VARCHAR (5)  NULL,
    [RecordCount]             INT          NULL,
    [ICN_Id]                  BIGINT       NOT NULL,
    PRIMARY KEY NONCLUSTERED HASH ([ICN_Id]) WITH (BUCKET_COUNT = 131072))
    WITH (MEMORY_OPTIMIZED = ON);
GO