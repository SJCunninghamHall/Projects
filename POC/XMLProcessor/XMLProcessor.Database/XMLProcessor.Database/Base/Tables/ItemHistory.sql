CREATE TABLE [Base].[ItemHistory] (
    [HistoryId]                           BIGINT          NOT NULL,
    [ItemId]                              BIGINT          NOT NULL,
    [Revision]                            INT             NOT NULL,
    [UserId]                              VARCHAR (64)    NOT NULL,
    [Time]                                DATETIME2 (3)   NOT NULL,
    [Process]                             VARCHAR (25)    NOT NULL,
    [Gender]                              CHAR (3)        NOT NULL,
    [Reference]                           VARCHAR (20)    NULL,
    [Account]                             VARCHAR (13)    NULL,
    [Sortcode]                            VARCHAR (6)     NULL,
    [TranCode]                            CHAR (2)        NULL,
    [JGAccount]                           VARCHAR (11)    NULL,
    [Amount]                              DECIMAL (11, 2) NULL,
    [IsDeleted]                           BIT             NOT NULL,
    [IsOnus]                              BIT             NULL,
    [AdjustmentReason]                    TINYINT         NULL,
    [PNVReviewStatus]                     TINYINT         NULL,
    [DuplicateStatus]                     TINYINT         NULL,
    [SameDayDuplicateStatus]              VARCHAR (30)    NULL,
    [IsExcludeFromSameDayDuplicateDetect] TINYINT         NULL,
    [VerificationStatus]                  VARCHAR (50)    NULL,
    CONSTRAINT [ItemHistory_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([HistoryId]) WITH (BUCKET_COUNT = 4194304),
    INDEX [NCI_ItemId] NONCLUSTERED ([ItemId])
)
WITH (MEMORY_OPTIMIZED = ON);

