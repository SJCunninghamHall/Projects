CREATE TYPE [Base].[tv_StgTxSet_XML] AS TABLE (
    [TxSetId]          VARCHAR (22)  NULL,
    [TxSetVrsn]        TINYINT       NULL,
    [ColltngPtcptId]   VARCHAR (6)   NULL,
    [CaptrdDtTm]       DATETIME2 (7) NULL,
    [TxSetSubDtTm]     DATETIME2 (2) NULL,
    [Src]              SMALLINT      NULL,
    [ColltngBrnchLctn] VARCHAR (8)   NULL,
    [ColltngLctn]      VARCHAR (10)  NULL,
    [ChanlRskTp]       VARCHAR (4)   NULL,
    [ChanlDesc]        VARCHAR (256) NULL,
    [ColltnPt]         VARCHAR (20)  NULL,
    [ColltngBrnchRef]  VARCHAR (256) NULL,
    [NoOfItems]        INT           NULL,
    [EndPtId]          VARCHAR (6)   NULL,
    [TxSet_Id]         BIGINT        NULL,
    [ReqToPay_Id]      BIGINT        NULL,
    INDEX [IX_TxSet_ReqToPay_Id] NONCLUSTERED HASH ([TxSet_Id], [ReqToPay_Id]) WITH (BUCKET_COUNT = 8))
    WITH (MEMORY_OPTIMIZED = ON);

