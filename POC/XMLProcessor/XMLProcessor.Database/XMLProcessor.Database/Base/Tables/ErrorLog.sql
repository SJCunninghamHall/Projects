CREATE TABLE [Base].[ErrorLog] (
    [OccuredDateTime] DATETIME2 (3)  NOT NULL,
    [ErrorLogID]      TINYINT        NOT NULL,
    [UserName]        NVARCHAR (128) NULL,
    [ErrorNumber]     INT            NULL,
    [ErrorSeverity]   INT            NULL,
    [ErrorState]      INT            NULL,
    [ErrorProcedure]  NVARCHAR (128) NULL,
    [ErrorLine]       INT            NULL,
    [ErrorMessage]    VARCHAR (4000) NULL,
    CONSTRAINT [ErrorLog_primaryKey] PRIMARY KEY NONCLUSTERED HASH ([OccuredDateTime], [ErrorLogID]) WITH (BUCKET_COUNT = 65536)
)
WITH (MEMORY_OPTIMIZED = ON);

