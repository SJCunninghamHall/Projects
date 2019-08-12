CREATE TYPE [Base].[tv_Document_New1] AS TABLE (
    [DocumentId]    BIGINT      NOT NULL,
    [ParticipantId] VARCHAR (6) NOT NULL,
    [RowNumber]     BIGINT      IDENTITY (1, 1) NOT NULL,
    INDEX [IX_tv_DocumentId] ([DocumentId]))
    WITH (MEMORY_OPTIMIZED = ON);

