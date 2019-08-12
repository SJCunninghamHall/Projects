CREATE TYPE [Base].[tv_GroupHeader_XML_native] AS TABLE (
    [MsgId]         VARCHAR (50)  NULL,
    [CreDtTm]       DATETIME2 (7) NULL,
    [NbOfTxs]       SMALLINT      NULL,
    [RcvrId]        VARCHAR (6)   NULL,
    [TstInd]        BIT           NULL,
    [Sgntr]         VARCHAR (MAX) NULL,
    [GroupHeaderId] BIGINT        NOT NULL,
    PRIMARY KEY NONCLUSTERED ([GroupHeaderId] ASC))
    WITH (MEMORY_OPTIMIZED = ON);

