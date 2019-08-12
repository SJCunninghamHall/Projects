CREATE TYPE [Base].[tv_CrdItm_XML] AS TABLE (
    [CreditItemId]  VARCHAR (35) NULL,
    [CreditItemTp]  VARCHAR (4)  NULL,
    [CreditItem_Id] BIGINT       NULL,
    [BkCd]          INT          NULL,
    [AcctNb]        INT          NULL,
    [RefNo]         VARCHAR (18) NULL,
    [TxSet_Id]      INT          NOT NULL,
    PRIMARY KEY NONCLUSTERED ([TxSet_Id] ASC))
    WITH (MEMORY_OPTIMIZED = ON);

