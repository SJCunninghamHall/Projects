CREATE PROCEDURE [Staging].[usp_GetAgencyISOExtractXML]
    (
		@AgencyID INT ,
		@MessageType VARCHAR(10) ,
		@MessageID VARCHAR(25) OUTPUT
    )
/*****************************************************************************************************
* Name				: [Staging].[usp_GetAgencyISOExtractXML]
* Description		: Extract Agency ISO Message XML data
* Called By			: iPSL.RNE.AgencyISOExtracts.dtsx
* Type of Procedure : Interpreted stored procedure
* Author			: Akuri Reddy
* Creation Date		: 04/11/2017
* Last Modified		: 
*******************************************************************************************************
* Returns 			: 
* Important Notes	: N/A 
* Dependencies		: 
*******************************************************************************************************/
AS

	SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @ObjectName VARCHAR(100) = '[Staging].[usp_GetAgencyISOExtractXML]';		        

		EXEC [Base].[usp_LogEvent] 1, @ObjectName, 'Enter'; 	

        DECLARE @FinalxmlResult XML;
		DECLARE @XML_Str NVARCHAR(MAX)
        DECLARE @XmlResult XML;
        DECLARE @Currency VARCHAR(3) = 'GBP';
        DECLARE @TxnCount INT;
		DECLARE @MSG01 VARCHAR(10) = 'MSG01'
		DECLARE @MSG05 VARCHAR(10) = 'MSG05'
		DECLARE @MSG06 VARCHAR(10) = 'MSG06'
		DECLARE @NoOfTxnsPerFile INT = ( SELECT CAST(ConfigValue AS INT)
                                         FROM   Config.ApplicationConfig W
                                         WHERE  ConfigType = 'AGENCY'
                                                AND ConfigParameter = 'ISOTxnsPerFile'
                                       );

        DECLARE  @Namespace VARCHAR(300) = 
			(
				SELECT 
					[ConfigValue]
				FROM    
					[Config].[ApplicationConfig]
				WHERE   
					[ConfigType] = 'AGENCY'
                AND 
					[ConfigParameter] = @MessageType
			)		 
		
        SELECT TOP 1
			@MessageID = MsgId
        FROM
			Staging.AgencyISOItem
        WHERE   
			AgencyId = @AgencyID
		AND 
			IntMessageType = @MessageType
		AND 
			ISNULL(IsExtracted, 0) = 0;

        SELECT 
			@TxnCount = COUNT(TxSetId) 
		FROM 
			(
				SELECT 
					TxSetId 
					,MIN(ID) As ID,
					ROW_NUMBER() OVER (ORDER BY TxSetId ) AS Rnk
				FROM   
					Staging.AgencyISOItem AI
				WHERE  
					AI.AgencyId = @AgencyID
				AND 
					IntMessageType = @MessageType 
				AND 
					MsgId = @MessageID
				AND 
					ISNULL(IsExtracted, 0) = 0
				GROUP BY 
					TxSetId
			) As R
		WHERE 
			R.Rnk <= @NoOfTxnsPerFile




		SELECT
			TxSetId
			,MIN(ID) As ID
			,ROW_NUMBER() OVER (ORDER BY TxSetId ) AS Rnk
		INTO
			#R
		FROM   
			Staging.AgencyISOItem AI
		WHERE  
			AI.AgencyId = @AgencyID
		AND 
			IntMessageType = @MessageType 
		AND 
			MsgId = @MessageID
		AND 
			ISNULL(IsExtracted, 0) = 0
		GROUP BY 
			TxSetId



		SELECT 
			TxSetId
			,ID
			,Rnk 
		INTO
			#Txns
		FROM 
			#R R
		WHERE 
			R.Rnk <= @NoOfTxnsPerFile
	

			SELECT 
				AI.TxSetId
				,Credit_CdtItmId
				,MIN(AI.Id) As ID
			INTO
				#Txn_Cr_CTE
			FROM 
				Staging.AgencyISOItem AI
			INNER JOIN 
				#Txns T 
			ON 
				AI.TxSetId = T.TxSetId
			WHERE 
				AI.AgencyId = @AgencyID 
			AND 
				AI.IntMessageType = @MessageType
			GROUP BY 
				AI.TxSetId
				,Credit_CdtItmId


			CREATE NONCLUSTERED INDEX nci_ID ON #Txn_Cr_CTE(ID)


			SELECT 
				AI.TxSetId
				,DbtItmId
				,MIN(AI.Id) As ID
			INTO
				#Txn_Db_CTE
			FROM 
				Staging.AgencyISOItem AI
			INNER JOIN 
				#Txns T 
			ON 
				AI.TxSetId = T.TxSetId
			WHERE 
				AI.AgencyId = @AgencyID 
			AND 
				AI.IntMessageType = @MessageType
			GROUP BY 
				AI.TxSetId
				,DbtItmId


			CREATE NONCLUSTERED INDEX nci_ID ON #Txn_Db_CTE(ID)



		SELECT  @XmlResult = ( SELECT   ( SELECT    ( SELECT TOP 1
																  D.[MsgId] ,
																  [CreDtTm] ,
																  @TxnCount AS [NbOfTxs] ,
																  IIF(@MessageType=@MSG01,[SndrId],NULL) As SndrId ,
																  IIF(@MessageType <> @MSG01,[RcvrId],NULL) As RcvrId ,
																  IIF(@MessageType=@MSG01,[DrctPtcpt],NULL) As [DrctPtcpt] ,
																  [TstInd] ,
																  [Sgntr]
														  FROM    Staging.AgencyISOItem D
														  WHERE   D.MsgId = @MessageID
														FOR
														  XML PATH('GrpHdr') ,
															  TYPE
														) ,
														( SELECT 
																  AI.[TxSetId] ,
																  RIGHT('00'
																  + CONVERT(VARCHAR, [TxSetVrsn]),
																  2) AS TxSetVrsn ,
																  [ColltngPtcptId] ,
																  [CaptrdDtTm] ,
																  IIF(@MessageType <> @MSG01,[TxSetSubDtTm],NULL) As [TxSetSubDtTm] ,
																  [Src] ,
																  [ColltngBrnchLctn] ,
																  [ColltngLctn] ,
																  [ChanlRskTp] ,
																  [ChanlDesc] ,
																  [ColltnPt] ,
																  [ColltngBrnchRef] ,
																  IIF(@MessageType=@MSG01,[FrdChckOnlyInd],NULL) As [FrdChckOnlyInd] ,
																  [NbOfItms] ,
																  [EndPtId] ,
																  (
																	SELECT
																	  CR_AI.Credit_CdtItmId AS "CdtItmId" ,
																	  Credit_CdtItmTp AS "CdtItmTp" ,
																	  IIF(@MessageType <> @MSG06,Credit_CdtItmTxCd,NULL) AS "CdtItmTxCd" ,
																	  IIF(@MessageType <> @MSG06,OnUsItmInd,NULL) AS "OnUsItmInd" ,
																	  Credit_AmtCcy AS "Amt/@Ccy" ,
																	  Credit_Amt AS "Amt" ,
																	  RIGHT(REPLICATE('0',6)+Credit_BkCd,6) AS "BkCd" ,
																	  Credit_AcctNb AS "AcctNb" ,
																	  Credit_RefNb AS "RefNb" ,
																	  IIF(@MessageType=@MSG01,Credit_XtrnlDataRef,NULL) As "XtrnlDataRef" ,
																	  IIF(@MessageType <> @MSG06,Credit_Img,NULL) AS "ItmImgData/Img" ,
																	  IIF(@MessageType = @MSG05, Credit_FrntImgQltyIndctnInd,NULL) AS "ItmImgData/FrntImgQltyIndctnInd" ,
																	  IIF(@MessageType = @MSG05,Credit_BckImgQltyIndctnInd,NULL) AS "ItmImgData/BckImgQltyIndctnInd" ,
																	  IIF(@MessageType = @MSG01,Credit_ImgHash,NULL) AS "ItmImgData/ImgHash" ,
																	  IIF(@MessageType=@MSG01,Credit_ImgCaptrId,NULL) As "ItmImgMetaData/ImgCaptrId" ,
																	  IIF(@MessageType=@MSG01,Credit_ImgCaptrDvcId,NULL) As "ItmImgMetaData/ImgCaptrDvcId" ,
																	  IIF(@MessageType=@MSG01,Credit_ImgCaptrLctn,NULL) As "ItmImgMetaData/ImgCaptrLctn" ,
																	  IIF(@MessageType=@MSG01,Credit_ImgCaptrDtTm,NULL) As "ItmImgMetaData/ImgCaptrDtTm" ,
																	  IIF(@MessageType <> @MSG06,Credit_ChqAtRskInd,NULL) AS "CdtItmFrdData/ChqAtRskInd" ,
																	  Credit_BnfcryNm AS "CdtItmFrdData/BnfcryNm" ,
																	  Credit_VrtlCdtInd AS "CdtItmFrdData/VrtlCdtInd" ,
																	  Credit_RefData AS "CdtItmFrdData/RefData" ,
																	  IIF(@MessageType <> @MSG06,ISNULL(CshAmtCcy,@Currency),NULL) AS "CdtItmFrdData/CshAmt/@Ccy" ,
																	  IIF(@MessageType <> @MSG06,Credit_CshAmt,NULL) AS "CdtItmFrdData/CshAmt" ,
																	  IIF(@MessageType <> @MSG06,ISNULL(FnddAmtCcy,@Currency),NULL) AS "CdtItmFrdData/FnddAmt/@Ccy" ,
																	  IIF(@MessageType <> @MSG06,Credit_FnddAmt,NULL) AS "CdtItmFrdData/FnddAmt" ,
																	  IIF(@MessageType <> @MSG06,ISNULL(NonFunddAmtCcy,@Currency),NULL) AS "CdtItmFrdData/NonFunddAmt/@Ccy" ,
																	  IIF(@MessageType <> @MSG06,Credit_NonFunddAmt,NULL) AS "CdtItmFrdData/NonFunddAmt" ,
																	  Credit_NbOfCdtsOrDbts AS "CdtItmFrdData/NbOfCdtsOrDbts" ,
																	  Credit_BkCdRprdInd AS "RprdItm/BkCdRprdInd" ,
																	  Credit_AcctNbRprdInd AS "RprdItm/AcctNbRprdInd" ,
																	  Credit_AmtRprdInd AS "RprdItm/AmtRprdInd" ,
																	  IIF(@MessageType <> @MSG01,Credit_SrlNbRprdInd,NULL) AS "RprdItm/SrlNbRprdInd" ,
																	  Credit_RefNbRprdInd AS "RprdItm/RefNbRprdInd" ,
																	  Credit_BkCdDfltdInd AS "DfltdItm/BkCdDfltdInd" ,
																	  Credit_AcctNbDfltdInd AS "DfltdItm/AcctNbDfltdInd" ,
																	  Credit_RefNbDfltdInd AS "DfltdItm/RefNbDfltdInd" ,
																	  IIF(@MessageType <> @MSG01,Credit_SwitchedSortCode,NULL) AS "SwtchdItm/BkCd" ,
																	  IIF(@MessageType <> @MSG01,Credit_SwitchedAccount,NULL) AS "SwtchdItm/AcctNb"
																	FROM    
																		Staging.AgencyISOItem CR_AI
																	INNER JOIN 
																		#Txn_Cr_CTE CR 
																	ON 
																		CR_AI.TxSetId = AI.TxSetId 
																	AND 
																		CR_AI.Id = CR.ID
																	WHERE 
																		CR_AI.TxSetId = AI.TxSetId 
																	AND 
																		CR_AI.AgencyId = @AgencyID
																	FOR
																	XML PATH('CrdtItm') ,
																		TYPE
																  ),
																  (
																	SELECT
																	  Db_AI.DbtItmId AS "DbtItmId" ,
																	  DbtItmTp AS "DbtItmTp" ,
																	  DbtItmTxCd AS "DbtItmTxCd" ,																  
																	  RpresntdItmInd AS "RpresntdItmInd" ,
																	  IIF(@MessageType <> @MSG06,OnUsItmInd,NULL) AS "OnUsItmInd" ,
																	  AmtCcy AS "Amt/@Ccy" ,
																	  Amt AS "Amt" ,
																	  RIGHT(REPLICATE('0',6)+BkCd,6) AS "BkCd" ,
																	  AcctNb AS "AcctNb" ,
																	  SrlNb AS "SrlNb" ,
																	  IIF(@MessageType <> @MSG01,HghValItm,NULL) AS "HghValItm" ,
																	  IIF(@MessageType = @MSG06,DayOneRspnWndwStartDtTm,NULL) AS "DayOneRspnWndwStartDtTm" ,
																	  IIF(@MessageType = @MSG06,DayOneRspnWndwEndDtTm,NULL) AS "DayOneRspnWndwEndDtTm" ,
																	  IIF(@MessageType = @MSG06,DayTwoRspnWndwStartDtTm,NULL) AS "DayTwoRspnWndwStartDtTm" ,
																	  IIF(@MessageType = @MSG06,DayTwoRspnWndwEndDtTm,NULL) AS "DayTwoRspnWndwEndDtTm" ,
																	  IIF(@MessageType <> @MSG05,XtrnlDataRef,NULL) AS "XtrnlDataRef" ,
																	  Img AS "ItmImgData/Img" ,
																	  IIF(@MessageType = @MSG01,ImgHash,NULL) AS "ItmImgData/ImgHash" ,
																	  IIF(@MessageType <> @MSG01,FrntImgQltyIndctnInd,NULL) AS "ItmImgData/FrntImgQltyIndctnInd" ,
																	  IIF(@MessageType <> @MSG01,BckImgQltyIndctnInd,NULL) AS "ItmImgData/BckImgQltyIndctnInd" ,
																	  IIF(@MessageType = @MSG01,ImgCaptrId,NULL) AS "ItmImgMetaData/ImgCaptrId" ,
																	  IIF(@MessageType = @MSG01,ImgCaptrDvcId,NULL) AS "ItmImgMetaData/ImgCaptrDvcId" ,
																	  IIF(@MessageType = @MSG01,ImgCaptrLctn,NULL) AS "ItmImgMetaData/ImgCaptrLctn" ,
																	  IIF(@MessageType = @MSG01,ImgCaptrDtTm,NULL) AS "ItmImgMetaData/ImgCaptrDtTm" ,
																	  IIF(@MessageType <> @MSG05,DtOfFrstChq,NULL) AS "DbtItmFrdData/DtOfFrstChq" ,
																	  IIF(@MessageType <> @MSG05,DtOfLstChq,NULL) AS "DbtItmFrdData/DtOfLstChq" ,
																	  IIF(@MessageType <> @MSG05,NbOfCtrPtys,NULL) AS "DbtItmFrdData/NbOfCtrPtys" ,
																	  IIF(@MessageType <> @MSG05,NbOfVldChqs,NULL) AS "DbtItmFrdData/NbOfVldChqs" ,
																	  IIF(@MessageType <> @MSG05,NbOfFrdChqs,NULL) AS "DbtItmFrdData/NbOfFrdChqs" ,
																	  IIF(@MessageType <> @MSG05,HghstAmtCcy,NULL) AS "DbtItmFrdData/HghstAmt/@Ccy" ,
																	  IIF(@MessageType <> @MSG05,HghstAmt,NULL) AS "DbtItmFrdData/HghstAmt" ,
																	  IIF(@MessageType <> @MSG05,RskInd,NULL) AS "DbtItmFrdData/RskInd" ,
																	  BkCdRprdInd AS "RprdItm/BkCdRprdInd" ,
																	  AcctNbRprdInd AS "RprdItm/AcctNbRprdInd" ,
																	  AmtRprdInd AS "RprdItm/AmtRprdInd" ,
																	  SrlNbRprdInd AS "RprdItm/SrlNbRprdInd" ,
																	  IIF(@MessageType <> @MSG01,RefNbRprdInd,NULL) AS "RprdItm/RefNbRprdInd" ,
																	  BkCdDfltdInd AS "DfltdItm/BkCdDfltdInd" ,
																	  AcctNbDfltdInd AS "DfltdItm/AcctNbDfltdInd" ,
																	  SrlNbDfltdInd AS "DfltdItm/SrlNbDfltdInd",
																	  IIF(@MessageType <> @MSG01,FORMAT(SwitchedSortCode,REPLICATE('0',6)),NULL) AS "SwtchdItm/BkCd" ,
																	  IIF(@MessageType <> @MSG01,SwitchedAccount,NULL) AS "SwtchdItm/AcctNb" ,
																	  IIF(@MessageType = @MSG06,DplctItmId,NULL) AS "DbtDplctItm/DplctItmId" ,
																	  IIF(@MessageType = @MSG06,DbtDplctSts,NULL) AS "DbtDplctItm/DbtDplctSts" ,
																	  IIF(@MessageType = @MSG06,DtFirstPresntd,NULL) AS "DbtDplctItm/DtFirstPresntd" ,
																	  IIF(@MessageType = @MSG06,MmbId,NULL) AS "DbtDplctItm/MmbId" ,
																	  IIF(@MessageType = @MSG06,OrgnlCaptrDt,NULL) AS "DbtDplctItm/OrgnlCaptrDt" ,
																	  IIF(@MessageType = @MSG06,OrgnlSrc,NULL) AS "DbtDplctItm/OrgnlSrc" ,
																	  IIF(@MessageType = @MSG06,StopdDt,NULL) AS "DbtStopdItm/StopdDt" ,
																	  IIF(@MessageType = @MSG06,StopdSts,NULL) AS "DbtStopdItm/StopdSts" ,
																	  IIF(@MessageType = @MSG06,@Currency,NULL) AS "DbtStopdItm/Amt/@Ccy" ,
																	  IIF(@MessageType = @MSG06,StopAmt,NULL) AS "DbtStopdItm/Amt" ,
																	  IIF(@MessageType = @MSG06,BnfcryNm,NULL) AS "DbtStopdItm/BnfcryNm", 
																	  IIF(@MessageType = @MSG06,StopItmStartRg,NULL) AS "DbtStopdItm/StopItmStartRg" ,
																	  IIF(@MessageType = @MSG06,StopItmEndRg,NULL) AS "DbtStopdItm/StopItmEndRg" 
																FROM    
																	Staging.AgencyISOItem Db_AI
																INNER JOIN 
																	#Txn_Db_CTE Db 
																ON 
																	Db_AI.TxSetId = AI.TxSetId 
																AND 
																	Db_AI.Id = Db.ID
																WHERE 
																	Db_AI.TxSetId = AI.TxSetId  
																AND 
																	Db_AI.AgencyId = @AgencyID
																FOR
																		XML PATH('DbtItm') ,
																			TYPE
																  )		 
														FROM    
															Staging.AgencyISOItem AI
														INNER JOIN 
															Txns T 
														ON 
															AI.Id = T.ID																  
														FOR
														  XML PATH('TxSet') ,
															  TYPE
														)
											FOR
											  XML PATH('TxSetSubmissn') ,
												  TYPE
											)
								 FOR
								   XML PATH('TxSetSubmissn') ,
									   TYPE
								 );
		IF @MessageType=@MSG05
			SET @XML_Str =REPLACE( REPLACE(CAST(@XmlResult  AS NVARCHAR(MAX)),'<TxSetSubmissn>','<BnfcryTxSetEarlyNtfctn>'),'</TxSetSubmissn>','</BnfcryTxSetEarlyNtfctn>')
		IF @MessageType=@MSG06
			SET @XML_Str =REPLACE( REPLACE(CAST(@XmlResult  AS NVARCHAR(MAX)),'<TxSetSubmissn>','<ReqToPay>'),'</TxSetSubmissn>','</ReqToPay>')

		IF @MessageType <> @MSG01
			SET @XmlResult= CAST(@XML_Str AS XML)

		SET @FinalxmlResult = ( SELECT  1 AS Tag ,
                                        NULL AS Parent ,
                                        @XmlResult AS [Document!1!!xmltext] ,
                                        @Namespace AS [Document!1!xmlns]
                              FOR
                                XML EXPLICIT
                              );  


        SELECT  @FinalxmlResult As XmlResult;


    END TRY

    BEGIN CATCH
        DECLARE @Number INT = ERROR_NUMBER();
        DECLARE @Message VARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @UserName NVARCHAR(128) = CONVERT(sysname, ORIGINAL_LOGIN());
        DECLARE @Severity INT = ERROR_SEVERITY();
        DECLARE @State INT = ERROR_STATE();
        DECLARE @Type VARCHAR(128) = 'Stored Procedure';
        DECLARE @Line INT = ERROR_LINE();
        DECLARE @Source VARCHAR(128) = ERROR_PROCEDURE();
        EXEC [Base].[usp_LogException] @Number, @Message, @UserName, @Severity,
            @State, @Type, @Line, @Source;
        THROW;  
    END CATCH;
GO
	
GRANT EXECUTE ON [Staging].[usp_GetAgencyISOExtractXML] TO [RNESVCAccess];
	
GO


EXEC sys.sp_addextendedproperty @name = N'MS_Description',
    @value = N'Extract Agency ISO Message XML data',
    @level0type = N'SCHEMA', @level0name = N'Staging',
    @level1type = N'PROCEDURE', @level1name = N'usp_GetAgencyISOExtractXML';
GO

EXEC sys.sp_addextendedproperty @name = N'Version', @value = N'$(Version)',
    @level0type = N'SCHEMA', @level0name = N'Staging',
    @level1type = N'PROCEDURE', @level1name = N'usp_GetAgencyISOExtractXML';
GO

EXEC sp_addextendedproperty @name = N'Component',
    @value = N'iPSL.ICE.RNE.Database', @level0type = N'SCHEMA',
    @level0name = N'Staging', @level1type = N'PROCEDURE',
    @level1name = N'usp_GetAgencyISOExtractXML';
GO
