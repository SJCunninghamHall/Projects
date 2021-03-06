﻿CREATE TYPE [Base].[tv_Debit_Native] AS TABLE (
    [Debit_ID]                INT             IDENTITY (1, 1) NOT NULL,
    [TxSetId]                 INT             NULL,
    [TxSetVrsn]               VARCHAR (1)     NULL,
    [DbtItmId]                INT             NULL,
    [DbtItmTp]                VARCHAR (35)    NULL,
    [DbtItmTxCd]              VARCHAR (5)     NULL,
    [RpresntdItmInd]          BIT             NULL,
    [Amt]                     DECIMAL (20, 2) NULL,
    [AmtCcy]                  NUMERIC (20, 2) NULL,
    [BkCd]                    VARCHAR (35)    NULL,
    [AcctNb]                  VARCHAR (35)    NULL,
    [SrlNb]                   VARCHAR (35)    NULL,
    [HghValItm]               BIT             NULL,
    [DayOneRspnWndwStartDtTm] DATETIME2 (7)   NULL,
    [DayOneRspnWndwEndDtTm]   DATETIME2 (7)   NULL,
    [DayTwoRspnWndwStartDtTm] DATETIME2 (7)   NULL,
    [DayTwoRspnWndwEndDtTm]   DATETIME2 (7)   NULL,
    [XtrnlDataRef]            VARCHAR (256)   NULL,
    [Img]                     VARCHAR (MAX)   NULL,
    [FrntImgQltyIndctnInd]    BIT             NULL,
    [BckImgQltyIndctnInd]     BIT             NULL,
    [ChqAtRskInd]             BIT             NULL,
    [DtOfFrstChq]             DATETIME2 (7)   NULL,
    [DtOfLstChq]              DATETIME2 (7)   NULL,
    [NbOfCtrPtys]             VARCHAR (15)    NULL,
    [NbOfVldChqs]             VARCHAR (15)    NULL,
    [NbOfFrdChqs]             VARCHAR (15)    NULL,
    [HghstAmt]                DECIMAL (20, 2) NULL,
    [HghstAmtCcy]             NUMERIC (20, 2) NULL,
    [RskInd]                  VARCHAR (15)    NULL,
    [BkCdRprdInd]             BIT             NULL,
    [AcctNbRprdInd]           BIT             NULL,
    [AmtRprdInd]              BIT             NULL,
    [SrlNbRprdInd]            BIT             NULL,
    [RefNbRprdInd]            BIT             NULL,
    [BkCdDfltdInd]            BIT             NULL,
    [AcctNbDfltdInd]          BIT             NULL,
    [SrlNbDfltdInd]           BIT             NULL,
    [DplctItmId]              VARCHAR (35)    NULL,
    [DbtDplctSts]             VARCHAR (5)     NULL,
    [DtFirstPresntd]          DATETIME2 (7)   NULL,
    [MmbId]                   VARCHAR (35)    NULL,
    [OrgnlCaptrDt]            DATETIME2 (7)   NULL,
    [OrgnlSrc]                DATETIME2 (7)   NULL,
    [StopdDt]                 DATETIME2 (7)   NULL,
    [StopdSts]                VARCHAR (5)     NULL,
    [StopedAmt]               DECIMAL (20, 2) NULL,
    [StopedAmtCcy]            DECIMAL (20, 2) NULL,
    [BnfcryNm]                VARCHAR (70)    NULL,
    [StopItmStartRg]          VARCHAR (1)     NULL,
    [StopItmEndRg]            VARCHAR (1)     NULL,
    [DbtItm_Id]               INT             NULL,
    [DbtStopdItm_Id]          INT             NULL,
    [CrdtItm_Id]              INT             NULL,
    [Amt_text]                DECIMAL (20, 2) NULL,
    [Ccy]                     VARCHAR (1)     NULL,
    [DbtItmFrdData_Id]        INT             NULL,
    [HghstAmt_text]           DECIMAL (20, 2) NULL,
    [TxSet_Id]                INT             NULL,
    INDEX [IX_Debit_ID] ([Debit_ID]))
    WITH (MEMORY_OPTIMIZED = ON);

