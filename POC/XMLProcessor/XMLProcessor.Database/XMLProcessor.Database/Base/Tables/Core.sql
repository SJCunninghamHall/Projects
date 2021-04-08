CREATE TABLE [Base].[Core] (
    [CoreId]           BIGINT       NOT NULL,
    [ExtractId]        VARCHAR (26) NOT NULL,
    [PostingExtractId] VARCHAR (26) NULL,
    [ParticipantId]    VARCHAR (6)  NOT NULL,
    [MessageType]      TINYINT      NOT NULL,
    [IntMessageType]   CHAR (6)     NULL,
    [Source]           VARCHAR (5)  NOT NULL,
    [Destination]      VARCHAR (5)  NOT NULL,
    [RecordCount]      INT          NOT NULL,
    [XMLMessageId]     BIGINT       NOT NULL,
    CONSTRAINT [Core_PrimaryKey] PRIMARY KEY NONCLUSTERED HASH ([CoreId]) WITH (BUCKET_COUNT = 8388608)
)
WITH (MEMORY_OPTIMIZED = ON);

