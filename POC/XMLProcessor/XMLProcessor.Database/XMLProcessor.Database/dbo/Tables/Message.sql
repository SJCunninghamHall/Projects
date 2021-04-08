CREATE TABLE [dbo].[Message] (
    [ID]           INT            IDENTITY (1, 1) NOT NULL,
    [XMLMessageIn] XML            NOT NULL,
    [Filename]     NVARCHAR (255) NULL
);
GO