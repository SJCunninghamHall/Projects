CREATE TABLE [Base].[AckNakDocumentStatus] (
    [StatusId]          BIGINT   NOT NULL,
    [DocumentId]        BIGINT   NOT NULL,
    [ParticipantId]     INT      NOT NULL,
    [SubmissionDate]    DATE     NOT NULL,
    [Mechanism]         CHAR (1) NOT NULL,
    [SubmissionCounter] BIGINT   NOT NULL,
    CONSTRAINT [AckNakDocumentStatus_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([StatusId]) WITH (BUCKET_COUNT = 4194304),
    CONSTRAINT [FK_AckNakDocumentStatus_DocumentId] FOREIGN KEY ([DocumentId]) REFERENCES [Base].[Document] ([DocumentId]),
    INDEX [NCI_DocumentId] NONCLUSTERED ([DocumentId])
)
WITH (MEMORY_OPTIMIZED = ON);

