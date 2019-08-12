
CREATE FUNCTION [Base].[cfn_XML_Get_WrapperXPath]
(
       @DocumentType VARCHAR(10)
)
RETURNS VARCHAR(100)
WITH NATIVE_COMPILATION, SCHEMABINDING,EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
(
       TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'English'
)
       -- Declare the return variable here
       DECLARE @RowPattern VARCHAR(100)
       

       -- Add the T-SQL statements to compute the return value here
       
                             IF (@DocumentType = 'MSG01')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:TxSetSubmissn'
                             END

                             ELSE IF (@DocumentType = 'MSG02')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:TxSetSubmissnAckNak'
                             END

                             ELSE IF (@DocumentType = 'MSG03')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:TxSetRjctn'
                             END

                             ELSE IF (@DocumentType = 'MSG04')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:LclBkNonBizDay'
                             END

                             ELSE IF (@DocumentType = 'MSG05')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:BnfcryTxSetEarlyNtfctn'
                             END

                             ELSE IF (@DocumentType = 'MSG06')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ReqToPay'
                             END

                             ELSE IF (@DocumentType = 'MSG07')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSG07PmtResponse'
                             END

                             ELSE IF (@DocumentType = 'MSG08')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ReqToPayRspnAckNak'
                             END

                             ELSE IF (@DocumentType = 'MSG09')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ReqToPayRspnItmRjctn'
                             END

                             ELSE IF (@DocumentType = 'MSG11')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:SttlmBlckdNtfctn'
                             END

                             ELSE IF (@DocumentType = 'MSG12')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:DfltPmtRespNtfctn'
                             END

                             ELSE IF (@DocumentType = 'MSG13')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:BnfcryPmtNtfctn'
                             END

                             ELSE IF (@DocumentType = 'MSG14')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSG14PmtFrdStsUp'
                             END

                             ELSE IF (@DocumentType = 'MSG15')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:TxSetSubmissnRpt'
                             END
                             ELSE IF (@DocumentType = 'MSG16')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ColltngFrdNtfctn'
                             END

                             ELSE IF (@DocumentType = 'MSQ01')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSQ01QueryMessage'
                             END

                             ELSE IF (@DocumentType = 'MSQ02')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSQ02QuerySubmAckNak'
                             END

                             ELSE IF (@DocumentType = 'MSQ03')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSQ03QueryRejection'
                             END

                             ELSE IF (@DocumentType = 'MSQ04')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSQ04QueryNotn'
                             END

                             ELSE IF (@DocumentType = 'MSQ05')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSQ05QuerySettlementPrevented'
                             END

                             ELSE IF (@DocumentType = 'MSS01')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSS01StopChq'
                             END

                             ELSE IF (@DocumentType = 'MSS02')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSS02StopChqAckNak'
                             END

                             ELSE IF (@DocumentType = 'MSS03')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSS03StopChqRejection'
                             END

                             ELSE IF (@DocumentType = 'MSS04')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSS04StopChq'
                             END

                             ELSE IF (@DocumentType = 'MSF01')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSF01FrdSetUnset'
                             END

                             ELSE IF (@DocumentType = 'MSF02')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSF02FraudItemSubmAckNak'
                             END

                             ELSE IF (@DocumentType = 'MSF03')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSF03FraudItemRejection'
                             END

                             ELSE IF (@DocumentType = 'MSF04')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSF04FrdSetUnsetNotn'
                             END

                             ELSE IF (@DocumentType = 'MSP01')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSP01PrevPd'
                             END

                             ELSE IF (@DocumentType = 'MSP02')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSP02PrevPdAckNak'
                             END

                             ELSE IF (@DocumentType = 'MSP03')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSP03PrevPdRejection'
                             END

                             ELSE IF (@DocumentType = 'MSP04')
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSP04PrevPd'
                             END

                             ELSE
                             BEGIN
                                    SET @RowPattern='/doc:Document/doc:ICSBatch/doc:DocBody/doc:MSG01PmtSubm'
                             END

       -- Return the result of the function
       RETURN @RowPattern

END