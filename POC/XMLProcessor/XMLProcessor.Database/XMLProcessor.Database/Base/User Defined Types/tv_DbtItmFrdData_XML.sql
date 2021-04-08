CREATE TYPE [Base].[tv_DbtItmFrdData_XML] AS TABLE (
    [BkCdDfltdInd]   VARCHAR (MAX) NULL,
    [AcctNbDfltdInd] VARCHAR (MAX) NULL,
    [RefNbDfltdInd]  VARCHAR (MAX) NULL,
    [CrdtItm_Id]     VARCHAR (MAX) NULL,
    [SrlNbDfltdInd]  VARCHAR (MAX) NULL,
    [DbtItm_Id]      BIGINT        NOT NULL,
    PRIMARY KEY NONCLUSTERED ([DbtItm_Id] ASC))
    WITH (MEMORY_OPTIMIZED = ON);

