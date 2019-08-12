CREATE TYPE [Base].[tv_StgCore] AS TABLE (
    [BusinessDate]            VARCHAR (10) NULL,
    [ExtractId]               VARCHAR (26) NULL,
    [ProcessingParticipantId] VARCHAR (6)  NULL,
    [ExtMessageType]          VARCHAR (6)  NULL,
    [IntMessageType]          VARCHAR (6)  NULL,
    [MessageSource]           VARCHAR (5)  NULL,
    [MessageDestination]      VARCHAR (5)  NULL,
    [RecordCount]             INT          NULL,
    [ICN_Id]                  BIGINT       NOT NULL,
    PRIMARY KEY CLUSTERED ([ICN_Id] ASC));

