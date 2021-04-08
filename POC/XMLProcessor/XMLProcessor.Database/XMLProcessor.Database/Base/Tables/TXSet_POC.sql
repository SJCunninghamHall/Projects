CREATE TABLE [Base].[TXSet_POC] (
    [DocumentId]                  BIGINT        NOT NULL,
    [InternalTxId]                BIGINT        NOT NULL,
    [CollectingPId]               VARCHAR (6)   NOT NULL,
    [TXIdDate]                    DATE          NOT NULL,
    [Source]                      SMALLINT      NOT NULL,
    [Sequence]                    INT           NOT NULL,
    [Version]                     TINYINT       NULL,
    [CollectingParticipantId]     VARCHAR (6)   NULL,
    [AltSource]                   SMALLINT      NULL,
    [CaptureDate]                 DATETIME2 (2) NULL,
    [TSetSubmissionDateTime]      DATETIME2 (2) NULL,
    [NumberOfItems]               INT           NULL,
    [EndPointId]                  VARCHAR (6)   NULL,
    [CollectingBranchLocation]    VARCHAR (8)   NULL,
    [CollectingLocation]          VARCHAR (10)  NULL,
    [ChannelRiskType]             VARCHAR (4)   NULL,
    [ChannelDescription]          VARCHAR (255) NULL,
    [CollectionPoint]             VARCHAR (20)  NULL,
    [CollectionBranchRef]         VARCHAR (255) NULL,
    [FraudCheckOnly]              BIT           NULL,
    [TransactionSetIdWithVersion] VARCHAR (24)  NULL,
    [TransactionSetId]            VARCHAR (22)  NULL,
    CONSTRAINT [TX_TXSet_POC_PK] PRIMARY KEY NONCLUSTERED HASH ([InternalTxId]) WITH (BUCKET_COUNT = 4194304)
)
WITH (MEMORY_OPTIMIZED = ON);

