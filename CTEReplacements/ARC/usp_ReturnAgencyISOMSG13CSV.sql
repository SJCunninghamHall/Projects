CREATE PROCEDURE [Agency].[usp_ReturnAgencyISOMSG13CSV]
	 @AgencyId INT
	,@CurrentBusinessDate DATE
	,@PreviousBusinessDate DATE
	,@FileName VARCHAR(200)
	,@TotalItemCount INT OUTPUT

/*****************************************************************************************************
* Name				: [Agency].[usp_ReturnAgencyISOMSG13CSV]
* Description		: This Stored Procedure returns the MSG13 Items in CSV format for a given AgencyId
* Type of Procedure : Interpreted stored procedure
* Author			: Nageswara Rao
* Creation Date		: 16/06/2018
*******************************************************************************************************/
AS
    BEGIN

		SET NOCOUNT ON;

		SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

		BEGIN TRY
		
			BEGIN TRAN

				--To derive the business date range for retrieving items from the FinalCredit table
				DECLARE @PrevBusinessDateFrom BIGINT
				DECLARE @PrevBusinessDateTo BIGINT
				--Table varible to calculate the number of TSets available for extraction for a given AgencyId
				DECLARE @HeaderBusinessDate VARCHAR(10);
				DECLARE @NumPaid INT;
				DECLARE @ValuePaid NUMERIC(13, 2);
				DECLARE @NumNoPay INT;
				DECLARE @ValueNoPay NUMERIC(13, 2);
				DECLARE @ItemsCount INT;
				DECLARE @CredItemsCount INT;
				DECLARE @DebItemsCount INT;
					
				SET @PrevBusinessDateFrom			= Base.cfn_Convert_Date_StartRangeKey(@PreviousBusinessDate)
				SET @PrevBusinessDateTo				= Base.cfn_Convert_Date_EndRangeKey(@PreviousBusinessDate)
				SET @HeaderBusinessDate				= FORMAT(@CurrentBusinessDate, 'yyyyMMdd')

				CREATE TABLE #EligibleItemIds
				(
					[TransactionSetIdWithVersion] [varchar](25) NULL,
					[TransactionSetId]			  [varchar](25) NULL,
					[CreditId] [varchar](25) NULL,			
					[CreditAmount] NUMERIC(20,2) NULL,
					[CreditIcsAmount] NUMERIC(20,2) NULL,
					[CreditItemType] [tinyint] NULL,
					[CreditFinalClearingState] [int] NULL,
					[DebitId] [varchar](25) NULL,
					[DebitAmount] NUMERIC(20,2) NULL,
					[DebitIcsAmount] NUMERIC(20,2) NULL,
					[DebitItemType]  [tinyint] NULL,
					[DebitFinalClearingState] [int] NULL,
					[DebitPayDecision] BIT NULL,
					[InternalTxId] [bigint] NULL,
					[Version] [tinyint] NULL,
					[CollectingParticipantId] [varchar](6) NULL,
					[CaptureDate] [datetime2](2) NULL,
					[TSetSubmissionDateTime] [datetime2](2) NULL,
					[DocumentCreatedDate] [datetime2](3) NULL,
					[AltSource] [smallint] NULL,
					[EndPointId] [varchar](6) NULL,
					[ChannelRiskType] [varchar](4) NULL,
				)

				CREATE TABLE #EligibleISOMSG13Tsets
				(
					[TransactionSetIdWithVersion] [varchar](24) NULL,
					[TransactionSetId] [varchar](22) NULL,
					[InternalTxId] [bigint] NULL,
					[Version] [tinyint] NULL,
					[CollectingParticipantId] [varchar](6) NULL,
					[CaptureDate] [datetime2](2) NULL,
					[TSetSubmissionDateTime] [datetime2](2) NULL,
					[DocumentCreatedDate] [datetime2](3) NULL,
					[AltSource] [smallint] NULL,
					[EndPointId] [varchar](6) NULL,
					[ChannelRiskType] [varchar](4) NULL,		
					[SubmittedPaidITPAmount] NUMERIC(20,2) NULL,
					[NotSubmittedPaidITPAmount] NUMERIC(20,2) NULL,
					[SubmittedPaidRtpDebitAmount] NUMERIC(20,2) NULL,
					[SubmittedRtpDebitAmount] NUMERIC(20,2) NULL,
					[SubmittedItpDebitAmount] NUMERIC(20,2) NULL
				)

				INSERT INTO #EligibleItemIds
				(
					[TransactionSetIdWithVersion],
					[TransactionSetId],
					InternalTxId
					,[Version]	
					,CollectingParticipantId
					,CaptureDate
					,TSetSubmissionDateTime
					,DocumentCreatedDate
					,AltSource
					,EndPointId
					,ChannelRiskType
					,[CreditId],
					[CreditAmount],
					[CreditIcsAmount],
					[CreditItemType],
					[CreditFinalClearingState],
					[DebitId],
					[DebitAmount]	,
					[DebitIcsAmount],
					[DebitItemType],
					[DebitFinalClearingState],
					[DebitPayDecision]
				)
				SELECT
					TransactionSetIdWithVersion,
					TransactionSetId,
					InternalTxId
					,[Version]	
					,CollectingParticipantId
					,CaptureDate
					,TSetSubmissionDateTime
					,CreatedDate
					,AltSource
					,EndPointId
					,ChannelRiskType
					
					,CreditId,			
					CreditAmount,
					CreditIcsAmount,
					CreditItemType,
					CreditFinalClearingState,			
					
					DebitId	,
					DebitAmount	,
					DebitIcsAmount,
					DebitItemType,
					DebitFinalClearingState,
					DebitPayDecision	
				FROM 
				(
					SELECT	  
						RemoveDuplicate = ROW_NUMBER() OVER(PARTITION BY Tx.TransactionSetId,FC.CreditId, FD.DebitId ORDER BY Tx.InternalTxId, FD.ItemId,FC.ItemId)
						,TransactionSetIdWithVersion = TX.TransactionSetIdWithVersion,
						TransactionSetId = Tx.TransactionSetId,				
						InternalTxId = Tx.InternalTxId,
						[Version] = Tx.Version,
						CollectingParticipantId = Tx.CollectingParticipantId,
						CaptureDate = Tx.CaptureDate,
						TSetSubmissionDateTime = Tx.TSetSubmissionDateTime,
						AltSource = Tx.AltSource,
						EndPointId = Tx.EndPointId,
						ChannelRiskType = Tx.ChannelRiskType,
						CreatedDate = doc.CreatedDate,
						
						CreditId = FC.CreditId,
						CreditAmount = FC.Amount,
						CreditIcsAmount = FC.ICSAmount,
						CreditItemType = FC.ItemType,
						CreditFinalClearingState = FC.FinalClearingState,				
						
						DebitId = FD.DebitId,
						DebitAmount = FD.Amount,
						DebitIcsAmount = FD.ICSAmount,
						DebitItemType = FD.ItemType,
						DebitFinalClearingState = FD.FinalClearingState,
						DebitPayDecision		= FD.PayDecision
						,FC.[AgencyBeneficiaryParticipantId]
					FROM 
						Base.TXSet Tx
					INNER JOIN 
						Base.Document Doc 
					ON 
						Doc.DocumentId = Tx.DocumentId
					INNER JOIN 
						Base.Core Cr WITH (SNAPSHOT)
					ON 
						Cr.XMLMessageId = Doc.XMLMessageId   
					AND 
						Cr.IntMessageType IN ('01MA01', '05MA01')
					INNER JOIN 
						Base.FinalDebit FD WITH (SNAPSHOT)
					ON 
						FD.TransactionSetId = Tx.TransactionSetId
					INNER JOIN 
						Base.FinalCredit FC WITH (SNAPSHOT)
					ON 
						FC.TransactionSetId = FD.TransactionSetId
					WHERE
					( 
						FC.[AgencyBeneficiaryParticipantId] = @AgencyId
						AND 
						(
							--Tset Received PrevBusiness Day
							(
								Tx.InternaltxId BETWEEN @PrevBusinessDateFrom AND @PrevBusinessDateTo
								AND
								(
									--Not Bank Holiday and MSG 13 received
									(FD.FinalClearingState BETWEEN 200 AND 500)
									--Settled yesterday
									OR 
									(
										FD.FinalClearingState = 82 
										AND FD.ItemType = 4 
										AND FC.Cf_OnBank <> 0
									)
								)
							)
							--bank holiday previously and MSG 13 received today
							OR 
							(
								(
									CAST(Day2ResponseWindowStartDateTime AS DATE) = @CurrentBusinessDate
								)
									OR
								(
									DATEDIFF(DD,@CurrentBusinessDate,FD.Day2ResponseWindowStartDateTime)>0 
										AND 
									FD.FinalclearingState IN (210,211) 
										AND 
									CAST(LEFT(Tx.InternalTxId,8) AS DATE) <> @CurrentBusinessDate
								)
							)
						)
						--Debit not rejected
						AND FD.FinalClearingState NOT IN (SELECT [EntityState] FROM [ReferenceData].[EntityExtractFilter] WHERE [FilterKey] IN ('AGYDBT','AGYAPGREJDWNLD'))
						--Credit not rejected
						AND FC.FinalClearingState NOT IN (SELECT [EntityState] FROM [ReferenceData].[EntityExtractFilter] WHERE [FilterKey] IN ('AGYDBT','AGYAPGREJDWNLD'))
						
					)
				) EligibleTransactionSets 	
				WHERE 
					EligibleTransactionSets.RemoveDuplicate = 1


	CREATE NONCLUSTERED INDEX IDX_EligibleItemIds ON #EligibleItemIds([TransactionSetIdWithVersion]) INCLUDE([CreditId],[DebitId])

	CREATE NONCLUSTERED INDEX IDX_EligibleItemIdsTsetId ON #EligibleItemIds([TransactionSetId]) INCLUDE([CreditId],[DebitId])
	
	IF EXISTS(SELECT TOP(1) 1 FROM #EligibleItemIds)
	BEGIN
		SET @TotalItemCount = 1
	END
	ELSE
	BEGIN
		SET @TotalItemCount = 0
	END

	IF (@TotalItemCount = 0)
	BEGIN
		SELECT Result.RowValue
		  FROM (
				 SELECT RowValue = 'Filename,Date,FileVolume,CreditVolume,DebitVolume,NumPaid,ValuePaid,NumNoPay,ValueNoPay' + REPLICATE(',', 23)
					  , 1 AS RNO
                  UNION ALL
                 SELECT RowValue = @FileName + ','
                        + @HeaderBusinessDate + ','
                        + RIGHT('00000' + CONVERT(VARCHAR, ISNULL(@ItemsCount, 0)),5) + ','
						+ RIGHT('00000' + CONVERT(VARCHAR, ISNULL(@CredItemsCount, 0)),5) + ','
						+ RIGHT('00000' + CONVERT(VARCHAR, ISNULL(@DebItemsCount, 0)),5) + ','
                        + RIGHT('00000' + CONVERT(VARCHAR, ISNULL(@NumPaid, 0)),5) + ','
                        + CONVERT(VARCHAR, ISNULL(@ValuePaid, 0.00)) + ','
                        + RIGHT('00000' + CONVERT(VARCHAR, ISNULL(@NumNoPay, 0)),5) + ','
                        + CONVERT(VARCHAR, ISNULL(@ValueNoPay, 0.00))
                        + REPLICATE(',', 23) ,
                        2 AS RNO
                  UNION ALL
                 SELECT RowValue = REPLICATE(',', 31) ,
                        3 AS RNO
                  UNION ALL
                 SELECT RowValue = 'T-Set Id,Collecting Participant ID,Collecting Channel,Item Id,Gender,Item Type,Transaction Code,Cheque Risk Indicator,Reference/serial,Sort code,Account,Beneficiary Name,Amount,Paid Amount,Decision,No Pay Reason Code,Fraud Reason Code,No Pay Reason Description,Virtual Credit Indicator,Cash Amount,Funded Amount,Non Funded Amount,Sort Code Repaired Indicator,Account No Repaired Indicator,Amount Repaired Indicator,Reference Number Repaired Indicator,Default Sort Code Indicator,Default Account Number Indicator,Default Reference Number Indicator,Original Sort Code (Switched Account),Original Account Number (Switched Account)' ,
                        4 AS RNO
                  UNION ALL
                 SELECT RowValue = 'No Data Available',
                        5 AS RNO
               ) AS Result
		 ORDER BY Result.RNO;
	END;
	ELSE 
	BEGIN
		INSERT INTO #EligibleISOMSG13Tsets
		(
			[TransactionSetIdWithVersion],
			[TransactionSetId] ,
			[InternalTxId] ,
			[Version] ,
			[CollectingParticipantId] ,
			[CaptureDate],
			[TSetSubmissionDateTime] ,
			[DocumentCreatedDate],
			[AltSource] ,
			[EndPointId],
			[ChannelRiskType] ,	
			[NotSubmittedPaidITPAmount],	
			[SubmittedPaidITPAmount] ,
			[SubmittedPaidRtpDebitAmount] ,
			[SubmittedRtpDebitAmount] ,
			[SubmittedItpDebitAmount]
		)
		SELECT 
			TransactionSetIdWithVersion			= EligibleTransactionSets.TransactionSetIdWithVersion,
			TransactionSetId					= EligibleTransactionSets.TransactionSetId,
			InternalTxId						= EligibleTransactionSets.InternalTxId,
			[Version]							= EligibleTransactionSets.[Version],
			CollectingParticipantId				= EligibleTransactionSets.CollectingParticipantId,
			CaptureDate							= EligibleTransactionSets.CaptureDate,
			TSetSubmissionDateTime				= EligibleTransactionSets.TSetSubmissionDateTime,
			DocumentCreatedDate					= EligibleTransactionSets.DocumentCreatedDate,
			AltSource							= EligibleTransactionSets.AltSource,						
			EndPointId							= EligibleTransactionSets.EndPointId,
			ChannelRiskType						= EligibleTransactionSets.ChannelRiskType,
			NotSubmittedPaidITPAmount			= ISNULL(EligibleTransactionSets.NotSubmittedPaidITPAmount,0.00),
			SubmittedPaidITPAmount				= ISNULL(EligibleTransactionSets.SubmittedPaidITPAmount,0.00),
			SubmittedPaidRtpDebitAmount			= ISNULL(EligibleTransactionSets.SubmittedPaidRtpDebitAmount,0.00),
			SubmittedRtpDebitAmount				= ISNULL(EligibleTransactionSets.SubmittedRtpDebitAmount,0.00),
			SubmittedItpDebitAmount				= ISNULL(EligibleTransactionSets.SubmittedItpDebitAmount,0.00)
			
		FROM
		(
			SELECT	 
				TransactionSetIdWithVersion		= Itms.TransactionSetIdWithVersion,
				TransactionSetId				= Itms.TransactionSetId,
				InternalTxId					= Itms.InternalTxId, 
				[Version]						= Itms.[Version],
				CollectingParticipantId			= Itms.CollectingParticipantId,
				CaptureDate						= Itms.CaptureDate,
				TSetSubmissionDateTime			= Itms.TSetSubmissionDateTime,
				DocumentCreatedDate				= Itms.DocumentCreatedDate,
				AltSource						= Itms.AltSource,						
				EndPointId						= Itms.EndPointId,
				ChannelRiskType					= Itms.ChannelRiskType,
				GetFirstAudit					= ROW_NUMBER() OVER(PARTITION BY Itms.TransactionSetId
														ORDER BY Itms.[Version] DESC, Itms.InternalTxId ASC),
				NotSubmittedPaidITPAmount		= SUM(
														CASE WHEN (Itms.DebitItemType= 4 AND Itms.DebitFinalClearingState =82) 
														THEN Itms.DebitAmount 
														ELSE 0.00 END
													  ) OVER(PARTITION BY Itms.TransactionSetId),

				SubmittedPaidITPAmount			= SUM(
														 CASE WHEN (Itms.DebitItemType= 4 AND Itms.DebitFinalClearingState !=82 AND ISNULL(Itms.DebitPayDecision,1) = 1) 
														 AND (Itms.DebitFinalClearingState BETWEEN 200 AND 500)  
														 THEN Itms.DebitAmount 
														 ELSE 0.00 END
													  ) OVER(PARTITION BY Itms.TransactionSetId),
				SubmittedPaidRtpDebitAmount		=  SUM(
														CASE WHEN Itms.DebitItemType= 5 AND Itms.DebitPayDecision = 1  AND (Itms.DebitFinalClearingState BETWEEN 200 AND 500) 
															THEN Itms.DebitAmount 
															ELSE 0.00 END
													  ) OVER(PARTITION BY Itms.TransactionSetId),
				SubmittedRtpDebitAmount			= SUM(
														 CASE WHEN Itms.DebitItemType= 5 AND Itms.DebitFinalClearingState NOT IN (30,60,130) 
														 THEN Itms.DebitAmount 
														 ELSE 0.00 END
													  ) OVER(PARTITION BY Itms.TransactionSetId),
				SubmitteditpDebitAmount			= SUM(
														 CASE WHEN Itms.DebitItemType= 4 AND Itms.DebitFinalClearingState NOT IN (30,60,130) 
														 THEN Itms.DebitAmount 
														 ELSE 0.00 END
													  ) OVER(PARTITION BY Itms.TransactionSetId)
			
			FROM #EligibleItemIds Itms 
		) EligibleTransactionSets 	
		WHERE EligibleTransactionSets.GetFirstAudit = 1
		
		CREATE NONCLUSTERED INDEX 
			IDX_EligibleISOMSG13Tsets 
		ON 
			#EligibleISOMSG13Tsets([TransactionSetIdWithVersion]) 
		INCLUDE
			(TransactionSetId,[Version],CollectingParticipantId,ChannelRiskType)


		-- ;WITH EligibleItems
			-- AS
			-- (

		SELECT	
			ETSET.TransactionSetIdWithVersion
			,TX.TransactionSetId	AS	[T-Set Id] 
			,RIGHT('00' + cast(TX.[Version] as varchar(2)),2) AS TxSetVrsn
			,TX.CollectingParticipantId AS [Collecting Participant ID]
			,TX.ChannelRiskType AS [Collecting Channel]
			,FD.DebitId AS [Item Id]
			,'DEBIT' AS [Gender]
			,ITMTYPE.ItemTypeCode AS [Item Type]
			,FD.TranCode AS [Transaction Code]
			,NULL AS [Cheque Risk Indicator]
			,RIGHT('000000' + CAST(FD.Serial as varchar(6)),6) AS [Reference/serial]
			,RIGHT('000000' + CAST(FD.Sortcode as varchar(6)),6) AS [Sort code]
			,RIGHT('00000000' + CAST(FD.AccountNumber as varchar(8)),8) AS [Account]
			,'' AS [Beneficiary Name]
			,FD.Amount AS [Amount]
			,CAST(NULL AS NUMERIC(20,2)) [Paid Amount]
			,CASE 
				WHEN 
						(
							FD.[PayDecision] = 1 
						AND 
							FD.FinalclearingState BETWEEN 200 AND 500
						)
					OR 
						(
							FD.ItemType= 4 
						AND 
							FD.FinalClearingState = 82
						) 
					OR 
						(
							FD.ItemType=4 
						AND 
							FD.FinalClearingState != 82 
						AND 
							FD.FinalClearingState BETWEEN 200 AND 500 
						AND 
							ISNULL(FD.[PayDecision],1)=1
						) 
				THEN 
					'Pay'

				WHEN 
						FD.[PayDecision] = 0 
					AND 
						FD.FinalclearingState BETWEEN 200 AND 500 
				THEN 
					'NoPay'
				WHEN 
					FD.FinalclearingState IN (210,211) 
				THEN 
					'Local Bank Holiday'
				WHEN 
					En.EntityIdentifier IS NOT NULL 
				THEN 
					'HoldOver'
				ELSE 
					''
			END AS [Decision]
			,[FD].[PayReason] AS [No Pay Reason Code]
			,FraudData.FraudReason AS [Fraud Reason Code]
			,NoPay.ReasonDescription AS [No Pay Reason Description] 
			,NULL AS [Virtual Credit Indicator]
			,NULL AS [Cash Amount]
			,NULL AS [Funded Amount]
			,NULL AS [Non Funded Amount]
			,IIF(FD.RepairedSortcode = 1, 'true', 'false') AS [Sort Code Repaired Indicator]
			,IIF(FD.RepairedAccount = 1, 'true', 'false') AS [Account No Repaired Indicator]
			,IIF(FD.RepairedAmount = 1, 'true', 'false') AS [Amount Repaired Indicator] 
			,IIF(FD.RepairedSerial = 1, 'true', 'false') AS [Reference Number Repaired Indicator] 
			,IIF(FD.DefaultedSortcode = 1, 'true', 'false') AS [Default Sort Code Indicator]
			,IIF(FD.DefaultedAccount = 1, 'true', 'false') AS [Default Account Number Indicator] 
			,IIF(FD.DefaultedSerialNumber = 1, 'true', 'false') AS [Default Reference Number Indicator]
			,RIGHT('000000' + cast(FD.SwitchedSortCode as varchar(6)),6) AS [Original Sort Code (Switched Account)]
			,RIGHT('00000000' + cast(FD.SwitchedAccount as varchar(8)),8) AS [Original Account Number (Switched Account)]
			,RKD 
				= ROW_NUMBER() OVER(PARTITION BY 
									 ETSET.TransactionSetIdWithVersion
									 ,FD.TSetIDWithVersion 
									 ,ETSET.DebitId
									 ,FD.DebitId
									ORDER BY 
									 FD.ItemId DESC
									) 
		INTO
			#EligibleItems EligibleItems 
		FROM
			#EligibleItemIds ETSET
		INNER JOIN 
			Base.FinalDebit FD WITH (SNAPSHOT)
		ON 
			ETSET.TransactionSetId = FD.TransactionSetId 
		AND 
			FD.DebitId=ETSET.DebitId 
		INNER JOIN 
			#EligibleISOMSG13Tsets TX 
		ON 
			ETSET.TransactionSetId = TX.TransactionSetId				
		LEFT JOIN 
			Lookup.ItemType ITMTYPE WITH (SNAPSHOT)
		ON 
			ITMTYPE.Id = FD.ItemType
		LEFT JOIN 
			ReferenceData.RepresentableConfig NoPay WITH (SNAPSHOT)
		ON 
			FD.PayReason=NoPay.ReasonCode		
		LEFT JOIN 
			Base.Entity En WITH (SNAPSHOT) 
		ON 
			ETSET.DebitId = En.EntityIdentifier 
		AND 
			En.EntityState= 165 
		AND 
			En.EntityId BETWEEN @PrevBusinessDateFrom AND @PrevBusinessDateTo
		LEFT JOIN  
			(
				SELECT 
					FSR.TransactionSetId
					, FSR.ItemId
					, FSR.FraudReason
					, Msg.MessageType
				FROM 
					Base.FraudStatusResults FSR WITH (SNAPSHOT)
				INNER JOIN 
					Base.FraudStatus FS WITH (SNAPSHOT) 
				ON 
					FSR.FraudStatusId = FS.FraudStatusId
				INNER JOIN 
					Base.Core c  WITH (SNAPSHOT) 
				ON 
					FS.CoreId = c.CoreId
				INNER JOIN 
					Lookup.MessageType Msg WITH (SNAPSHOT) 
				ON 
					Msg.MessageId = C.MessageType
				WHERE 
					Msg.MessageType = 'MSG13'
			) FraudData 
		ON 
			FraudData.TransactionSetId = FD.TSetIDWithVersion 
		AND 
			FD.DebitId = FraudData.ItemId

		UNION ALL

			SELECT	 
				ETSET.TransactionSetIdWithVersion
				,TX.TransactionSetId	AS	[T-Set Id] 
				,RIGHT('00' + cast(TX.[Version] as varchar(2)),2) AS TxSetVrsn
				,TX.CollectingParticipantId AS [Collecting Participant ID]
				,TX.ChannelRiskType AS [Collecting Channel]
				,FC.CreditId AS [Item Id]
				,'CREDIT' AS [Gender]
				,ITMTYPE.ItemTypeCode AS [Item Type]
				,FC.TranCode AS [Transaction Code]
				,CrdFrdData.ChequeAtRisk AS [Cheque Risk Indicator]
				,FC.[Reference] AS [Reference/serial]
				,RIGHT('000000' + cast(FC.Sortcode as varchar(6)),6) AS [Sort code]
				,RIGHT('00000000' + cast(FC.AccountNumber as varchar(8)),8) AS [Account]
				,CrdFrdData.BeneficiaryName AS [Beneficiary Name],
										
				-- IF not Submitted to Switch
				CASE 
					WHEN 
						FC.FinalclearingState < 90 
					THEN 
						CASE 
							WHEN 
									FC.ICSAmount IS NULL 
								OR 
									fc.amount < (ISNULL(FC.ICSAmount,0.00)+TX.NotSubmittedPaidITPAmount) 
							THEN 
								fc.amount
							ELSE  
								ISNULL(FC.ICSAmount,0.00)+TX.NotSubmittedPaidITPAmount 
						END
					ELSE
						-- Submitted to Switch
						ISNULL(FC.ICSAmount,0.00)+TX.NotSubmittedPaidITPAmount
				END AS [Amount]

				, ISNULL
					(
						IIF
							(
								CASE 
									WHEN 
										FC.FinalclearingState < 90 
									THEN 
										CASE 
											WHEN 
													FC.ICSAmount IS NULL 
												OR 
													FC.amount < (ISNULL(FC.ICSAmount,0.00)+TX.NotSubmittedPaidITPAmount) 
											THEN 
												FC.amount
											ELSE  
												ISNULL(FC.ICSAmount,0.00)+TX.NotSubmittedPaidITPAmount 
										END
								ELSE										
									ISNULL(FC.ICSAmount,0.00)+TX.NotSubmittedPaidITPAmount
								END
									<
								(TX.NotSubmittedPaidITPAmount+TX.SubmittedPaidITPAmount+ TX.SubmittedPaidRtpDebitAmount)
								,
								CASE WHEN FC.FinalclearingState < 90 
								THEN 
									CASE WHEN FC.ICSAmount IS NULL OR FC.amount < (ISNULL(FC.ICSAmount,0.00)+TX.NotSubmittedPaidITPAmount) 
										THEN FC.amount
									ELSE  
										ISNULL(FC.ICSAmount,0.00)+TX.NotSubmittedPaidITPAmount 
									END
								ELSE										
								ISNULL(FC.ICSAmount,0.00)+TX.NotSubmittedPaidITPAmount
								END
								,(TX.NotSubmittedPaidITPAmount+TX.SubmittedPaidITPAmount+ TX.SubmittedPaidRtpDebitAmount)
							)
						,0.00
					)
				  AS [Paid Amount]
				,NULL AS [Decision]
				,NULL AS [No Pay Reason Code]
				,NULL AS [Fraud Reason Code]
				,NULL AS [No Pay Reason Description] 
				,CrdFrdData.VirtualCredit AS [Virtual Credit Indicator]
				,IIF(CrdFrdData.CashAmount > FC.Amount, FC.Amount, CrdFrdData.CashAmount) AS [Cash Amount]
				,IIF(TX.SubmittedItpDebitAmount > FC.Amount, FC.Amount, TX.SubmittedItpDebitAmount) AS [Funded Amount]
				,IIF(TX.SubmittedRtpDebitAmount > FC.Amount, FC.Amount, TX.SubmittedRtpDebitAmount) AS [Non Funded Amount]
				,IIF(FC.RepairedSortcode = 1, 'true', 'false') AS [Sort Code Repaired Indicator]
				,IIF(FC.RepairedAccount = 1, 'true', 'false') AS [Account No Repaired Indicator]
				,IIF(FC.RepairedAmount = 1, 'true', 'false') AS [Amount Repaired Indicator] 
				,IIF(FC.RepairedReference = 1, 'true', 'false') AS [Reference Number Repaired Indicator] 
				,IIF(FC.DefaultedSortcode = 1, 'true', 'false') AS [Default Sort Code Indicator]
				,IIF(FC.DefaultedAccount = 1, 'true', 'false') AS [Default Account Number Indicator] 
				,IIF(FC.DefaultedReference = 1, 'true', 'false') AS [Default Reference Number Indicator]
				,RIGHT('000000' + cast(FC.SwitchedSortCode as varchar(6)),6) AS [Original Sort Code (Switched Account)]
				,RIGHT('00000000' + cast(FC.SwitchedAccount as varchar(8)),8) AS [Original Account Number (Switched Account)]
				,RKD 
				= ROW_NUMBER() OVER(PARTITION BY 
									 ETSET.TransactionSetIdWithVersion
									 ,FC.TSetIDWithVersion 
									 ,ETSET.CreditId
									 ,FC.CreditId
									ORDER BY 
									 FC.ItemId DESC
									) 
		FROM
			#EligibleItemIds ETSET
		INNER JOIN 
			Base.FinalCredit FC WITH (SNAPSHOT)
		ON 
			ETSET.TransactionSetId = FC.TransactionSetId 
		AND 
			FC.CreditId=ETSET.CreditId
		INNER JOIN 
			#EligibleISOMSG13Tsets TX
		ON 
			ETSET.TransactionSetId = TX.TransactionSetId
		LEFT JOIN  
			Lookup.ItemType ITMTYPE WITH (SNAPSHOT)
		ON 
			ITMTYPE.Id = FC.ItemType
		LEFT JOIN 
			(
				SELECT 
					[CreditId], 
					[ItemId], 
					[BeneficiaryName], 
					[CashAmount], 
					[FundedAmount], 
					[NonFundedAmount],
					[VirtualCredit],
					[ChequeAtRisk]
				FROM
					(
						SELECT 
							Cr.[CreditId] AS [CreditId],
							Cr.[ItemId] AS [ItemId],
							CrFrd.[BeneficiaryName] AS [BeneficiaryName],
							CrFrd.[CashAmount] AS [CashAmount],
							CrFrd.[FundedAmount] AS [FundedAmount], [NonFundedAmount] [NonFundedAmount],
							CASE 
								WHEN CrFrd.[VirtualCredit] = 1 
								THEN 'true' 
								ELSE 'false' 
							END AS [VirtualCredit],
							CASE 
								WHEN CrFrd.[ChequeAtRisk] = 1 
								THEN 'true' 
								ELSE 'false' 
							END AS [ChequeAtRisk],
							ROW_NUMBER() OVER (PARTITION BY Cr.CreditId ORDER BY Cr.ItemId DESC) AS [RowNumber]
						FROM 
							Base.Credit Cr  WITH (SNAPSHOT)  
						INNER JOIN 
							Base.CreditFraudData AS CrFrd  WITH (SNAPSHOT) 
						ON 
							CrFrd.ItemId = Cr.ItemId
						INNER JOIN 
							Base.ItemUpdate IU  WITH (SNAPSHOT) 
						ON 
							IU.InternalId = Cr.ItemId
						INNER JOIN 
							Base.Core C  WITH (SNAPSHOT) 
						ON 
							C.CoreId = IU.CoreID
						INNER JOIN 
							Lookup.MessageType Msg  WITH (SNAPSHOT) 
						ON 
							Msg.MessageId = C.MessageType
						WHERE 
							Msg.MessageType IN ('MSG13', 'MSG05', 'MSG01')
					) [CreditFraudData] 
				WHERE 
					CreditFraudData.RowNumber = 1
			) AS CrdFrdData	
		ON 
			CrdFrdData.CreditId = FC.CreditId
		WHERE 
			FC.AgencyBeneficiaryParticipantId = @AgencyId 
	--)
	
		
		CREATE NONCLUSTERED INDEX 
			nci_TSETIDwVRKD 
		ON 
			#EligibleItems(TransactionSetIdWithVersion, RKD)
		WHERE 
			RKD = 1


		SELECT 
			COUNT(1) ItemsCount,
			COUNT(CASE WHEN Gender='CREDIT' THEN 1 ELSE NULL END) CredItemsCount,
			COUNT(CASE WHEN Gender='DEBIT' THEN 1 ELSE NULL END) DebItemsCount,
			COUNT(CASE WHEN [Decision]='Pay' AND Gender='DEBIT' THEN 1 ELSE NULL END) NumPaid,
			SUM(CASE WHEN [Decision]='Pay' AND Gender='DEBIT' THEN CONVERT(NUMERIC(20,2),Amount) ELSE NULL END) ValuePaid,
			COUNT(CASE WHEN [Decision]='NoPay'  AND Gender='DEBIT' THEN 1 ELSE NULL END) NumNoPay,
			SUM(CASE WHEN [Decision]='NoPay'  AND Gender='DEBIT' THEN CONVERT(NUMERIC(20,2),Amount) ELSE NULL END) ValueNoPay
		INTO
			#HeaderRecord
		FROM
			#EligibleItems 
		WHERE 
			RKD = 1


			

			
		SELECT 
			Result.RowValue
		FROM 
			(
				 SELECT RowValue = 'Filename,Date,FileVolume,CreditVolume,DebitVolume,NumPaid,ValuePaid,NumNoPay,ValueNoPay' + REPLICATE(',', 23)
				      , 1 AS RNO
					  ,'1' AS [T-Set Id]
					  ,'1' AS [Gender]
					  ,'1' AS [Item Type]
					  ,'1' AS [Item Id]
				  UNION ALL
				  SELECT RowValue = (
				  SELECT				  
						  @FileName + ','
                        + @HeaderBusinessDate + ','
                        + RIGHT('00000' + CONVERT(VARCHAR, ISNULL(ItemsCount, 0)),5) + ','
						+ RIGHT('00000' + CONVERT(VARCHAR, ISNULL(CredItemsCount, 0)),5) + ','
						+ RIGHT('00000' + CONVERT(VARCHAR, ISNULL(DebItemsCount, 0)),5) + ','
                        + RIGHT('00000' + CONVERT(VARCHAR, ISNULL(NumPaid, 0)),5) + ','
                        + CONVERT(VARCHAR, ISNULL(ValuePaid, 0.00)) + ','
                        + RIGHT('00000' + CONVERT(VARCHAR, ISNULL(NumNoPay, 0)),5) + ','
                        + CONVERT(VARCHAR, ISNULL(ValueNoPay, 0.00))
                        + REPLICATE(',', 23) 
						),
                        2 AS RNO
					    ,'2' AS [T-Set Id]
						,'2' AS [Gender]
						,'2' AS [Item Type]
						,'2' AS [Item Id]
					FROM 
						(
							SELECT TOP 1 
								* 
							FROM 
								#HeaderRecord
						) A


				UNION ALL
				 SELECT RowValue = REPLICATE(',', 31) ,
						3 AS RNO
						,'3' AS [T-Set Id]
						,'3' AS [Gender]
						,'3' AS [Item Type]
						,'3' AS [Item Id]
				  UNION ALL
				 SELECT RowValue = 'T-Set Id,Collecting Participant ID,Collecting Channel,Item Id,Gender,Item Type,Transaction Code,Cheque Risk Indicator,Reference/serial,Sort code,Account,Beneficiary Name,Amount,Paid Amount,Decision,No Pay Reason Code,Fraud Reason Code,No Pay Reason Description,Virtual Credit Indicator,Cash Amount,Funded Amount,Non Funded Amount,Sort Code Repaired Indicator,Account No Repaired Indicator,Amount Repaired Indicator,Reference Number Repaired Indicator,Default Sort Code Indicator,Default Account Number Indicator,Default Reference Number Indicator,Original Sort Code (Switched Account),Original Account Number (Switched Account)' ,
						4 AS RNO
						,'4' AS [T-Set Id]
						,'4' AS [Gender]
						,'4' AS [Item Type]
						,'4' AS [Item Id]
				  UNION ALL
				 SELECT RowValue = (
									 
						 SELECT CONCAT ([T-Set Id],','
										,[Collecting Participant ID],','
										,[Collecting Channel],','
										,[Item Id],','
										,[Gender],','
										,[Item Type],','
										,[Transaction Code],','
										,[Cheque Risk Indicator],','
										,[Reference/serial],','
										,[Sort code],','
										,[Account],','
										,[Beneficiary Name],','
										,[Amount],','
										,[Paid Amount],','
										,[Decision],','
										,[No Pay Reason Code],','
										,[Fraud Reason Code],','
										,[No Pay Reason Description],','
										,[Virtual Credit Indicator],','
										,[Cash Amount],','
										,[Funded Amount],','
										,[Non Funded Amount],','
										,[Sort Code Repaired Indicator],','
										,[Account No Repaired Indicator],','
										,[Amount Repaired Indicator] ,','
										,[Reference Number Repaired Indicator] ,','
										,[Default Sort Code Indicator],','
										,[Default Account Number Indicator],','
										,[Default Reference Number Indicator],','
										,[Original Sort Code (Switched Account)],','
										,[Original Account Number (Switched Account)]
									) 
									),
							5 AS RNO,
						    [T-Set Id],
							[Gender],
							[Item Type],
							[Item Id]
					FROM 
						(
							SELECT 
								* 
							FROM 
								#EligibleItems 
							WHERE 
								RKD = 1
						) A
			) AS Result
		 ORDER BY 
			Result.RNO
			,Result.[T-Set Id]
			,Result.[Gender]
			,Result.[Item Type]
			,Result.[Item Id]; 
	END;
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
GRANT EXECUTE ON [Agency].[usp_ReturnAgencyISOMSG13CSV] TO AgencyISOMsgExtractor;
	
GO

EXECUTE sp_addextendedproperty @name = N'Component', @value = N'STAR',
    @level0type = N'SCHEMA', @level0name = N'Agency', @level1type = N'PROCEDURE',
    @level1name = N'usp_ReturnAgencyISOMSG13CSV';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'This Stored Procedure returns the MSG13 Items in CSV format for a given AgencyId.',
    @level0type = N'SCHEMA', @level0name = N'Agency', @level1type = N'PROCEDURE',
    @level1name = N'usp_ReturnAgencyISOMSG13CSV';


GO
EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)',
    @level0type = N'SCHEMA', @level0name = N'Agency', @level1type = N'PROCEDURE',
    @level1name = N'usp_ReturnAgencyISOMSG13CSV';