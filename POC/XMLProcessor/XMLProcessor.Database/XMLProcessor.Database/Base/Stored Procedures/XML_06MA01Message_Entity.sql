
CREATE PROCEDURE [Base].[XML_06MA01Message_Entity]
       @tv_Entity_XML Base.tv_Entity_XML        READONLY ,
       @CoreId BigInt

WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER  
AS BEGIN ATOMIC WITH  (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE=N'us_english')  
       DECLARE @tv_Entity_STG Base.[tv_Entity_STG3];
       
       --Part 1
       INSERT INTO @tv_Entity_STG
       (
              [EntityId], 
              [EntityType],  
              [StateRevision], 
              [EntityState], 
              [SourceDateTime], 
              [Entities_Id]  
       )
       SELECT 
              @CoreId AS [EntityId], 
              entity.[EntityType],  
              entity.[StateRevision], 
              entity.[EntityState], 
              entity.[SourceDateTime], 
              entity.[Entities_Id] 
       FROM 
              @tv_Entity_XML entity;     

       --Part 2
       INSERT INTO [Base].[Entity]
       (
              [EntityId],
              [CoreId],
              [EntityType],
              [EntityIdentifier],
              [Revision],
              [EntityState],
              [SourceDateTime]
       )
       SELECT 
              stg.Alpa_ID as [EntityId],
              @CoreId,
              stg.[EntityType],
              stg.[Entities_Id], 
              stg.[StateRevision], 
              stg.[EntityState],
              stg.[SourceDateTime]
       FROM 
              @tv_Entity_STG stg
              
END