CREATE TABLE [dbo].[t_test] (
    [BusinessDate] VARCHAR (10) NULL,
    [RecordCount]  INT          NULL,
    [Id]           BIGINT       NOT NULL,
    [name1]        VARCHAR (10) NULL,
    CONSTRAINT [PK_Memory] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)
WITH (DURABILITY = SCHEMA_ONLY, MEMORY_OPTIMIZED = ON);

