CREATE TYPE [Base].[tv_FraudInfo] AS TABLE (
    [TransactionSetId] VARCHAR (25) NULL,
    [ItemId]           VARCHAR (25) NULL,
    [FraudCheckResult] VARCHAR (15) NULL,
    [FraudCheckReason] VARCHAR (4)  NULL,
    INDEX [IX_CoreEntityStateID] ([ItemId]))
    WITH (MEMORY_OPTIMIZED = ON);

