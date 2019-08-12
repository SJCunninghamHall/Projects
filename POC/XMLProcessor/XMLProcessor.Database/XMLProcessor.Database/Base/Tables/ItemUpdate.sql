CREATE TABLE [Base].[ItemUpdate] (
    [InternalId]               BIGINT          NOT NULL,
    [ItemId]                   VARCHAR (25)    NOT NULL,
    [ProcessId]                VARCHAR (26)    NULL,
    [OperatorId]               VARCHAR (20)    NULL,
    [UpdateDateTime]           DATETIME2 (2)   NULL,
    [Revision]                 INT             NULL,
    [PayingParticipantId]      CHAR (6)        NULL,
    [BeneficiaryParticipantId] CHAR (6)        NULL,
    [Gender]                   CHAR (3)        NULL,
    [AdjustmentReason]         TINYINT         NULL,
    [NoPayReason]              VARCHAR (30)    NULL,
    [CoreID]                   BIGINT          NULL,
    [OriginalAmount]           DECIMAL (11, 2) NULL,
    [ICSAmount]                DECIMAL (11, 2) NULL,
    CONSTRAINT [ItemUpdate_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([InternalId]) WITH (BUCKET_COUNT = 8388608),
    INDEX [NCI_ItemUpdateId_Range] NONCLUSTERED ([InternalId]),
    INDEX [NCI_ItemUpdate_ItemID] NONCLUSTERED ([ItemId])
)
WITH (MEMORY_OPTIMIZED = ON);

