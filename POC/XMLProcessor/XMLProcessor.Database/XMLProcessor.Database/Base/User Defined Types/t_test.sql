CREATE TYPE [Base].[t_test] AS TABLE (
    [BusinessDate] VARCHAR (10) NULL,
    [Recordnumber] INT          IDENTITY (1, 1) NOT NULL,
    [Id]           BIGINT       NOT NULL,
    [name1]        VARCHAR (6)  NULL,
    INDEX [PK_Memory1] ([Id]))
    WITH (MEMORY_OPTIMIZED = ON);

