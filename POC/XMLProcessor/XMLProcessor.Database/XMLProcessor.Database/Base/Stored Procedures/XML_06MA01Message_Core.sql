
CREATE PROCEDURE [Base].[XML_06MA01Message_Core]
       @tv_Core_XML Base.tv_Core_XML     READONLY ,
       @BusinessDate varchar(10),
       @CoreId bigint

WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER  
AS BEGIN ATOMIC WITH  (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE=N'us_english')  
       -- PART 1
       DECLARE @tv_Core Base.[tv_STGCore_XML];

       INSERT INTO @tv_Core
       (
              [CoreId],                                --[bigint] NOT NULL,
              [BusinessDate],                          --[varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
              [ExtractId]   ,                          --[varchar](26) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
              [ProcessingParticipantId], --[varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
              [ExtMessageType],                 --[varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
              [IntMessageType],                 --[varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
              [MessageSource],                  --[varchar](5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
              [MessageDestination],             --[varchar](5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
              [RecordCounts],                          --[int] NULL,
              [ICN_Id]                                 --[bigint] NOT NULL,
       )
       SELECT        
              @CoreId                                         AS [CoreId],
              @BusinessDate                     AS [BusinessDate],
              src.ExtractId                     AS [ExtractId],
              src.ProcessingParticipantId AS [ProcessingParticipantId] ,
              src.ExtMessageType                AS [ExtMessageType],
              src.IntMessageType                AS [IntMessageType], 
              src.MessageSource                 AS [MessageSource],         
              src.MessageDestination            AS [MessageDestination],  
              src.RecordCount                          AS [RecordCounts],    
              src.ICN_Id                               AS [ICN_Id] 
       FROM 
              @tv_Core_XML src;


      -- PART 2

       INSERT INTO [Base].[Core]
       (
              [CoreId],
              [ExtractId],
              [PostingExtractId],
              [ParticipantId],
              [MessageType],
              [IntMessageType],
              [Source],
              [Destination],
              [RecordCount],
              [XMLMessageId]
       )
       SELECT 
              core.[CoreId]                     AS [CoreId],
              core.ExtractId                    AS [ExtractId],
              NULL                              AS [PostingExtractId],
              core.[ProcessingParticipantId]    AS [ParticipantId],
              LkpDocType.MessageId              AS [MessageType],    
              core.IntMessageType               AS [IntMessageType],
              core.MessageSource                AS [Source],
              core.MessageDestination           AS [Destination],
              core.[RecordCounts]               AS [RecordCount],
              core.[CoreId]                     AS [XMLMessageId] --TODO Is this the correct number
       FROM 
              @tv_Core As core
              LEFT OUTER JOIN [Lookup].[MessageType] LkpDocType ON core.ExtMessageType = LkpDocType.MessageType;

END