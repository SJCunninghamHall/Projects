﻿CREATE TYPE [Base].[tv_Capture_History_Item] AS TABLE (
    [XMLId]               INT             NOT NULL,
    [ItemId]              BIGINT          NOT NULL,
    [CoreId]              BIGINT          NOT NULL,
    [FCMIdentifier]       VARCHAR (25)    NULL,
    [IsElectronic]        BIT             NULL,
    [cf_DeferredPosting]  VARCHAR (3)     NULL,
    [cf_NPASortCode]      CHAR (6)        NULL,
    [cf_ChnlInsertReason] VARCHAR (20)    NULL,
    [cf_NoPaySuspectRsn]  VARCHAR (30)    NULL,
    [cf_fCashItem]        CHAR (1)        NULL,
    [OriginalAmount]      DECIMAL (11, 2) NULL,
    [JGAccount]           VARCHAR (11)    NULL,
    [IsTCCorrected]       BIT             NULL,
    [IsANCorrected]       BIT             NULL,
    [IsSortCodeCorrected] BIT             NULL,
    [IsSerialCorrected]   BIT             NULL,
    [IsReject]            BIT             NULL,
    [AuditRevision]       INT             NULL,
    [DebitReference]      VARCHAR (18)    NULL,
    [AdjustmentReason]    TINYINT         NULL,
    [ICSAmount]           NUMERIC (20, 2) NULL,
    [cf_OnBank]           TINYINT         NULL,
    [IsAmountCorrected]   BIT             NULL,
    [cf_ImageDateTime]    CHAR (28)       NULL,
    INDEX [IX_tv_Capture_History_Item] ([ItemId]))
    WITH (MEMORY_OPTIMIZED = ON);

