CREATE TABLE [Base].[Document] (
    [DocumentId]             BIGINT        NOT NULL,
    [ParticipantId]          VARCHAR (6)   NOT NULL,
    [SubmissionDate]         DATE          NOT NULL,
    [Mechanism]              CHAR (1)      NOT NULL,
    [SubmissionCounter]      BIGINT        NOT NULL,
    [CreatedDate]            DATETIME2 (3) NOT NULL,
    [NumberOfEntries]        BIGINT        NULL,
    [ReceiverParticipantId]  VARCHAR (6)   NULL,
    [SenderParticipantId]    VARCHAR (6)   NULL,
    [ChargedParticipantId]   VARCHAR (6)   NULL,
    [DocumentType]           TINYINT       NULL,
    [Signature]              VARCHAR (MAX) NULL,
    [XMLMessageId]           BIGINT        NULL,
    [TestFlag]               BIT           NULL,
    [NumberOfTxSetSubmitted] INT           NULL,
    [NumberOfTxSetAccepted]  INT           NULL,
    [NumberOfTxSetRejected]  INT           NULL,
    [DocumentMessageID]      VARCHAR (23)  NULL,
    CONSTRAINT [Document_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([DocumentId]) WITH (BUCKET_COUNT = 4194304),
    CONSTRAINT [FK_Document_DocumentType] FOREIGN KEY ([DocumentType]) REFERENCES [Lookup].[MessageType] ([MessageId]),
    CONSTRAINT [FK_Document_FileId] FOREIGN KEY ([XMLMessageId]) REFERENCES [Base].[XMLMessage] ([Id]),
    INDEX [IDX_FileId] NONCLUSTERED ([XMLMessageId]),
    INDEX [IDX_DocumentMessageID] NONCLUSTERED ([DocumentMessageID]),
    INDEX [IDX_CompositeKey] NONCLUSTERED ([ParticipantId], [SubmissionDate], [Mechanism], [SubmissionCounter])
)
WITH (MEMORY_OPTIMIZED = ON);

