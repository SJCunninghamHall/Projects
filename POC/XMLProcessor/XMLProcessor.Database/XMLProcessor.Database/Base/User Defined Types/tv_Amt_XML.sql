CREATE TYPE [Base].[tv_Amt_XML] AS TABLE (
    [Ccy]        VARCHAR (3)  NULL,
    [Amt_Text]   VARCHAR (30) NULL,
    [CrdtItm_Id] BIGINT       NULL,
    [DbtItm_Id]  BIGINT       NULL,
    INDEX [Ix_DbtItm_Id] ([DbtItm_Id]))
    WITH (MEMORY_OPTIMIZED = ON);

