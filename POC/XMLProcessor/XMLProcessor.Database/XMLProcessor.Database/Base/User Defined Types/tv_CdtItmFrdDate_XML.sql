CREATE TYPE [Base].[tv_CdtItmFrdDate_XML] AS TABLE (
    [BnfcryNm]   VARCHAR (MAX) NULL,
    [VrtlCdtInd] VARCHAR (MAX) NULL,
    [RefData]    VARCHAR (MAX) NULL,
    [CrdtItm_Id] INT           NOT NULL,
    PRIMARY KEY NONCLUSTERED ([CrdtItm_Id] ASC))
    WITH (MEMORY_OPTIMIZED = ON);

