﻿CREATE TYPE [Base].[ICNItemUpdateHolder] AS TABLE (
    [InternalId]               BIGINT          NOT NULL,
    [CrDbItemId]               BIGINT          NOT NULL,
    [CrDbTransactionItemId]    VARCHAR (25)    NOT NULL,
    [ProcessId]                VARCHAR (26)    NULL,
    [OperatorId]               VARCHAR (20)    NULL,
    [UpdateDateTime]           DATETIME2 (2)   NULL,
    [Revision]                 INT             NULL,
    [PayingParticipantId]      CHAR (6)        NULL,
    [BeneficiaryParticipantId] CHAR (6)        NULL,
    [Gender]                   CHAR (3)        NULL,
    [AdjustmentReason]         TINYINT         NULL,
    [NoPayReason]              VARCHAR (30)    NULL,
    [ReasonCode]               SMALLINT        NULL,
    [Narrative]                VARCHAR (255)   NULL,
    [AlternateSortcode]        INT             NULL,
    [AlternateAccount]         INT             NULL,
    [CoreID]                   BIGINT          NOT NULL,
    [SerialNumber]             INT             NULL,
    [Reference]                VARCHAR (18)    NULL,
    [AccountNumber]            INT             NULL,
    [Sortcode]                 INT             NULL,
    [Amount]                   NUMERIC (20, 2) NULL,
    [OriginalAmount]           NUMERIC (20, 2) NULL,
    [ICSAmount]                NUMERIC (20, 2) NULL,
    [Currency]                 TINYINT         NULL,
    [TranCode]                 CHAR (2)        NULL,
    [DefaultedSortcode]        BIT             NULL,
    [DefaultedAccount]         BIT             NULL,
    [ResponseDate]             DATETIME2 (2)   NULL,
    [ResponseTime]             DATETIME2 (2)   NULL,
    [Image]                    VARCHAR (MAX)   NULL,
    [PayDecision]              BIT             NULL,
    [PayReason]                CHAR (4)        NULL,
    [SettlementPeriodID]       BIGINT          NULL,
    [SwSortcode]               INT             NULL,
    [SwAccountNumber]          INT             NULL,
    INDEX [IX_CoreItemUpdateItemID] ([InternalId]))
    WITH (MEMORY_OPTIMIZED = ON);
