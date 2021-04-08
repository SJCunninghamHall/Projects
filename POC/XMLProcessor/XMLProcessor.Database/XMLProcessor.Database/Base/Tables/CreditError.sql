CREATE TABLE [Base].[CreditError] (
    [CreditId]         BIGINT        NOT NULL,
    [InternalSqn]      SMALLINT      NOT NULL,
    [ErrorCode]        CHAR (4)      NOT NULL,
    [ErrorDescription] VARCHAR (255) NOT NULL,
    CONSTRAINT [CreditErr_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([CreditId], [InternalSqn]) WITH (BUCKET_COUNT = 524288)
)
WITH (MEMORY_OPTIMIZED = ON);

