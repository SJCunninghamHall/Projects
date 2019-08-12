CREATE TYPE [Base].[tv_TxSet_XML_native] AS TABLE (
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
    [NbOfItms]         INT           NULL,
    [EndPtId]          VARCHAR (6)   NULL,
    [CrdtItm]          VARCHAR (6)   NULL,
    [DbtItm]           VARCHAR (6)   NULL,
    INDEX [IX_TxSet_Id] NONCLUSTERED HASH ([TxSetId]) WITH (BUCKET_COUNT = 8))
    WITH (MEMORY_OPTIMIZED = ON);

