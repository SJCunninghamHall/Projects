CREATE TYPE [Base].[tv_DbtItm_XML] AS TABLE (
    [DbtItmId]                VARCHAR (25)  NULL,
    [DbtItmTp]                CHAR (4)      NULL,
    [RpresntdItmInd]          BIT           NULL,
    [DbtItm_Id]               INT           NOT NULL,
    [BkCd]                    VARCHAR (35)  NULL,
    [AcctNb]                  VARCHAR (35)  NULL,
    [SrlNb]                   VARCHAR (35)  NULL,
    [HghValItm]               BIT           NULL,
    [DayOneRspnWndwStartDtTm] DATETIME2 (7) NULL,
    [DayOneRspnWndwEndDtTm]   DATETIME2 (7) NULL,
    [DayTwoRspnWndwStartDtTm] DATETIME2 (7) NULL,
    [DayTwoRspnWndwEndDtTm]   DATETIME2 (7) NULL,
    [XtrnlDataRef]            VARCHAR (256) NULL,
    [TxSet_Id]                INT           NULL,
    PRIMARY KEY NONCLUSTERED ([DbtItm_Id] ASC))
    WITH (MEMORY_OPTIMIZED = ON);

