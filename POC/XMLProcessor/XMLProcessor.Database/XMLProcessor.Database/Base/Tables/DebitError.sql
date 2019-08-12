CREATE TABLE [Base].[DebitError] (
    [DebitId]          BIGINT        NOT NULL,
    [InternalSqn]      SMALLINT      NOT NULL,
    [ErrorCode]        CHAR (4)      NOT NULL,
    [ErrorDescription] VARCHAR (256) NOT NULL,
    CONSTRAINT [TXErr_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([DebitId], [InternalSqn]) WITH (BUCKET_COUNT = 524288)
)
WITH (MEMORY_OPTIMIZED = ON);

