CREATE TYPE [Base].[tv_CreditItem_XML_native] AS TABLE (
    [CdtItmId]      VARCHAR (35)    NULL,
    [CdtItmTp]      VARCHAR (4)     NULL,
    [Amt]           DECIMAL (18, 5) NULL,
    [BkCd]          VARCHAR (35)    NULL,
    [AcctNb]        VARCHAR (35)    NULL,
    [RefNb]         VARCHAR (35)    NULL,
    [CreditItem_ID] INT             NOT NULL,
    PRIMARY KEY NONCLUSTERED ([CreditItem_ID] ASC))
    WITH (MEMORY_OPTIMIZED = ON);

