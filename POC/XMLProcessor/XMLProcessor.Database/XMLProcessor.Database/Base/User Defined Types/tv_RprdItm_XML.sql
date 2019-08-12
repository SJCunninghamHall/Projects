CREATE TYPE [Base].[tv_RprdItm_XML] AS TABLE (
    [BkCdRprdInd]   VARCHAR (MAX) NULL,
    [AcctNbRprdInd] VARCHAR (MAX) NULL,
    [AmtRprdInd]    VARCHAR (MAX) NULL,
    [SrlNbRprdInd]  VARCHAR (MAX) NULL,
    [RefNbRprdInd]  VARCHAR (MAX) NULL,
    [CrdtItm_Id]    BIGINT        NULL,
    [DbtItm_Id]     BIGINT        NULL,
    INDEX [IX_DbtItem_Id] NONCLUSTERED HASH ([CrdtItm_Id]) WITH (BUCKET_COUNT = 8))
    WITH (MEMORY_OPTIMIZED = ON);

