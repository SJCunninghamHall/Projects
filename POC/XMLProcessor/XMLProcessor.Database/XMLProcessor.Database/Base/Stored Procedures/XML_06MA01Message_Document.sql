
CREATE PROCEDURE [Base].[XML_06MA01Message_Document]
       @tv_document_XML Base.[tv_GrpHdr_XML]    READONLY ,
       @BusinessDate varchar(10),
       @ISODocumentId bigint,
       @XMLMessageID bigint,
       @DocumentType varchar(5)

WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER  
AS BEGIN ATOMIC WITH  (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE=N'us_english')  
       -- PART 1
       DECLARE @tv_document Base.[tv_stgDocument_XML];

       INSERT INTO @tv_document
       (
                     [MsgId],
                     [CreDtTm],
                     [NbOfTxs],
                     [RcvrId],
                     [TstInd],
                     [Sgntr],
                     [DocumentId]
       )
       SELECT        
                     [MsgId],
                     [CreDtTm],
                     [NbOfTxs],
                     [RcvrId],
                     [TstInd],
                     [Sgntr],
                     @ISODocumentId 
       FROM 
              @tv_document_XML docXML;
      -- PART 2
           INSERT INTO Base.[Document]
                                  (
                                              [DocumentId] ,
                                              [ParticipantId] ,
                                              [SubmissionDate] ,
                                              [Mechanism] ,
                                              [SubmissionCounter] ,
                                              [CreatedDate] ,
                                               [NumberOfEntries] ,
                                              [ReceiverParticipantId] ,
                                              [SenderParticipantId] ,
                                              [ChargedParticipantId] ,
                                              [DocumentType] ,
                                              [Signature] ,
                                              [XMLMessageId] ,
                                              [TestFlag],
                                              [DocumentMessageID]
                                          )
                        SELECT doc.[DocumentId] DocumentId ,
                               SUBSTRING(doc.MsgId,1,6) AS ParticipantId ,
                              /*(Select DateAdd(DAY,(cast(SUBSTRING(doc.MsgId, 9, 3) as int)),DateFromParts(cast('20'+ SUBSTRING(doc.MsgId, 7, 2) as int)-1,12,31)))*/
                                SUBSTRING(doc.MsgId, 7, 4),
                                SUBSTRING(doc.MsgId, 12, 1) AS SubmissionMechanism ,
                                SUBSTRING(doc.MsgId, 14, 10) AS SubmissionCounter , --       ,CAST(SUBSTRING(doc.MsgId, 14, 10) AS BIGINT)
								   doc.[CreDtTm] ,--CreatedDatetime
								   doc.[NbOfTxs] ,--CAST(doc.NbOfTxs AS BIGINT)--NoOftransactions
								   doc.[RcvrId] , --Recvr.Id , Lookup value not being used 
								   NULL,--SndrId,
								   NULL,
								   6,-- @DocumentType, -- Todo – lookup tables
								   doc.[Sgntr] ,--Signature
								   @XMLMessageID ,
								   doc.TstInd,
								   doc.MsgId
                         From  @tv_document AS doc
                                  
                                  
END