
CREATE PROCEDURE [Base].[XML_06MA01Message_Txset]
       @tv_TxSet_XML Base.[tv_TxSet_XML] READONLY ,
       @DocumentId bigint,
       @CoreId bigint

WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER  
AS BEGIN ATOMIC WITH  (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE=N'us_english')  
       -- PART 1
       DECLARE @tv_STGTxSet Base.[tv_STGTxSet];

       INSERT INTO @tv_STGTxSet
       (
              [TxSetId],
              [TxSetVrsn],
              [ColltngPtcptId],
              [CaptrdDtTm],
              [TxSetSubDtTm],
              [Src],
              [ColltngBrnchLctn],
              [ColltngLctn],
              [ChanlRskTp],
              [ChanlDesc],
              [ColltnPt],
              [ColltngBrnchRef],
              [NoOfItems],
              [EndPtId],
              [TxSet_Id],
              [ReqToPay_Id]
       )
       SELECT        
              [TxSetId] ,
              [TxSetVrsn] ,
              [ColltngPtcptId] ,
              [CaptrdDtTm] ,
              [TxSetSubDtTm] ,
              [Src] ,
              [ColltngBrnchLctn] ,
              [ColltngLctn] ,
              [ChanlRskTp] ,
              [ChanlDesc] ,
              [ColltnPt] ,
              [ColltngBrnchRef] ,
              [NbOfItms] ,
              [EndPtId] ,
              [TxSet_Id] ,
              [ReqToPay_Id] 
       FROM 
              @tv_TxSet_XML;


      -- PART 2

       INSERT INTO  [Base].[TXSet]
                              ([DocumentId]
                              ,[InternalTxId]
                              ,[CollectingPId]
                              ,[TXIdDate]
                              ,[Source]
                              ,[Sequence]
                              ,[Version]
                              ,[CollectingParticipantId]
                              ,[AltSource]
                              ,[CaptureDate]
                              ,[TSetSubmissionDateTime]
                              ,[NumberOfItems]
                              ,[EndPointId]
                              ,[CollectingBranchLocation]
                              ,[CollectingLocation]
                              ,[ChannelRiskType]
                              ,[ChannelDescription]
                              ,[CollectionPoint]
                              ,[CollectionBranchRef]
                              ,[FraudCheckOnly]
                              ,[TransactionSetIdWithVersion]
                              ,[TransactionSetId])
       SELECT 
                                  @DocumentId ,
                                   @CoreId,  --Todo
                                  SUBSTRING(TxSetId,0, 6),
                                 /* (Select DateAdd(DAY,(cast(SUBSTRING(TxSetId, 9, 3) as int)),DateFromParts(cast('20'+ SUBSTRING(TxSetId, 7, 2) as int)-1,12,31))),*/
                                  SUBSTRING(TxSetId, 7, 4),
                                  SUBSTRING(TxSetId, 12, 4),
                                  SUBSTRING(TxSetId, 16, 7),
                                  [TxSetVrsn] ,
                                  [ColltngPtcptId],
                                  [Src] AS AltSource ,
                                   null ,-- TODO 
                                  [TxSetSubDtTm], -- [TSetSubmissionDateTime] , 
                                  0,--[NbOfItms],--TODO
                                 [EndPtId] ,
                                 [ColltngBrnchLctn]  ,
                                 [ColltngLctn]  as CollectingLocation ,
                                 [ChanlRskTp] as ChannelRiskType ,
                                [ChanlDesc] as ChannelDescription ,
                                [ColltnPt]  as CollectionPoint ,
                                [ColltngBrnchRef]  as CollectionBranchRef ,
                                null as FraudCheckOnly,--TODO
                               ([TxSet_Id]  + isnull(SUBSTRING((CAST([TxSetVrsn] AS varchar(4))), len([TxSetVrsn])-1,2),'00')) as [TransactionSetIdWithVersion],
                                [TxSet_Id] 
       FROM 
              @tv_STGTxSet
              
END