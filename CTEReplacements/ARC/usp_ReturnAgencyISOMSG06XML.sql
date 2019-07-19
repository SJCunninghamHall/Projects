CREATE PROCEDURE [Agency].[usp_ReturnAgencyISOMSG06XML]
	 @AgencyId INT
    ,@EligibleISOMSG06Tsets [Agency].[tv_ISOMSG06Tsets] READONLY
	,@AgyReceiverId VARCHAR(6)
	,@AgyCollectingParticpantId VARCHAR(6)
	,@GrpHdrMsgIdSequence BIGINT
	,@Namespace VARCHAR(300)
	,@FinalxmlResult XML OUTPUT	
/*****************************************************************************************************
* Name				: [Agency].[usp_ReturnAgencyISOMSG06XML]
* Description		: This Stored Procedure returns the XML for the AGY MSG06 ISO Extract 
* Type of Procedure : Interpreted stored procedure
* Author			: Pavan Kumar Manneru
* Creation Date		: 01/02/2017
*******************************************************************************************************/
AS
    BEGIN
		SET NOCOUNT ON;

		SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

		 BEGIN TRY 
		
			BEGIN TRAN

				DECLARE @InputSignature VARBINARY(MAX) = CONVERT(Varbinary(MAX),'Signature')
				DECLARE @EncodedSignature VARCHAR(MAX) = CAST(N'' as xml).value('xs:base64Binary(sql:variable("@InputSignature"))','VARCHAR(MAX)')

				SELECT	
					ETSET.TransactionSetIdWithVersion
					,ETSET.ItemId
					,TX.TransactionSetId	AS	TxSetId 
					,RIGHT('00' + cast(TX.[Version] as varchar(2)),2) AS TxSetVrsn
					,TX.CollectingParticipantId AS ColltngPtcptId
					,TX.CaptureDate AS CaptrdDtTm
					,TX.TSetSubmissionDateTime AS TxSetSubDtTm
					,RIGHT('0000' + cast(TX.AltSource as varchar(4)),4) AS Src						
					,TX.CollectingBranchLocation AS ColltngBrnchLctn
					,TX.CollectingLocation AS ColltngLctn
					,TX.ChannelRiskType AS ChanlRskTp
					,TX.ChannelDescription AS ChanlDesc
					,TX.CollectionPoint AS ColltnPt
					,TX.CollectionBranchRef AS ColltngBrnchRef
					,TX.NumberOfItems AS NbOfItms
					,TX.EndPointId AS EndPtId
				INTO
					#ExtractTXSet
				FROM
					@EligibleISOMSG06Tsets ETSET
				INNER JOIN 
					[Base].[vw_TXSet] TX 
				ON 
					ETSET.InternalTxId = TX.InternalTxId			

			
			SELECT	
				ETSET.TransactionSetIdWithVersion
				,ETSET.ItemId
				,DB.DebitId AS DbtItmId
				,ITMTYPE.ItemTypeCode AS DbtItmTp
				,IIF(LTRIM(RTRIM(FD.TranCode))='',NULL,FD.TranCode) AS DbtItmTxCd
				,IIF(FD.Represent = 1, 'true', 'false') AS RpresntdItmInd
				,FD.Amount AS Amt
				,CCY.Currency AS AmtCcy
				,RIGHT('000000' + cast(FD.Sortcode as varchar(6)),6) AS BkCd
				,RIGHT('00000000' + cast(FD.AccountNumber as varchar(8)),8) AS AcctNb
				,RIGHT('000000' + cast(FD.SerialNumber as varchar(6)),6) AS SrlNb
				,IIF(FD.HighValue = 1, 'true', 'false') AS HghValItm
				,FD.Day1ResponseStartDateTime AS DayOneRspnWndwStartDtTm
				,FD.Day1ResponseEndDateTime AS DayOneRspnWndwEndDtTm
				,FD.Day2ResponseStartDatetime AS DayTwoRspnWndwStartDtTm
				,FD.Day2ResponseEndDateTime AS DayTwoRspnWndwEndDtTm
				,FD.RicherDataRef AS XtrnlDataRef
				--ItmImgData
				,IMG.Image AS Img
				,CASE 
					WHEN IMG.FrontImageQuality = 1 
					THEN 'true'
					WHEN IMG.FrontImageQuality = 0 
					THEN 'false'
					ELSE NULL 
				END FrntImgQltyIndctnInd
				,CASE 
					WHEN IMG.RearImageQuality = 1 
					THEN 'true'
					WHEN IMG.RearImageQuality = 0 
					THEN 'false'
					ELSE NULL 
				END AS BckImgQltyIndctnInd
				--DbtItmFrdData
				,IIF(DBFRD.SuspiciousCheque=1,'true','false') AS ChqAtRskInd
				,DBFRD.DateOfFirstCheque AS DtOfFrstChq
				,DBFRD.DateOfLastCheque AS DtOfLstChq
				,DBFRD.NumberOfCounterparties AS NbOfCtrPtys
				,DBFRD.NumberOfGoodCheques AS NbOfVldChqs
				,DBFRD.NumberOfFraudCheques AS NbOfFrdChqs
				,DBFRD.LargestAmount AS HghstAmt
				,DBFRDCCY.Currency AS HghstAmtCcy
				,RIGHT('0000' + cast(DBFRD.RiskIndicator as varchar(4)),4) AS RskInd
				--RprdItm
				,IIF(FD.RepairedSortcode = 1, 'true', 'false') AS BkCdRprdInd
				,IIF(FD.RepairedAccount = 1, 'true', 'false') AS AcctNbRprdInd
				,IIF(FD.RepairedAmount = 1, 'true', 'false') AS AmtRprdInd 
				,IIF(FD.RepairedSerial = 1, 'true', 'false') AS SrlNbRprdInd 
				,IIF(FD.RepairedReference = 1, 'true', 'false') AS RefNbRprdInd 
				--DfltdItm
				,IIF(FD.DefaultedSortcode = 1, 'true', 'false') AS BkCdDfltdInd 
				,IIF(FD.DefaultedAccount = 1, 'true', 'false') AS AcctNbDfltdInd 
				,IIF(FD.DefaultedSerialNumber = 1, 'true', 'false') AS SrlNbDfltdInd
				--SwtchdItm
				,RIGHT('000000' + cast(FD.SwitchedSortCode as varchar(6)),6) AS SwitchedSortCode
				,RIGHT('00000000' + cast(FD.SwitchedAccount as varchar(8)),8) AS SwitchedAccount
				--DbtDplctItm
				,DBDUP.DuplicateItemId AS DplctItmId
				,DBDUP.Status AS DbtDplctSts
				,DBDUP.DateFirstSeen AS DtFirstPresntd
				,DBDUP.OriginalCollectingParticipant AS MmbId
				,DBDUP.OriginalCaptureDate AS OrgnlCaptrDt
				,RIGHT('0000' + cast(DBDUP.OriginalSource as varchar(4)),4) AS OrgnlSrc						
				--DbtStopdItm
				,DBSTOP.StoppedDate AS StopdDt
				,DBSTOP.Status AS StopdSts
				,DBSTOP.Amount AS DebitStoppedAmount
				,DBSTOPCCY.Currency AS DebitStoppedAmountCcy
				,DBSTOP.Beneficiary AS BnfcryNm
				,RIGHT('000000' + cast(DBSTOP.StopItemStartRange as varchar(6)),6) AS StopItmStartRg
				,RIGHT('000000' + cast(DBSTOP.StopItemEndRange as varchar(6)),6) AS StopItmEndRg
			INTO
				#ExtractDebit						
			FROM 
				@EligibleISOMSG06Tsets ETSET
			INNER JOIN 
				[Base].[vw_TXSet] TX 
			ON 
				ETSET.InternalTxId = TX.InternalTxId	
			INNER JOIN 
				Base.Debit DB WITH (SNAPSHOT) 
			ON 
				DB.ItemId = ETSET.ItemId 
			INNER JOIN 
				Base.vw_FinalDebit FD 
			ON 
				DB.DebitId=FD.DebitId
			INNER JOIN 
				Base.ItemUpdate IU WITH (SNAPSHOT) 
			ON 
				IU.InternalId = DB.ItemId
			INNER JOIN 
				Base.Core CO WITH (SNAPSHOT) 
			ON 
				CO.CoreId = IU.CoreID
			INNER JOIN 
				Lookup.ItemType ITMTYPE WITH (SNAPSHOT) 
			ON 
				ITMTYPE.Id = FD.ItemType
			INNER JOIN 
				Lookup.Currency CCY WITH (SNAPSHOT) 
			ON 
				CCY.Id = FD.Currency
			LEFT JOIN 
				Base.[Image] IMG 
			ON 
				IMG.ItemId = DB.ItemId
			LEFT JOIN 
				Base.DebitFraudData DBFRD WITH (SNAPSHOT) 
			ON 
				DBFRD.ItemId = DB.ItemId
			LEFT JOIN 
				Lookup.Currency DBFRDCCY WITH (SNAPSHOT) 
			ON 
				DBFRDCCY.Id = DBFRD.LargestAmountCurrency
			LEFT JOIN 
				Base.DuplicateDebit DBDUP WITH (SNAPSHOT) 
			ON 
				DBDUP.ItemId = DB.ItemId
			LEFT JOIN 
				Base.StoppedItem DBSTOP WITH (SNAPSHOT) 
			ON 
				DBSTOP.ItemId = DB.ItemId
			LEFT JOIN 
				Lookup.Currency DBSTOPCCY WITH (SNAPSHOT) 
			ON 
				DBSTOPCCY.Id = DBSTOP.Currency
			WHERE 
				CO.IntMessageType = '06MA01'  
			AND 
				FD.PayingParticipantId = @AgencyId
			
			CREATE CLUSTERED INDEX ci_TransactionSetIdWithVersion ON #ExtractDebit(TransactionSetIdWithVersion)

			SELECT	
				TransactionSetIdWithVersion
				,DbtItmId
				,CdtItmId
				,CdtItmTp
				,Amt
				,AmtCcy
				,BkCd
				,AcctNb
				,RefNb
				,BnfcryNm
				,VrtlCdtInd
				,RefData
				,BkCdRprdInd
				,AcctNbRprdInd
				,AmtRprdInd
				,SrlNbRprdInd
				,RefNbRprdInd
				,BkCdDfltdInd
				,AcctNbDfltdInd
				,RefNbDfltdInd
				,SwitchedSortCode
				,SwitchedAccount
			INTO
				#ExtractCredit
			FROM
				(
					SELECT	
						EDB.TransactionSetIdWithVersion
						,EDB.DbtItmId
						,CR.CreditId AS CdtItmId
						,ITMTYPE.ItemTypeCode AS CdtItmTp
						,0.00 AS Amt --CR.Amount AS Amt --(As per the Bug 212237 fix)
						,CCY.Currency AS AmtCcy
						,RIGHT('000000' + cast([CR].[Sortcode] as varchar(6)),6) AS BkCd
						,RIGHT('00000000' + cast([CR].[AccountNumber] as varchar(8)),8) AS AcctNb
						,CR.Reference AS RefNb
						--CdtItmFrdData
						,CRFRD.BeneficiaryName AS BnfcryNm
						,IIF(CRFRD.VirtualCredit = 1, 'true', 'false') AS VrtlCdtInd
						,CRFRD.ReferenceData AS RefData
						--RprdItm
						,IIF(CR.RepairedSortcode = 1, 'true', 'false') AS BkCdRprdInd
						,IIF(CR.RepairedAccount = 1, 'true', 'false') AS AcctNbRprdInd
						,IIF(CR.RepairedAmount = 1, 'true', 'false') AS AmtRprdInd 
						,IIF(CR.RepairedSerial = 1, 'true', 'false') AS SrlNbRprdInd 
						,IIF(CR.RepairedReference = 1, 'true', 'false') AS RefNbRprdInd
						--DfltdItm
						,IIF(CR.DefaultedSortcode = 1, 'true', 'false') AS BkCdDfltdInd 
						,IIF(CR.DefaultedAccount = 1, 'true', 'false') AS AcctNbDfltdInd 
						,IIF(CR.DefaultedReference = 1, 'true', 'false') AS RefNbDfltdInd					
						--SwtchdItm
						,RIGHT('000000' + cast([CR].[SwitchedSortCode] as varchar(6)),6) AS SwitchedSortCode
						,RIGHT('00000000' + cast([CR].[SwitchedAccount] as varchar(8)),8) SwitchedAccount				
						,ROW_NUMBER() OVER (PARTITION BY CR.CreditId ORDER BY CR.ItemId DESC) RKD
					FROM 
						#ExtractDebit EDB
					INNER JOIN 
						[Base].[vw_TXSet] TX 
					ON 
						EDB.TransactionSetIdWithVersion = TX.TransactionSetIdWithVersion 
					INNER JOIN 
						Base.vw_FinalCredit CR 
					ON 
						TX.InternalTxId = CR.InternalTxId
					INNER JOIN 
						Lookup.ItemType ITMTYPE WITH (SNAPSHOT) 
					ON 
						ITMTYPE.Id = CR.ItemType
					INNER JOIN 
						Lookup.Currency CCY WITH (SNAPSHOT) 
					ON 
						CCY.Id = CR.Currency
					INNER JOIN 
						Base.CreditFraudData CRFRD WITH (SNAPSHOT) 
					ON 
						CRFRD.ItemId = CR.ItemId
				) ECR
			WHERE 
				ECR.RKD = 1

			-- Indexes --
			CREATE CLUSTERED INDEX ci_TransactionSetIdWithVersion ON #ExtractCredit(TransactionSetIdWithVersion)
			
			CREATE NONCLUSTERED INDEX 
				nci_TransactionSetIdWithVersion_RKD 
			ON
				#ExtractCredit(TransactionSetIdWithVersion, RKD)
			WHERE
				RKD = 1
			-------------
			
			;WITH ExtractGrpHdr
			AS
			(
				SELECT	
					CONCAT
						(
							@AgyCollectingParticpantId,
							RIGHT(DATEPART(YEAR,GETDATE()),2),
							Right(Concat('000',DATEPART(DAYOFYEAR,GETDATE())),3),
							'C',
							':',
							RIGHT(CONCAT('0000000000',@GrpHdrMsgIdSequence),10)
						) AS MsgId
						,GETDATE() AS CreDtTm
						,@AgyReceiverId AS RcvrId
						,'false' AS TstInd
						,@EncodedSignature AS Sgntr
			)


			SELECT 
				@FinalxmlResult = 
			(
			SELECT
				(
				SELECT 				
					(
						SELECT	
							MsgId
							,CreDtTm
							,CNTTXN.NumberofTransactions AS NbOfTxs
							,RcvrId
							,TstInd
							,Sgntr
						FROM 
							ExtractGrpHdr
						CROSS JOIN 
							(
								SELECT 
									COUNT(1) NumberofTransactions 
								FROM 
									#ExtractTXSet
							) CNTTXN
					FOR XML PATH('GrpHdr') ,TYPE
					),
							(
							SELECT	TxSetId
									,TxSetVrsn
									,ColltngPtcptId
									,CaptrdDtTm
									,TxSetSubDtTm
									,Src
									,ColltngBrnchLctn
									,ColltngLctn
									,ChanlRskTp
									,ChanlDesc
									,ColltnPt
									,ColltngBrnchRef
									,NbOfItms
									,EndPtId
									,
									(
										SELECT	
											CdtItmId
											,CdtItmTp
											,AmtCcy AS "Amt/@Ccy"
											,Amt							
											,BkCd
											,AcctNb
											,RefNb
											,BnfcryNm AS "CdtItmFrdData/BnfcryNm"
											,VrtlCdtInd AS "CdtItmFrdData/VrtlCdtInd"
											,RefData AS "CdtItmFrdData/RefData"
											,BkCdRprdInd AS "RprdItm/BkCdRprdInd"
											,AcctNbRprdInd AS "RprdItm/AcctNbRprdInd"
											,AmtRprdInd	   AS "RprdItm/AmtRprdInd"
											,SrlNbRprdInd  AS "RprdItm/SrlNbRprdInd"
											,RefNbRprdInd  AS "RprdItm/RefNbRprdInd"
											,BkCdDfltdInd  AS "DfltdItm/BkCdDfltdInd"
											,AcctNbDfltdInd	AS "DfltdItm/AcctNbDfltdInd"
											,RefNbDfltdInd AS "DfltdItm/RefNbDfltdInd"
											,SwitchedSortCode AS "SwtchdItm/BkCd"
											,SwitchedAccount  AS "SwtchdItm/AcctNb"
										FROM 
											#ExtractCredit CR 
										WHERE 
											TX.TransactionSetIdWithVersion = CR.TransactionSetIdWithVersion
										FOR XML PATH('CrdtItm') ,TYPE
									)
									,
									(
										SELECT	
											DbtItmId
											,DbtItmTp
											,DbtItmTxCd
											,RpresntdItmInd
											,AmtCcy AS "Amt/@Ccy"
											,Amt							
											,BkCd
											,AcctNb
											,SrlNb
											,HghValItm
											,DayOneRspnWndwStartDtTm
											,DayOneRspnWndwEndDtTm
											,DayTwoRspnWndwStartDtTm
											,DayTwoRspnWndwEndDtTm
											,XtrnlDataRef
											,Img AS "ItmImgData/Img"
											,FrntImgQltyIndctnInd AS "ItmImgData/FrntImgQltyIndctnInd"
											,BckImgQltyIndctnInd AS "ItmImgData/BckImgQltyIndctnInd"
											,ChqAtRskInd AS "DbtItmFrdData/ChqAtRskInd"
											,DtOfFrstChq AS "DbtItmFrdData/DtOfFrstChq" 
											,DtOfLstChq	 AS "DbtItmFrdData/DtOfLstChq"
											,NbOfCtrPtys AS "DbtItmFrdData/NbOfCtrPtys"
											,NbOfVldChqs AS "DbtItmFrdData/NbOfVldChqs"
											,NbOfFrdChqs AS "DbtItmFrdData/NbOfFrdChqs"
											,IIF(HghstAmt IS NOT NULL,HghstAmtCcy,NULL) AS "DbtItmFrdData/HghstAmt/@Ccy"
											,HghstAmt	 AS "DbtItmFrdData/HghstAmt"						 
											,RskInd		 AS "DbtItmFrdData/RskInd"
											,BkCdRprdInd AS "RprdItm/BkCdRprdInd"
											,AcctNbRprdInd AS "RprdItm/AcctNbRprdInd"
											,AmtRprdInd	   AS "RprdItm/AmtRprdInd"
											,SrlNbRprdInd  AS "RprdItm/SrlNbRprdInd"
											,RefNbRprdInd  AS "RprdItm/RefNbRprdInd"
											,BkCdDfltdInd  AS "DfltdItm/BkCdDfltdInd"
											,AcctNbDfltdInd	AS "DfltdItm/AcctNbDfltdInd"
											,SrlNbDfltdInd AS "DfltdItm/SrlNbDfltdInd"
											,SwitchedSortCode AS "SwtchdItm/BkCd"
											,SwitchedAccount AS "SwtchdItm/AcctNb"
											,DplctItmId AS "DbtDplctItm/DplctItmId"
											,DbtDplctSts AS "DbtDplctItm/DbtDplctSts"
											,DtFirstPresntd AS "DbtDplctItm/DtFirstPresntd"
											,MmbId AS "DbtDplctItm/MmbId"
											,OrgnlCaptrDt AS "DbtDplctItm/OrgnlCaptrDt"
											,OrgnlSrc AS "DbtDplctItm/OrgnlSrc"
											,StopdDt AS "DbtStopdItm/StopdDt"
											,StopdSts AS "DbtStopdItm/StopdSts"
											,DebitStoppedAmountCcy "DbtStopdItm/Amt/@Ccy"
											,DebitStoppedAmount AS "DbtStopdItm/Amt"							
											,BnfcryNm AS "DbtStopdItm/BnfcryNm"
											,StopItmStartRg AS "DbtStopdItm/StopItmStartRg"
											,StopItmEndRg AS "DbtStopdItm/StopItmEndRg"
										FROM 
											#ExtractDebit DB 
										WHERE 
											TX.TransactionSetIdWithVersion = DB.TransactionSetIdWithVersion 
										AND 
											DB.ItemId = TX.ItemId
										FOR XML PATH('DbtItm') ,TYPE
									)
							FROM 
								#ExtractTXSet TX
							FOR XML PATH('TxSet') ,TYPE
							)
					FOR XML PATH('ReqToPay') ,TYPE
					)
				FOR XML PATH('Document') ,TYPE
			)

		SET @FinalxmlResult = ( SELECT  1 AS Tag ,
										NULL AS Parent ,
										@FinalxmlResult AS [Document!1!!xmltext] ,
										@Namespace AS [Document!1!xmlns]
								FOR
								XML EXPLICIT
								);		
	IF (XACT_STATE()) = 1                                                                                                                                                                                                                                              
						BEGIN                                                                                                                                                                                                                                                               
						   COMMIT TRANSACTION;                                                                                                                                                                                                                                           
						END;
						END TRY
						BEGIN CATCH
							IF (XACT_STATE()) = -1                                                                                                                                                                                                                                              
							BEGIN                                                                                                                                                                                                                                                               
							   ROLLBACK TRANSACTION;                                                                                                                                                                                                                                           
							END;
						END CATCH
    END;
	
GO
GRANT EXECUTE ON [Agency].[usp_ReturnAgencyISOMSG06XML] TO AgencyISOMsgExtractor;
	
GO


EXECUTE sp_addextendedproperty @name = N'Component', @value = N'STAR',
    @level0type = N'SCHEMA', @level0name = N'Agency', @level1type = N'PROCEDURE',
    @level1name = N'usp_ReturnAgencyISOMSG06XML';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'This Stored Procedure extracts an XML in MSG06 ISO format for a given AgencyId.',
    @level0type = N'SCHEMA', @level0name = N'Agency', @level1type = N'PROCEDURE',
    @level1name = N'usp_ReturnAgencyISOMSG06XML';


GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)',
    @level0type = N'SCHEMA', @level0name = N'Agency', @level1type = N'PROCEDURE',
    @level1name = N'usp_ReturnAgencyISOMSG06XML';