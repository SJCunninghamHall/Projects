CREATE TABLE [Lookup].[Currency] (
    [Id]                  TINYINT       NOT NULL,
    [Currency]            VARCHAR (10)  NOT NULL,
    [CurrencyDescription] VARCHAR (150) NULL,
    CONSTRAINT [Currency_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([Id]) WITH (BUCKET_COUNT = 8),
    INDEX [NCI_Currency] NONCLUSTERED HASH ([Currency]) WITH (BUCKET_COUNT = 8)
)
WITH (MEMORY_OPTIMIZED = ON);

