CREATE PROCEDURE [Agency].[usp_ReturnAgencyISOMSG05XML]
	@EligibleISOMSG05Tsets		[Agency].[tv_ISOMSG05Tsets] READONLY,
	@TotalItemCount				INT,
	@FirstRec					INT,
	@LastRec					INT,
	@AgyReceiverId				VARCHAR(6),
	@AgyCollectingParticpantId	VARCHAR(6),
	@GrpHdrMsgIdSequence		BIGINT,
	@Namespace					VARCHAR(300),
	@FinalxmlResult				XML							OUTPUT
/*****************************************************************************************************
* Name				: [Agency].[usp_ReturnAgencyISOMSG05XML]]
* Description		: This Stored Procedure returns the XML for the AGY MSG05 ISO Extract 
* Type of Procedure : Interpreted stored procedure
* Author			: Pavan Kumar Manneru
* Creation Date		: 12/02/2017
*******************************************************************************************************/
AS
	BEGIN

		SET NOCOUNT ON;

		SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

		BEGIN TRY

			BEGIN TRAN;

			DECLARE @InputSignature VARBINARY(MAX)	= CONVERT(VARBINARY(MAX), 'Signature');
			DECLARE @EncodedSignature VARCHAR(MAX)	= CAST(N'' AS XML).value('xs:base64Binary(sql:variable("@InputSignature"))', 'VARCHAR(MAX)');

			SELECT
				TXSETS	.TransactionSetIdWithVersion,
				TXSETS.TxSetId, 
				[TXSETS].[TxSetVrsn],
				TXSETS.ColltngPtcptId,
				TXSETS.CaptrdDtTm,
				TXSETS.TxSetSubDtTm,
				[TXSETS].[Src],
				TXSETS.ColltngBrnchLctn,
				TXSETS.ColltngLctn,
				TXSETS.ChanlRskTp,
				TXSETS.ChanlDesc,
				TXSETS.ColltnPt,
				TXSETS.ColltngBrnchRef,
				TXSETS.NbOfItms,
				TXSETS.EndPtId
			INTO
				#ExtractTXSet
			FROM
				(
					SELECT
						ETSET.TransactionSetIdWithVersion,
						TX.TransactionSetId									AS TxSetId,
						RIGHT('00' + CAST(TX.[Version] AS VARCHAR(2)), 2) AS TxSetVrsn,
						TX.CollectingParticipantId							AS ColltngPtcptId,
						TX.CaptureDate										AS CaptrdDtTm,
						TX.TSetSubmissionDateTime							AS TxSetSubDtTm,
						RIGHT('0000' + CAST(TX.AltSource AS VARCHAR(4)), 4) AS Src,
						TX.CollectingBranchLocation							AS ColltngBrnchLctn,
						TX.CollectingLocation								AS ColltngLctn,
						TX.ChannelRiskType									AS ChanlRskTp,
						TX.ChannelDescription								AS ChanlDesc,
						TX.CollectionPoint									AS ColltnPt,
						TX.CollectionBranchRef								AS ColltngBrnchRef,
						TX.NumberOfItems									AS NbOfItms,
						TX.EndPointId										AS EndPtId,
						ROW_NUMBER() OVER (PARTITION BY
											TX.TransactionSetIdWithVersion
											ORDER BY
											TX.InternalTxId DESC
										)								AS RKD
					FROM
						@EligibleISOMSG05Tsets	AS ETSET
					INNER JOIN
						[Base].[vw_TXSet]		AS TX
					ON
						ETSET.TransactionSetIdWithVersion = TX.TransactionSetIdWithVersion
					INNER JOIN
						[Base].[Document]		AS DOC
					ON
						DOC.DocumentId = TX.DocumentId
					INNER JOIN
						[Base].[Core]			AS CO
					ON
						CO.XMLMessageId = DOC.XMLMessageId
					WHERE
						ETSET.TransactionSetRank > @FirstRec
					AND ETSET.TransactionSetRank <= @LastRec
					AND CO.IntMessageType = '05MA01'
				) AS TXSETS
			WHERE
				[TXSETS].[RKD] = 1;


			SELECT
				TransactionSetIdWithVersion,
				CdtItmId,
				CdtItmTp,
				CdtItmTxCd,
				[ECR].[OnUsItmInd],
				Amt,
				AmtCcy,
				[ECR].[BkCd],
				[ECR].[AcctNb],
				RefNb,
				Img,
				[ECR].[FrntImgQltyIndctnInd],
				[ECR].[BckImgQltyIndctnInd],
				[ECR].[ChqAtRskInd],
				BnfcryNm,
				[ECR].[VrtlCdtInd],
				RefData,
				CshAmt,
				CshAmtCcy,
				FnddAmt,
				FnddAmtCcy,
				NonFunddAmt,
				NonFunddAmtCcy,
				NbOfCdtsOrDbts,
				[ECR].[BkCdRprdInd],
				[ECR].[AcctNbRprdInd],
				[ECR].[AmtRprdInd],
				[ECR].[SrlNbRprdInd],
				[ECR].[RefNbRprdInd],
				[ECR].[BkCdDfltdInd],
				[ECR].[AcctNbDfltdInd],
				[ECR].[RefNbDfltdInd],
				[ECR].[SwitchedSortCode],
				[ECR].[SwitchedAccount]
			INTO
				#ExtractCredit
			FROM
				(
					SELECT
						ETSET.TransactionSetIdWithVersion,
						CR.CreditId															AS CdtItmId,
						ITMTYPE.ItemTypeCode												AS CdtItmTp,
						CR.TranCode															AS CdtItmTxCd,
						IIF(CR.OnUs = 1, 'true', 'false')								AS OnUsItmInd,
						CR.Amount															AS Amt,
						CCY.Currency														AS AmtCcy,
						RIGHT('000000' + CAST([CR].[Sortcode] AS VARCHAR(6)), 6) AS BkCd,
						RIGHT('00000000' + CAST([CR].[AccountNumber] AS VARCHAR(8)), 8)		AS AcctNb,
						CR.Reference														AS RefNb,
						--ItmImgData
						IMG.Image															AS Img,
						CASE
							WHEN IMG.FrontImageQuality = 1
							THEN 'true'
							WHEN IMG.FrontImageQuality = 0
							THEN 'false'
							ELSE NULL
						END																	AS FrntImgQltyIndctnInd,
						CASE
							WHEN IMG.RearImageQuality = 1
							THEN 'true'
							WHEN IMG.RearImageQuality = 0
							THEN 'false'
							ELSE NULL
						END																	AS BckImgQltyIndctnInd,
						--CdtItmFrdData
						CASE
							WHEN CRFRD.ChequeAtRisk = 1
							THEN 'true'
							WHEN CRFRD.ChequeAtRisk = 0
							THEN 'false'
							ELSE NULL
						END																	AS ChqAtRskInd,
						CRFRD.BeneficiaryName												AS BnfcryNm,
						IIF(CRFRD.VirtualCredit = 1, 'true', 'false')					AS VrtlCdtInd,
						CRFRD.ReferenceData													AS RefData,
						CRFRD.CashAmount													AS CshAmt,
						CRFRDCSHCCY.Currency												AS CshAmtCcy,
						CRFRD.FundedAmount													AS FnddAmt,
						CRFRDFNDCCY.Currency												AS FnddAmtCcy,
						CRFRD.NonFundedAmount												AS NonFunddAmt,
						CRFRDNFNDCCY.Currency												AS NonFunddAmtCcy,
						CRFRD.NumberOfItems													AS NbOfCdtsOrDbts,
						--RprdItm
						IIF(CR.RepairedSortcode = 1, 'true', 'false')					AS BkCdRprdInd,
						IIF(CR.RepairedAccount = 1, 'true', 'false')						AS AcctNbRprdInd,
						IIF(CR.RepairedAmount = 1, 'true', 'false')							AS AmtRprdInd,
						IIF(CR.RepairedSerial = 1, 'true', 'false')							AS SrlNbRprdInd,
						IIF(CR.RepairedReference = 1, 'true', 'false')		AS RefNbRprdInd,
						--DfltdItm
						IIF(CR.DefaultedSortcode = 1, 'true', 'false')		AS BkCdDfltdInd,
						IIF(CR.DefaultedAccount = 1, 'true', 'false')					AS AcctNbDfltdInd,
						IIF(CR.DefaultedReference = 1, 'true', 'false')						AS RefNbDfltdInd,
						--SwtchdItm
						RIGHT('000000' + CAST([CR].[SwitchedSortCode] AS VARCHAR(6)), 6) AS SwitchedSortCode,
						RIGHT('00000000' + CAST([CR].[SwitchedAccount] AS VARCHAR(8)), 8) AS SwitchedAccount,
						ROW_NUMBER() OVER (PARTITION BY
											CR.CreditId
											ORDER BY
											CR.ItemId DESC
										)												AS RKD
					FROM
						@EligibleISOMSG05Tsets	AS ETSET
					INNER JOIN
						(
							SELECT
								InternalTxId,
								INTX.TransactionSetIdWithVersion
							FROM
								@EligibleISOMSG05Tsets	AS ETSET
							INNER JOIN
								[Base].[vw_TXSet]		AS INTX
							ON
								ETSET.TransactionSetIdWithVersion = INTX.TransactionSetIdWithVersion
							GROUP BY
								InternalTxId,
								INTX.TransactionSetIdWithVersion
						)						AS TX
					ON
						ETSET.TransactionSetIdWithVersion = TX.TransactionSetIdWithVersion
					INNER JOIN
						Base.FinalCredit		AS FC
					ON
						FC.InternalTxId = TX.InternalTxId
					INNER JOIN
						Base.Credit				AS CR
					ON
						CR.CreditId = FC.CreditId
					INNER JOIN
						Base.ItemUpdate			AS IU
					ON
						IU.InternalId = CR.ItemId
					INNER JOIN
						Base.Core				AS CO
					ON
						CO.CoreId = IU.CoreID
					INNER JOIN
						Lookup.ItemType			AS ITMTYPE
					ON
						ITMTYPE.Id = CR.ItemType
					INNER JOIN
						Lookup.Currency			AS CCY
					ON
						CCY.Id = CR.Currency
					INNER JOIN
						Base.CreditFraudData	AS CRFRD
					ON
						CRFRD.ItemId = CR.ItemId
					LEFT JOIN
						Lookup.Currency			AS CRFRDCSHCCY
					ON
						CRFRDCSHCCY.Id = CRFRD.CashAmountCurrency
					LEFT JOIN
						Lookup.Currency			AS CRFRDFNDCCY
					ON
						CRFRDFNDCCY.Id = CRFRD.FundedAmountCurrency
					LEFT JOIN
						Lookup.Currency			AS CRFRDNFNDCCY
					ON
						CRFRDNFNDCCY.Id = CRFRD.NonFundedAmountCurrency
					LEFT JOIN
						Base.[Image]			AS IMG
					ON
						IMG.ItemId = CR.ItemId
					WHERE
						CO.IntMessageType = '05MA01'
				) AS ECR
			WHERE
				[ECR].[RKD] = 1;


			CREATE CLUSTERED INDEX ci_TransactionSetIdWithVersion
			ON #ExtractCredit (TransactionSetIdWithVersion);


			SELECT
				TransactionSetIdWithVersion,
				DbtItmId,
				DbtItmTp,
				[EDB].[DbtItmTxCd],
				[EDB].[RpresntdItmInd],
				[EDB].[OnUsItmInd],
				Amt,
				AmtCcy,
				[EDB].[BkCd],
				[EDB].[AcctNb],
				[EDB].[SrlNb],
				[EDB].[HghValItm],
				Img,
				[EDB].[FrntImgQltyIndctnInd],
				[EDB].[BckImgQltyIndctnInd],
				[EDB].[BkCdRprdInd],
				[EDB].[AcctNbRprdInd],
				[EDB].[AmtRprdInd],
				[EDB].[SrlNbRprdInd],
				[EDB].[RefNbRprdInd],
				[EDB].[BkCdDfltdInd],
				[EDB].[AcctNbDfltdInd],
				[EDB].[SrlNbDfltdInd],
				[EDB].[SwitchedSortCode],
				[EDB].[SwitchedAccount]
			INTO
				#ExtractDebit
			FROM
				(
					SELECT
						ETSET.TransactionSetIdWithVersion,
						DB.DebitId														AS DbtItmId,
						ITMTYPE.ItemTypeCode											AS DbtItmTp,
						IIF(LTRIM(RTRIM(DB.TranCode)) = '', NULL, DB.TranCode) AS DbtItmTxCd,
						IIF(DB.Represent = 1, 'true', 'false')			AS RpresntdItmInd,
						IIF(DB.OnUs = 1, 'true', 'false')							AS OnUsItmInd,
						DB.Amount														AS Amt,
						CCY.Currency													AS AmtCcy,
						RIGHT('000000' + CAST(DB.Sortcode AS VARCHAR(6)), 6) AS BkCd,
						RIGHT('00000000' + CAST(DB.AccountNumber AS VARCHAR(8)), 8)		AS AcctNb,
						RIGHT('000000' + CAST(DB.SerialNumber AS VARCHAR(6)), 6) AS SrlNb,
						IIF(DB.HighValue = 1, 'true', 'false')			AS HghValItm,
						--ItmImgData
						IMG.Image														AS Img,
						CASE
							WHEN IMG.FrontImageQuality = 1
							THEN 'true'
							WHEN IMG.FrontImageQuality = 0
							THEN 'false'
							ELSE NULL
						END																AS FrntImgQltyIndctnInd,
						CASE
							WHEN IMG.RearImageQuality = 1
							THEN 'true'
							WHEN IMG.RearImageQuality = 0
							THEN 'false'
							ELSE NULL
						END																AS BckImgQltyIndctnInd,
						--RprdItm
						IIF(DB.RepairedSortcode = 1, 'true', 'false')				AS BkCdRprdInd,
						IIF(DB.RepairedAccount = 1, 'true', 'false')					AS AcctNbRprdInd,
						IIF(DB.RepairedAmount = 1, 'true', 'false')						AS AmtRprdInd,
						IIF(DB.RepairedSerial = 1, 'true', 'false')						AS SrlNbRprdInd,
						IIF(DB.RepairedReference = 1, 'true', 'false')	AS RefNbRprdInd,
						--DfltdItm
						IIF(DB.DefaultedSortcode = 1, 'true', 'false')	AS BkCdDfltdInd,
						IIF(DB.DefaultedAccount = 1, 'true', 'false')				AS AcctNbDfltdInd,
						IIF(DB.DefaultedSerialNumber = 1, 'true', 'false') AS SrlNbDfltdInd,
						--SwtchdItm
						RIGHT('000000' + CAST(DB.SwitchedSortCode AS VARCHAR(6)), 6) AS SwitchedSortCode,
						RIGHT('00000000' + CAST(DB.SwitchedAccount AS VARCHAR(8)), 8) AS SwitchedAccount,
						ROW_NUMBER() OVER (PARTITION BY
											DB.DebitId
											ORDER BY
											DB.ItemId DESC
										)											AS RKD
					FROM
						@EligibleISOMSG05Tsets	AS ETSET
					INNER JOIN
						(
							SELECT
								InternalTxId,
								INTX.TransactionSetIdWithVersion
							FROM
								@EligibleISOMSG05Tsets	AS ETSET
							INNER JOIN
								[Base].[vw_TXSet]		AS INTX
							ON
								ETSET.TransactionSetIdWithVersion = INTX.TransactionSetIdWithVersion
							GROUP BY
								InternalTxId,
								INTX.TransactionSetIdWithVersion
						)						AS TX
					ON
						ETSET.TransactionSetIdWithVersion = TX.TransactionSetIdWithVersion
					INNER JOIN
						Base.FinalDebit			AS FD
					ON
						FD.InternalTxId = TX.InternalTxId
					INNER JOIN
						Base.Debit				AS DB
					ON
						DB.DebitId = FD.DebitId
					INNER JOIN
						Base.ItemUpdate			AS IU
					ON
						IU.InternalId = DB.ItemId
					INNER JOIN
						Base.Core				AS CO
					ON
						CO.CoreId = IU.CoreID
					INNER JOIN
						Lookup.ItemType			AS ITMTYPE
					ON
						ITMTYPE.Id = DB.ItemType
					INNER JOIN
						Lookup.Currency			AS CCY
					ON
						CCY.Id = DB.Currency
					LEFT JOIN
						Base.[Image]			AS IMG
					ON
						IMG.ItemId = DB.ItemId
					WHERE
						CO.IntMessageType = '05MA01'
				) AS EDB
			WHERE
				[EDB].[RKD] = 1;

			CREATE CLUSTERED INDEX ci_TransactionSetIdWithVersion
			ON #ExtractDebit (TransactionSetIdWithVersion);

			CREATE NONCLUSTERED INDEX nci_TransactionSetIdWithVersion
			ON #ExtractDebit (TransactionSetIdWithVersion, RKD)
			WHERE RKD = 1;
			WITH
				ExtractGrpHdr
			AS
				(
					SELECT
						CONCAT	(@AgyCollectingParticpantId, RIGHT(DATEPART(YEAR, GETDATE()), 2), RIGHT(CONCAT('000', DATEPART(DAYOFYEAR, GETDATE())), 3), 'C', ':', RIGHT(CONCAT('0000000000', @GrpHdrMsgIdSequence), 10)) AS MsgId,
						GETDATE()																																															AS CreDtTm,
						@AgyReceiverId																																														AS RcvrId,
						'false'																																																AS TstInd,
						@EncodedSignature																																													AS Sgntr
				)
			SELECT
				@FinalxmlResult =
						(
							SELECT
						(
							SELECT
						(
							SELECT
								[ExtractGrpHdr].[MsgId],
								[ExtractGrpHdr].[CreDtTm],
								[CNTTXN].[NumberofTransactions] AS NbOfTxs,
								[ExtractGrpHdr].[RcvrId],
								[ExtractGrpHdr].[TstInd],
								[ExtractGrpHdr].[Sgntr]
							FROM
								ExtractGrpHdr
							CROSS JOIN
								(
									SELECT
										COUNT(1)	AS NumberofTransactions
									FROM
										#ExtractTXSet
								)	AS CNTTXN
							FOR XML PATH('GrpHdr'), TYPE
						)	,
						(
							SELECT
								TxSetId,
								[TX].[TxSetVrsn],
								ColltngPtcptId,
								CaptrdDtTm,
								TxSetSubDtTm,
								[TX].[Src],
								ColltngBrnchLctn,
								ColltngLctn,
								ChanlRskTp,
								ChanlDesc,
								ColltnPt,
								ColltngBrnchRef,
								NbOfItms,
								EndPtId,
						(
							SELECT
								CdtItmId,
								CdtItmTp,
								CdtItmTxCd,
								[CR].[OnUsItmInd],
								AmtCcy												AS "Amt/@Ccy",
								Amt,
								[CR].[BkCd],
								[CR].[AcctNb],
								RefNb,
								Img													AS "ItmImgData/Img",
								[CR].[FrntImgQltyIndctnInd]							AS "ItmImgData/FrntImgQltyIndctnInd",
								[CR].[BckImgQltyIndctnInd]							AS "ItmImgData/BckImgQltyIndctnInd",
								[CR].[ChqAtRskInd]									AS "CdtItmFrdData/ChqAtRskInd",
								BnfcryNm											AS "CdtItmFrdData/BnfcryNm",
								[CR].[VrtlCdtInd]									AS "CdtItmFrdData/VrtlCdtInd",
								RefData												AS "CdtItmFrdData/RefData",
								IIF(CshAmt IS NOT NULL, CshAmtCcy, NULL)			AS "CdtItmFrdData/CshAmt/@Ccy",
								CshAmt												AS "CdtItmFrdData/CshAmt",
								IIF(FnddAmt IS NOT NULL, FnddAmtCcy, NULL)			AS "CdtItmFrdData/FnddAmt/@Ccy",
								FnddAmt												AS "CdtItmFrdData/FnddAmt",
								IIF(NonFunddAmt IS NOT NULL, NonFunddAmtCcy, NULL)	AS "CdtItmFrdData/NonFunddAmt/@Ccy",
								NonFunddAmt											AS "CdtItmFrdData/NonFunddAmt",
								NbOfCdtsOrDbts										AS "CdtItmFrdData/NbOfCdtsOrDbts",
								[CR].[BkCdRprdInd]									AS "RprdItm/BkCdRprdInd",
								[CR].[AcctNbRprdInd]								AS "RprdItm/AcctNbRprdInd",
								[CR].[AmtRprdInd]									AS "RprdItm/AmtRprdInd",
								[CR].[SrlNbRprdInd]									AS "RprdItm/SrlNbRprdInd",
								[CR].[RefNbRprdInd]									AS "RprdItm/RefNbRprdInd",
								[CR].[BkCdDfltdInd]									AS "DfltdItm/BkCdDfltdInd",
								[CR].[AcctNbDfltdInd]								AS "DfltdItm/AcctNbDfltdInd",
								[CR].[RefNbDfltdInd]								AS "DfltdItm/RefNbDfltdInd",
								[CR].[SwitchedSortCode]								AS "SwtchdItm/BkCd",
								[CR].[SwitchedAccount]								AS "SwtchdItm/AcctNb"
							FROM
								#ExtractCredit AS CR
							WHERE
								TX.TransactionSetIdWithVersion = CR.TransactionSetIdWithVersion
							FOR XML PATH('CrdtItm'), TYPE
						)	,
						(
							SELECT
								DbtItmId,
								DbtItmTp,
								[DB].[DbtItmTxCd],
								[DB].[RpresntdItmInd],
								[DB].[OnUsItmInd],
								AmtCcy						AS "Amt/@Ccy",
								Amt,
								[DB].[BkCd],
								[DB].[AcctNb],
								[DB].[SrlNb],
								[DB].[HghValItm],
								Img							AS "ItmImgData/Img",
								[DB].[FrntImgQltyIndctnInd] AS "ItmImgData/FrntImgQltyIndctnInd",
								[DB].[BckImgQltyIndctnInd]	AS "ItmImgData/BckImgQltyIndctnInd",
								[DB].[BkCdRprdInd]			AS "RprdItm/BkCdRprdInd",
								[DB].[AcctNbRprdInd]		AS "RprdItm/AcctNbRprdInd",
								[DB].[AmtRprdInd]			AS "RprdItm/AmtRprdInd",
								[DB].[SrlNbRprdInd]			AS "RprdItm/SrlNbRprdInd",
								[DB].[RefNbRprdInd]			AS "RprdItm/RefNbRprdInd",
								[DB].[BkCdDfltdInd]			AS "DfltdItm/BkCdDfltdInd",
								[DB].[AcctNbDfltdInd]		AS "DfltdItm/AcctNbDfltdInd",
								[DB].[SrlNbDfltdInd]		AS "DfltdItm/SrlNbDfltdInd",
								[DB].[SwitchedSortCode]		AS "SwtchdItm/BkCd",
								[DB].[SwitchedAccount]		AS "SwtchdItm/AcctNb"
							FROM
								#ExtractDebit AS DB
							WHERE
								TX.TransactionSetIdWithVersion = DB.TransactionSetIdWithVersion
							FOR XML PATH('DbtItm'), TYPE
						)
							FROM
								#ExtractTXSet AS TX
							FOR XML PATH('TxSet'), TYPE
						)
							FOR XML PATH('BnfcryTxSetEarlyNtfctn'), TYPE
						)
							FOR XML PATH('Document'), TYPE
						);

			SET @FinalxmlResult =
				(
					SELECT
						1				AS Tag,
						NULL			AS Parent,
						@FinalxmlResult AS [Document!1!!xmltext],
						@Namespace		AS [Document!1!xmlns]
					FOR XML EXPLICIT
				);

			IF (XACT_STATE()) = 1
				BEGIN
					COMMIT	TRANSACTION;
				END;
		END TRY
		BEGIN CATCH
			IF (XACT_STATE()) = -1
				BEGIN
					ROLLBACK TRANSACTION;
				END;
		END CATCH;
	END;

GO
GRANT
	EXECUTE
ON [Agency].[usp_ReturnAgencyISOMSG05XML]
TO
	AgencyISOMsgExtractor;

GO


EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'STAR',
	@level0type = N'SCHEMA',
	@level0name = N'Agency',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReturnAgencyISOMSG05XML';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This Stored Procedure extracts an XML in MSG05 ISO format for a given AgencyId.',
	@level0type = N'SCHEMA',
	@level0name = N'Agency',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReturnAgencyISOMSG05XML';


GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'Agency',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_ReturnAgencyISOMSG05XML';