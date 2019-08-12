﻿CREATE TABLE [Base].[Debit] (
    [ItemId]                    BIGINT          NOT NULL,
    [Revision]                  INT             NULL,
    [SerialNumber]              INT             NULL,
    [Sortcode]                  INT             NULL,
    [AccountNumber]             INT             NULL,
    [Amount]                    NUMERIC (20, 2) NULL,
    [Currency]                  TINYINT         NULL,
    [ReasonCode]                SMALLINT        NULL,
    [Narrative]                 VARCHAR (255)   NULL,
    [TranCode]                  CHAR (2)        NULL,
    [DefaultedSortcode]         BIT             NULL,
    [DefaultedAccount]          BIT             NULL,
    [DefaultedSerialNumber]     BIT             NULL,
    [AlternateSortCode]         INT             NULL,
    [AlternateAccount]          INT             NULL,
    [SwitchedSortCode]          INT             NULL,
    [SwitchedAccount]           INT             NULL,
    [InternalTxId]              BIGINT          NULL,
    [DebitId]                   VARCHAR (35)    NOT NULL,
    [ItemType]                  TINYINT         NULL,
    [RicherDataRef]             VARCHAR (256)   NULL,
    [Day1ResponseStartDateTime] DATETIME2 (3)   NULL,
    [Day1ResponseEndDateTime]   DATETIME2 (3)   NULL,
    [Day2ResponseStartDatetime] DATETIME2 (3)   NULL,
    [Day2ResponseEndDateTime]   DATETIME2 (3)   NULL,
    [PayReason]                 CHAR (4)        NULL,
    [FraudStatusCode]           CHAR (4)        NULL,
    [FraudReasonCode]           CHAR (4)        NULL,
    [SettlementPeriodId]        BIGINT          NULL,
    [OnUs]                      BIT             NULL,
    [Represent]                 BIT             NULL,
    [HighValue]                 BIT             NULL,
    [PayDecision]               BIT             NULL,
    [RepairedSortcode]          BIT             NULL,
    [RepairedAccount]           BIT             NULL,
    [RepairedAmount]            BIT             NULL,
    [RepairedSerial]            BIT             NULL,
    [RepairedReference]         BIT             NULL,
    [DocumentId]                BIGINT          NULL,
    [TSetID]                    VARCHAR (22)    NULL,
    [TSetIDWithVersion]         VARCHAR (24)    NULL,
    CONSTRAINT [Debits_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([ItemId]) WITH (BUCKET_COUNT = 16777216),
    CONSTRAINT [FK_Debit_Currency] FOREIGN KEY ([Currency]) REFERENCES [Lookup].[Currency] ([Id]),
    CONSTRAINT [FK_Debit_ItemType] FOREIGN KEY ([ItemType]) REFERENCES [Lookup].[ItemType] ([Id]),
    INDEX [NCI_ItemId] NONCLUSTERED ([ItemId]),
    INDEX [NCI_InternalTxId] NONCLUSTERED ([InternalTxId]),
    INDEX [NCI_DocumentId] NONCLUSTERED ([DocumentId]),
    INDEX [NCI_DebitId] NONCLUSTERED ([DebitId]),
    INDEX [NCI_Codeline] NONCLUSTERED ([Sortcode], [AccountNumber], [SerialNumber], [Amount], [ItemId])
)
WITH (MEMORY_OPTIMIZED = ON);

