CREATE TYPE [Base].[tv_ItmImgData_XML] AS TABLE (
    [Img]                  VARCHAR (MAX) NULL,
    [FrntImgQltyIndctnInd] VARCHAR (MAX) NULL,
    [BckImgQltyIndctnInd]  VARCHAR (MAX) NULL,
    [DbtItem_Id]           BIGINT        NOT NULL,
    PRIMARY KEY NONCLUSTERED ([DbtItem_Id] ASC))
    WITH (MEMORY_OPTIMIZED = ON);

