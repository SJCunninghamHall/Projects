CREATE TYPE [Base].[tv_GrpHdr_XML] AS TABLE (
    [MsgId]       VARCHAR (35)  NULL,
    [CreDtTm]     DATETIME2 (7) NULL,
    [NbOfTxs]     VARCHAR (15)  NULL,
    [RcvrId]      VARCHAR (35)  NULL,
    [TstInd]      VARCHAR (5)   NULL,
    [Sgntr]       VARCHAR (MAX) NULL,
    [ReqToPay_Id] BIGINT        NOT NULL,
    PRIMARY KEY NONCLUSTERED ([ReqToPay_Id] ASC))
    WITH (MEMORY_OPTIMIZED = ON);

