CREATE TYPE [Base].[tv_Core_Native] AS TABLE 
(
    [BusinessDate]            VARCHAR (10) NULL,
    [ExtractId]               VARCHAR (26) NULL,
    [ProcessingParticipantId] VARCHAR (6)  NULL,
    [ExtMessageType]          VARCHAR (6)  NULL,
    [IntMessageType]          VARCHAR (6)  NULL,
    [MessageSource]           VARCHAR (5)  NULL,
    [MessageDestination]      VARCHAR (5)  NULL,
    [RecordCount]             INT          NULL,
    [ICN_Id]                  BIGINT       NOT NULL,
    PRIMARY KEY NONCLUSTERED ([ICN_Id] ASC))
    WITH (MEMORY_OPTIMIZED = ON);
		/*
	Msg 12317, Level 16, State 78, Line 11
Clustered indexes, which are the default for primary keys, are not supported with memory optimized tables. Specify a NONCLUSTERED index instead.
	*/
GO