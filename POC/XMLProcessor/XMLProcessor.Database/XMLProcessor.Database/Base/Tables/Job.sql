CREATE TABLE [Base].[Job] (
    [JobId]                  BIGINT        NOT NULL,
    [CoreId]                 BIGINT        NOT NULL,
    [BusinessDate]           DATE          NOT NULL,
    [InstallationId]         VARCHAR (15)  NOT NULL,
    [CaptureSystemId]        CHAR (1)      NOT NULL,
    [APGStartTime]           DATETIME2 (2) NOT NULL,
    [APGEndTime]             DATETIME2 (2) NOT NULL,
    [WorkTypeNbr]            TINYINT       NOT NULL,
    [SortFamily]             SMALLINT      NOT NULL,
    [SourceType]             VARCHAR (46)  NOT NULL,
    [SourceName]             VARCHAR (50)  NOT NULL,
    [SourceID]               TINYINT       NOT NULL,
    [FinancialInstitutionId] VARCHAR (9)   NOT NULL,
    [CollectionStartTime]    DATETIME2 (2) NOT NULL,
    [CollectionEndTime]      DATETIME2 (2) NOT NULL,
    CONSTRAINT [Job_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([JobId]) WITH (BUCKET_COUNT = 8388608)
)
WITH (MEMORY_OPTIMIZED = ON);

