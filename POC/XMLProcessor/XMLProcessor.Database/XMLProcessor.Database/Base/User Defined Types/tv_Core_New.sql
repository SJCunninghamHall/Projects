CREATE TYPE [Base].[tv_Core_New] AS TABLE (
    [CoreId]           BIGINT       NOT NULL,
    [ExtractId]        VARCHAR (26) NOT NULL,
    [PostingExtractId] VARCHAR (26) NULL,
    [ParticipantId]    VARCHAR (6)  NOT NULL,
    [MessageType]      TINYINT      NULL,
    [MessageTypeXML]   VARCHAR (6)  NOT NULL,
    [IntMessageType]   CHAR (6)     NULL,
    [Source]           VARCHAR (5)  NOT NULL,
    [Destination]      VARCHAR (5)  NOT NULL,
    [RecordCount]      INT          NOT NULL,
    [XMLMessageId]     BIGINT       NULL,
    [RowNumber]        BIGINT       IDENTITY (1, 1) NOT NULL,
    INDEX [IX_tv_Core_PK] ([CoreId]))
    WITH (MEMORY_OPTIMIZED = ON);
GO