CREATE TABLE [Base].[DebitFraudData] (
    [ItemId]                 BIGINT          NOT NULL,
    [DateOfFirstCheque]      DATE            NULL,
    [DateOfLastCheque]       DATE            NULL,
    [NumberOfCounterparties] INT             NULL,
    [NumberOfGoodCheques]    INT             NULL,
    [NumberOfFraudCheques]   INT             NULL,
    [LargestAmount]          NUMERIC (20, 2) NULL,
    [LargestAmountCurrency]  TINYINT         NULL,
    [RiskIndicator]          SMALLINT        NULL,
    [SuspiciousCheque]       BIT             NULL,
    CONSTRAINT [AdditionalFraudData_PrimaryKey] PRIMARY KEY NONCLUSTERED HASH ([ItemId]) WITH (BUCKET_COUNT = 524288),
    CONSTRAINT [fk_Fraud_Debit] FOREIGN KEY ([ItemId]) REFERENCES [Base].[Debit] ([ItemId])
)
WITH (MEMORY_OPTIMIZED = ON);

