﻿CREATE TYPE [Base].[tv_Credit_New] AS TABLE (
    [XsdParseId]              INT             NULL,
    [ItemId]                  BIGINT          NULL,
    [Reference]               VARCHAR (18)    NULL,
    [CreditId]                VARCHAR (35)    NULL,
    [TXId]                    BIGINT          NULL,
    [Revision]                INT             NULL,
    [ItemType]                TINYINT         NULL,
    [Currency]                TINYINT         NULL,
    [Amount]                  NUMERIC (20, 2) NULL,
    [AccountNumber]           INT             NULL,
    [Sortcode]                INT             NULL,
    [TranCode]                CHAR (2)        NULL,
    [RicherDataRef]           VARCHAR (256)   NULL,
    [OnUs]                    BIT             NULL,
    [RepairedSortcode]        BIT             NULL,
    [RepairedAccount]         BIT             NULL,
    [RepairedAmount]          BIT             NULL,
    [RepairedSerial]          BIT             NULL,
    [RepairedReference]       BIT             NULL,
    [DefaultedSortcode]       BIT             NULL,
    [DefaultedAccount]        BIT             NULL,
    [DefaultedReference]      BIT             NULL,
    [Image]                   VARCHAR (MAX)   NULL,
    [ImageHash]               VARCHAR (128)   NULL,
    [CaptureId]               VARCHAR (70)    NULL,
    [CaptureDeviceID]         VARCHAR (70)    NULL,
    [CaptureLocation]         VARCHAR (70)    NULL,
    [CaptureDateTime]         DATETIME2 (5)   NULL,
    [FrontImageQuality]       BIT             NULL,
    [RearImageQuality]        BIT             NULL,
    [ChequeAtRisk]            BIT             NULL,
    [BeneficiaryName]         VARCHAR (50)    NULL,
    [FraudVirtualCredit]      BIT             NULL,
    [ReferenceData]           VARCHAR (20)    NULL,
    [CashAmount]              NUMERIC (20, 2) NULL,
    [CashCurrency]            TINYINT         NULL,
    [FundedAmount]            NUMERIC (20, 2) NULL,
    [FundedCurrency]          TINYINT         NULL,
    [NonFundedAmount]         NUMERIC (20, 2) NULL,
    [NonFundedCurrency]       TINYINT         NULL,
    [NumberOfItems]           INT             NULL,
    [SwitchedSortcode]        INT             NULL,
    [SwitchedAccountNumber]   INT             NULL,
    [XMLId]                   INT             NULL,
    [EndPointId]              VARCHAR (6)     NULL,
    [CollectingParticipantId] VARCHAR (6)     NOT NULL,
    [TransactionSetId]        VARCHAR (22)    NULL,
    [Version]                 TINYINT         NULL,
    [TSetIDWithVersion]       VARCHAR (24)    NULL,
    [CaptureDate]             DATETIME2 (7)   NULL,
    [Source]                  SMALLINT        NULL,
    [APGDIN]                  VARCHAR (15)    NULL,
    [APGNoPayReason]          VARCHAR (30)    NULL,
    [OnBank]                  TINYINT         NULL,
    [JGAccount]               VARCHAR (11)    NULL,
    [IsAmountCorrected]       BIT             NULL,
    [IsAnCorrected]           BIT             NULL,
    [IsSortCodeCorrected]     BIT             NULL,
    [IsSerialCorrected]       BIT             NULL,
    [DeletedItem]             BIT             NULL,
    [ItemTypeXML]             VARCHAR (4)     NULL,
    [CurrencyXML]             VARCHAR (4)     NULL,
    [CashCurrencyXML]         VARCHAR (4)     NULL,
    [FundedCurrencyXML]       VARCHAR (4)     NULL,
    [NonFundedCurrencyXML]    VARCHAR (4)     NULL,
    [RowNumber]               BIGINT          IDENTITY (1, 1) NOT NULL,
    INDEX [IX_tv_Credit_XsdParseId] ([XsdParseId]),
    INDEX [IX_tv_Credit_NonFundedCurrencyXML] ([NonFundedCurrencyXML]),
    INDEX [IX_tv_Credit_New] ([ItemId]),
    INDEX [IX_tv_Credit_FundedCurrencyXML] ([FundedCurrencyXML]),
    INDEX [IX_tv_Credit_CurrencyXML] ([CurrencyXML]),
    INDEX [IX_tv_Credit_CashCurrencyXML] ([CashCurrencyXML]))
    WITH (MEMORY_OPTIMIZED = ON);
GO