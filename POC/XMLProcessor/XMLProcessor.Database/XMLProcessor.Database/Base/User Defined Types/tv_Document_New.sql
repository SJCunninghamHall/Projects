CREATE TYPE [Base].[tv_Document_New] AS TABLE (
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
    [DocumentTypeXML]        VARCHAR (6)   NULL,
    [Signature]              VARCHAR (MAX) NULL,
    [XMLMessageId]           BIGINT        NULL,
    [TestFlag]               BIT           NULL,
    [NumberOfTxSetSubmitted] INT           NULL,
    [NumberOfTxSetAccepted]  INT           NULL,
    [NumberOfTxSetRejected]  INT           NULL,
    [DocumentMessageID]      VARCHAR (23)  NULL,
    [RowNumber]              BIGINT        IDENTITY (1, 1) NOT NULL,
    INDEX [IX_tv_DocumentId] ([DocumentId]))
    WITH (MEMORY_OPTIMIZED = ON);

