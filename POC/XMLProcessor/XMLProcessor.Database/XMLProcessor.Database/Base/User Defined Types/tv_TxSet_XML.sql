CREATE TYPE [Base].[tv_TxSet_XML] AS TABLE (
    [TxSetId]          VARCHAR (35)  NULL,
    [TxSetVrsn]        VARCHAR (35)  NULL,
    [ColltngPtcptId]   VARCHAR (35)  NULL,
    [CaptrdDtTm]       DATETIME2 (7) NULL,
    [TxSetSubDtTm]     DATETIME2 (2) NULL,
    [Src]              SMALLINT      NULL,
    [ColltngBrnchLctn] VARCHAR (8)   NULL,
    [ColltngLctn]      VARCHAR (10)  NULL,
    [ChanlRskTp]       VARCHAR (4)   NULL,
    [ChanlDesc]        VARCHAR (256) NULL,
    [ColltnPt]         VARCHAR (20)  NULL,
    [ColltngBrnchRef]  VARCHAR (256) NULL,
    [NbOfItms]         INT           NULL,
    [EndPtId]          VARCHAR (6)   NULL,
    [TxSet_Id]         VARCHAR (35)  NULL,
    [ReqToPay_Id]      VARCHAR (35)  NULL,
    INDEX [IX_TxSet_Id] NONCLUSTERED HASH ([TxSet_Id], [ReqToPay_Id]) WITH (BUCKET_COUNT = 8))
    WITH (MEMORY_OPTIMIZED = ON);

