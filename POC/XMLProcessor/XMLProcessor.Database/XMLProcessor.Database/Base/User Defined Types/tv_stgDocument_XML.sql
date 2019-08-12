CREATE TYPE [Base].[tv_stgDocument_XML] AS TABLE (
    [MsgId]      VARCHAR (50)  NULL,
    [CreDtTm]    DATETIME2 (7) NULL,
    [NbOfTxs]    SMALLINT      NULL,
    [RcvrId]     VARCHAR (6)   NULL,
    [TstInd]     BIT           NULL,
    [Sgntr]      VARCHAR (MAX) NULL,
    [DocumentId] BIGINT        NOT NULL,
    PRIMARY KEY NONCLUSTERED ([DocumentId] ASC))
    WITH (MEMORY_OPTIMIZED = ON);

