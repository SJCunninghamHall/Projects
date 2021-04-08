CREATE TABLE [Base].[AckNakStatusReasonInfo] (
    [StatusId]          BIGINT         NOT NULL,
    [ReasonId]          BIGINT         NOT NULL,
    [ReasonCode]        CHAR (4)       NOT NULL,
    [ReasonDescription] VARCHAR (256)  NULL,
    [ErrorLocation]     VARCHAR (1000) NULL,
    CONSTRAINT [AckNakStatusReasonInfo_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([ReasonId]) WITH (BUCKET_COUNT = 8388608),
    CONSTRAINT [FK_AckNakStatusReasonInfo_StatusId] FOREIGN KEY ([StatusId]) REFERENCES [Base].[AckNakDocumentStatus] ([StatusId]),
    INDEX [NCI_StatusId] NONCLUSTERED ([StatusId])
)
WITH (MEMORY_OPTIMIZED = ON);

