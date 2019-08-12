CREATE TYPE [Base].[tv_CreditFraudData] AS TABLE (
    [ItemId]                  BIGINT          NOT NULL,
    [BeneficiaryName]         VARCHAR (50)    NULL,
    [ReferenceData]           VARCHAR (20)    NULL,
    [CashAmount]              NUMERIC (20, 2) NULL,
    [CashAmountCurrency]      TINYINT         NULL,
    [FundedAmount]            NUMERIC (20, 2) NULL,
    [FundedAmountCurrency]    TINYINT         NULL,
    [NonFundedAmount]         NUMERIC (20, 2) NULL,
    [NonFundedAmountCurrency] TINYINT         NULL,
    [NumberOfItems]           INT             NULL,
    [VirtualCredit]           BIT             NULL,
    [ChequeAtRisk]            BIT             NULL,
    INDEX [IX_tv_CreditFraudData] ([ItemId]))
    WITH (MEMORY_OPTIMIZED = ON);
GO