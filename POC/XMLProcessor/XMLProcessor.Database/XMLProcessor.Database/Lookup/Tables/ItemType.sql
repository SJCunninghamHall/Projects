CREATE TABLE [Lookup].[ItemType] (
    [Id]                  TINYINT       NOT NULL,
    [ItemTypeCode]        CHAR (4)      NOT NULL,
    [CRDRIndicator]       VARCHAR (6)   NOT NULL,
    [ItemTypeDescription] VARCHAR (100) NULL,
    CONSTRAINT [ItemType_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([Id]) WITH (BUCKET_COUNT = 32),
    INDEX [NCI_ItemTypeCode] NONCLUSTERED HASH ([ItemTypeCode]) WITH (BUCKET_COUNT = 32)
)
WITH (MEMORY_OPTIMIZED = ON);

