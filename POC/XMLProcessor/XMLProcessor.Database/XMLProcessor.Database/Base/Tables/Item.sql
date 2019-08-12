﻿CREATE TABLE [Base].[Item] (
    [ItemId]               BIGINT          NOT NULL,
    [APGDIN]               VARCHAR (15)    NULL,
    [APGBusinessDate]      DATETIME2 (2)   NULL,
    [Gender]               VARCHAR (3)     NULL,
    [TransactionNumber]    BIGINT          NULL,
    [JGAccount]            VARCHAR (11)    NULL,
    [IsElectronic]         BIT             NULL,
    [IsOnUs]               BIT             NULL,
    [IsDeleted]            BIT             NULL,
    [IsCorrected]          BIT             NULL,
    [IsAmountCorrected]    BIT             NULL,
    [OriginalAmount]       DECIMAL (11, 2) NULL,
    [IsTCCorrected]        BIT             NULL,
    [IsANCorrected]        BIT             NULL,
    [IsSortCodeCorrected]  BIT             NULL,
    [IsSerialCorrected]    BIT             NULL,
    [IsReject]             BIT             NULL,
    [RejectReason]         SMALLINT        NULL,
    [SpSelector]           VARCHAR (4)     NULL,
    [Currency]             TINYINT         NULL,
    [AdjustmentReason]     TINYINT         NULL,
    [Comments]             VARCHAR (60)    NULL,
    [UserId]               VARCHAR (64)    NULL,
    [Process]              VARCHAR (25)    NULL,
    [FCMIdentifier]        VARCHAR (25)    NULL,
    [Revision]             INT             NULL,
    [OriginalISN]          VARCHAR (12)    NULL,
    [AeStatus]             VARCHAR (23)    NULL,
    [IcStatus]             VARCHAR (23)    NULL,
    [IqvStatus]            VARCHAR (14)    NULL,
    [CarSetId]             SMALLINT        NULL,
    [CarResults]           VARCHAR (11)    NULL,
    [IaStatus]             VARCHAR (11)    NULL,
    [IaResult]             VARCHAR (11)    NULL,
    [PNVReviewStatus]      TINYINT         NULL,
    [DuplicateStatus]      TINYINT         NULL,
    [ReturnReason]         TINYINT         NULL,
    [ChequeIssuedDate]     DATETIME2 (2)   NULL,
    [ImageHash]            CHAR (64)       NULL,
    [VerificationStatus]   VARCHAR (50)    NULL,
    [DebitReference]       VARCHAR (18)    NULL,
    [CoServiceSortcode]    INT             NULL,
    [ICSAmount]            DECIMAL (11, 2) NULL,
    [ISDBranchSelector]    VARCHAR (4)     NULL,
    [ISDBranchItemDesc]    VARCHAR (11)    NULL,
    [ISDTellerId]          VARCHAR (10)    NULL,
    [ISDProdType]          VARCHAR (10)    NULL,
    [ISDTransactionType]   VARCHAR (20)    NULL,
    [ISDRecieptNumber]     VARCHAR (20)    NULL,
    [ISDCarSetId]          SMALLINT        NULL,
    [ISDSentToCar]         BIT             NULL,
    [ISDPassedCar]         BIT             NULL,
    [ISDCarConfidence]     SMALLINT        NULL,
    [ISDSentToICR]         BIT             NULL,
    [ISDAutoCorrected]     BIT             NULL,
    [ISDOperatorCorrected] BIT             NULL,
    [ISDIaStatus]          VARCHAR (11)    NULL,
    [ISDIaResult]          VARCHAR (30)    NULL,
    [cf_AccountType]       VARCHAR (12)    NULL,
    [cf_ANDefaulted]       CHAR (1)        NULL,
    [cf_Batch_SourceID]    VARCHAR (15)    NULL,
    [cf_BrandID]           VARCHAR (15)    NULL,
    [cf_CustomerName1]     VARCHAR (99)    NULL,
    [cf_CustomerName2]     VARCHAR (99)    NULL,
    [cf_CustomerName3]     VARCHAR (99)    NULL,
    [cf_CustomerName4]     VARCHAR (99)    NULL,
    [cf_CustomerName5]     VARCHAR (99)    NULL,
    [cf_Date]              CHAR (10)       NULL,
    [cf_DeferredPosting]   VARCHAR (3)     NULL,
    [cf_DeviceID]          VARCHAR (30)    NULL,
    [cf_fCashItem]         CHAR (1)        NULL,
    [cf_ICSTransactionID]  CHAR (25)       NULL,
    [cf_ImageDateTime]     CHAR (28)       NULL,
    [cf_IQVRejectReason]   VARCHAR (30)    NULL,
    [cf_LAR]               VARCHAR (11)    NULL,
    [cf_LocationID]        VARCHAR (20)    NULL,
    [cf_LockRollID]        VARCHAR (18)    NULL,
    [cf_MarketSector]      VARCHAR (99)    NULL,
    [cf_MSOUGroupID]       VARCHAR (99)    NULL,
    [cf_MSOUGroupName]     VARCHAR (99)    NULL,
    [cf_NoPaySuspectRsn]   VARCHAR (30)    NULL,
    [cf_NPASortCode]       CHAR (6)        NULL,
    [cf_ParticipantID]     CHAR (6)        NULL,
    [cf_PersonID]          VARCHAR (20)    NULL,
    [cf_PlaceHolder]       VARCHAR (99)    NULL,
    [cf_SCDefaulted]       CHAR (1)        NULL,
    [cf_SERDefaulted]      CHAR (1)        NULL,
    [cf_SourceID]          CHAR (4)        NULL,
    [cf_SuspectReason]     VARCHAR (2)     NULL,
    [cf_SwitchedOut]       CHAR (1)        NULL,
    [cf_AgencySC]          INT             NULL,
    [cf_DoDateCheck]       TINYINT         NULL,
    [cf_DoCARvLAR]         TINYINT         NULL,
    [cf_DoCARvData]        TINYINT         NULL,
    [cf_CPMError]          TINYINT         NULL,
    [cf_OnBank]            TINYINT         NULL,
    [cf_OpenCredit]        TINYINT         NULL,
    [cf_Posted]            TINYINT         NULL,
    [cf_SuspectFlag]       TINYINT         NULL,
    [cf_HVStatus]          TINYINT         NULL,
    [cf_ChnlInsertReason]  VARCHAR (20)    NULL,
    [CoreId]               BIGINT          NULL,
    CONSTRAINT [NCH_Item_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([ItemId]) WITH (BUCKET_COUNT = 8388608),
    INDEX [NCI_FCMId] NONCLUSTERED ([FCMIdentifier], [Revision]),
    INDEX [NCI_APGDIN] NONCLUSTERED ([APGDIN])
)
WITH (MEMORY_OPTIMIZED = ON);

