CREATE TABLE [Base].[TXSetErr] (
    [InternalTxId]     BIGINT        NOT NULL,
    [InternalSqn]      SMALLINT      NOT NULL,
    [ErrorCode]        CHAR (4)      NOT NULL,
    [ErrorDescription] VARCHAR (255) NOT NULL,
    CONSTRAINT [TXSetErr_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([InternalTxId], [InternalSqn]) WITH (BUCKET_COUNT = 524288)
)
WITH (MEMORY_OPTIMIZED = ON);

