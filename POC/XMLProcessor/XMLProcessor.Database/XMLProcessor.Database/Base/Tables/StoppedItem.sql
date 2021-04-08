CREATE TABLE [Base].[StoppedItem] (
    [ItemId]             BIGINT          NOT NULL,
    [StoppedDate]        DATE            NULL,
    [Status]             CHAR (4)        NULL,
    [Amount]             DECIMAL (14, 2) NULL,
    [Currency]           TINYINT         NULL,
    [Beneficiary]        VARCHAR (50)    NULL,
    [StopItemStartRange] INT             NULL,
    [StopItemEndRange]   INT             NULL,
    CONSTRAINT [StoppedItem_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([ItemId]) WITH (BUCKET_COUNT = 524288)
)
WITH (MEMORY_OPTIMIZED = ON);

