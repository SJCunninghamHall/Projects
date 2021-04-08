CREATE TYPE [Base].[Image_Native] AS TABLE (
    [Image]                VARCHAR (35)  NULL,
    [FrontImageQuality]    BIT           NULL,
    [RearImageQuality]     BIT           NULL,
    [ItemId]               BIGINT        NULL,
    [ImageHash]            VARCHAR (128) NULL,
    [CaptureId]            VARCHAR (70)  NULL,
    [CaptureDeviceID]      VARCHAR (70)  NULL,
    [CaptureLocation]      VARCHAR (70)  NULL,
    [CaptureDateTime ]     DATETIME2 (7) NULL,
    [UniqueItemIdentifier] VARCHAR (25)  NULL,
    [Image_id]             INT           IDENTITY (1, 1) NOT NULL,
    INDEX [IX_Image_id] ([Image_id]))
    WITH (MEMORY_OPTIMIZED = ON);

