﻿CREATE TABLE [Lookup].[MessageType] (
    [MessageId]   TINYINT      NOT NULL,
    [MessageType] VARCHAR (10) NOT NULL,
    CONSTRAINT [MessageType_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([MessageId]) WITH (BUCKET_COUNT = 128),
    INDEX [NCI_MessageType] UNIQUE NONCLUSTERED HASH ([MessageType]) WITH (BUCKET_COUNT = 128)
)
WITH (MEMORY_OPTIMIZED = ON);

