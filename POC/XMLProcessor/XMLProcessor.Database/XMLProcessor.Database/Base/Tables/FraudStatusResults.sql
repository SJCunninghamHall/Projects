CREATE TABLE [Base].[FraudStatusResults] (
    [FraudId]             BIGINT          NOT NULL,
    [TransactionSetId]    VARCHAR (25)    NULL,
    [ItemId]              VARCHAR (25)    NOT NULL,
    [FraudResult]         VARCHAR (15)    NULL,
    [FraudReason]         VARCHAR (4)     NULL,
    [FraudStatusId]       BIGINT          NOT NULL,
    [FirstChequeDate]     DATE            NULL,
    [LastChequeDate]      DATE            NULL,
    [CounterpartiesCount] INT             NULL,
    [GoodChequesCount]    INT             NULL,
    [FraudChequesCount]   INT             NULL,
    [LargestAmount]       DECIMAL (11, 2) NULL,
    [RiskIndicator]       INT             NULL,
    CONSTRAINT [FraudResults_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([FraudId]) WITH (BUCKET_COUNT = 8388608),
    CONSTRAINT [FraudStatus_FraudStatusId] FOREIGN KEY ([FraudStatusId]) REFERENCES [Base].[FraudStatus] ([FraudStatusId]),
    INDEX [NCI_FraudStatusId] NONCLUSTERED ([FraudStatusId]),
    INDEX [NCI_Fraud_ItemId] NONCLUSTERED ([ItemId])
)
WITH (MEMORY_OPTIMIZED = ON);

