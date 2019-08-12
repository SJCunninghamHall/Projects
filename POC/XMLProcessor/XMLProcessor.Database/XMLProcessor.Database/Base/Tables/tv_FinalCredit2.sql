CREATE TABLE [Base].[tv_FinalCredit2] (
    [ItemId]   BIGINT NULL,
    [CreditId] BIGINT NOT NULL,
    [rowc]     INT    IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY NONCLUSTERED ([CreditId] ASC),
    INDEX [IX_tv_FinalCredit_Reference] NONCLUSTERED ([ItemId], [CreditId])
)
WITH (MEMORY_OPTIMIZED = ON);

