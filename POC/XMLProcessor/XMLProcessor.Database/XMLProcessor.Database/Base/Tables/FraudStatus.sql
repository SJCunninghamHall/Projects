CREATE TABLE [Base].[FraudStatus] (
    [FraudStatusId]   BIGINT        NOT NULL,
    [CreationDate]    DATETIME2 (2) NULL,
    [NumberOfEntries] BIGINT        NULL,
    [ResponseType]    VARCHAR (5)   NULL,
    [CoreId]          BIGINT        NOT NULL,
    CONSTRAINT [Fraud_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([FraudStatusId]) WITH (BUCKET_COUNT = 8388608),
    CONSTRAINT [Fraud_CoreId] FOREIGN KEY ([CoreId]) REFERENCES [Base].[Core] ([CoreId]),
    INDEX [NCI_StatusId] NONCLUSTERED ([CoreId])
)
WITH (MEMORY_OPTIMIZED = ON);

