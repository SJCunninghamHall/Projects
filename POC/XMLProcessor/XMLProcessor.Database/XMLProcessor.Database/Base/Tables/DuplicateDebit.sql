CREATE TABLE [Base].[DuplicateDebit] (
    [ItemId]                        BIGINT       NOT NULL,
    [DuplicateItemId]               VARCHAR (25) NULL,
    [Status]                        CHAR (4)     NULL,
    [DateFirstSeen]                 DATE         NULL,
    [OriginalCollectingParticipant] VARCHAR (6)  NULL,
    [OriginalCaptureDate]           DATE         NULL,
    [OriginalSource]                SMALLINT     NULL,
    CONSTRAINT [DuplicateDebit_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([ItemId]) WITH (BUCKET_COUNT = 524288),
    CONSTRAINT [fk_Duplicate_Debit] FOREIGN KEY ([ItemId]) REFERENCES [Base].[Debit] ([ItemId]),
    INDEX [NCI_DuplicateDebit_DuplicateItemId] NONCLUSTERED ([DuplicateItemId])
)
WITH (MEMORY_OPTIMIZED = ON);

