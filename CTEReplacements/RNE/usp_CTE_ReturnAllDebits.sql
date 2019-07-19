CREATE PROCEDURE [RNE].[usp_CTE_ReturnAllDebits]
     @BusinessDate DATETIME
    ,@PreviousBusinessDate DATETIME
	,@NextBusinessDate DATETIME

/*****************************************************************************************************
* Name				: [Base].[usp_CTE_ReturnAllDebits]
* Description		: This stored procedure returns final set of Debits for CTE.
* Type of Procedure : Interpreted stored procedure
* Author			: Pavan manneru
* Creation Date		: 15/07/2018
* Last Modified		: N/A
*******************************************************************************************************/
AS
    BEGIN
	
		-- ;WITH CTEFinalEntities
		-- AS
		-- (
		SELECT	
			CTEInitialEntities.TranSetID
			,CTEInitialEntities.Participant
			,CTEInitialEntities.MarketSectorGroupID
			,CTEInitialEntities.MSOUGroupName
			,CTEInitialEntities.Brand
			,CTEInitialEntities.OnUsInd
			,CTEInitialEntities.CaptDate
			,CTEInitialEntities.[Source]
			,CTEInitialEntities.CollSort
			,CTEInitialEntities.ImageCaptureID
			,CTEInitialEntities.ImageCaptureDeviceID
			,CTEInitialEntities.SettlementPeriodID
			,CTEInitialEntities.TranAmount
			,CTEInitialEntities.ItemType
			,CTEInitialEntities.CrDrInd
			,CTEInitialEntities.TransID
			,CTEInitialEntities.SortCode
			,CTEInitialEntities.AccNum
			,CTEInitialEntities.SerialNumber
			,CTEInitialEntities.Ref
			,CTEInitialEntities.TranCode
			,CTEInitialEntities.ResAmount
			,CTEInitialEntities.SwitchSort
			,CTEInitialEntities.SwitchAcc
			,CTEInitialEntities.Beneficiary
			,CASE 
				WHEN CTEInitialEntities.cf_ChnlInsertReason='Cash' 
				THEN 1 
				ELSE 0 
			END AS CashInd
			,CTEInitialEntities.RepairReasonCode
			,CTEInitialEntities.RepairFlag
			,CTEInitialEntities.OrigSort
			,CTEInitialEntities.OrigAcc
			,CTEInitialEntities.OrigAmt
			,CTEInitialEntities.OrigSerNum
			,CTEInitialEntities.OrigRef
			,CTEInitialEntities.OrigTransCode
			,CTEInitialEntities.RejectReasonCode
			,CTEInitialEntities.RejectFlag
			,CTEInitialEntities.PaidStatus
			,CTEInitialEntities.UnpaidReason
			,CTEInitialEntities.FraudCheckResult
			,CTEInitialEntities.FraudCheckReason
			,CASE 
				WHEN CTEInitialEntities.cf_ChnlInsertReason='Electronic' 
				THEN 1 
				ELSE 0 
			END AS ElecInd
			,CTEInitialEntities.RepFlag
			,CTEInitialEntities.NpASort
			,CTEInitialEntities.NPAAcc
			,CTEInitialEntities.AccSys
			,CTEInitialEntities.Redir	
			,CTEInitialEntities.Day2ResponseWindowEndDateTime		
			,CTEInitialEntities.ItemEntityState
			,CTEInitialEntities.ChargedParticipantId ChargingParticipant
			,CTEInitialEntities.NoOfAssociatedItems
			,CTEInitialEntities.MSG13ItemId	
			,CTEInitialEntities.MessageType
			,CTEInitialEntities.cf_OnBank
			,CTEInitialEntities.ICSAmount
			,CTEInitialEntities.isEligibleForExtract
			,CTEInitialEntities.cf_ChnlInsertReason
			,CTEInitialEntities.FinalRKD	
			,MAX(CTEInitialEntities.RejEntityState) OVER (PARTITION BY CTEInitialEntities.TransId ORDER BY CTEInitialEntities.TransId) RejEntityState
			,MAX(CTEInitialEntities.DocumentEntityState) OVER (PARTITION BY CTEInitialEntities.TransId ORDER BY CTEInitialEntities.TransId) DocumentEntityState
			,MAX(CTEInitialEntities.DefaultPayDecision) OVER (PARTITION BY CTEInitialEntities.TransId ORDER BY CTEInitialEntities.TransId) DefaultPayDecisionInd
		INTO
			#FinalEntities
		FROM
			[RNE].[StagingCTEInitialEntities] 	CTEInitialEntities

		-- SJC. We only ever select isEligibleForExtract and FinalRKD where their values are equal to 1, so filter
		-- the index to just those values.
		CREATE NONCLUSTERED INDEX 
			nci_iefe_FinalRKD 
		ON 
			#FinalEntities(isEligibleForExtract, FinalRKD)
		WHERE 
			isEligibleForExtract = 1 
		AND 
			FinalRKD = 1

		SELECT 
			FinalEntities.TranSetID
			,FinalEntities.Participant
			,FinalEntities.MarketSectorGroupID
			,FinalEntities.MSOUGroupName
			,CASE	
				WHEN FinalEntities.RejEntityState <> 0 
				THEN FinalEntities.RejEntityState
				WHEN FinalEntities.DocumentEntityState <> 0 
				THEN FinalEntities.DocumentEntityState
				ELSE  FinalEntities.ItemEntityState
			END AS CompStat -- Need to be mapped to a collection, return 'C' or 'P'
			,FinalEntities.Brand
			,FinalEntities.OnUsInd
			,FinalEntities.SettlementPeriodID
			,FinalEntities.CaptDate
			,FinalEntities.[Source]
			,FinalEntities.CollSort
			,FinalEntities.ImageCaptureID
			,FinalEntities.ImageCaptureDeviceID			
			,FinalEntities.TranAmount
			,FinalEntities.ItemType
			,FinalEntities.CrDrInd
			,FinalEntities.TransID
			,FinalEntities.SortCode
			,FinalEntities.AccNum
			,FinalEntities.SerialNumber
			,FinalEntities.Ref
			,FinalEntities.TranCode
			,FinalEntities.ResAmount
			,FinalEntities.SwitchSort
			,FinalEntities.SwitchAcc
			,FinalEntities.NoOfAssociatedItems
			,FinalEntities.Beneficiary
			,FinalEntities.CashInd
			,FinalEntities.RepairReasonCode
			,FinalEntities.RepairFlag
			,FinalEntities.OrigSort
			,FinalEntities.OrigAcc
			,FinalEntities.OrigAmt
			,FinalEntities.OrigSerNum
			,FinalEntities.OrigRef
			,FinalEntities.OrigTransCode
			,FinalEntities.RejectReasonCode
			,IIF(FinalEntities.RejEntityState <> 0,1,FinalEntities.RejectFlag) AS RejectFlag
			,FinalEntities.PaidStatus
			,CASE	
				WHEN FinalEntities.DefaultPayDecisionInd = 1 
				THEN '2'
				WHEN FinalEntities.UnpaidReason = '0099' 
				THEN '1'
				ELSE NULL
			END AS DefaultPayDecision
			,FinalEntities.UnpaidReason
			,FinalEntities.FraudCheckResult
			,FinalEntities.FraudCheckReason
			,FinalEntities.ElecInd
			,FinalEntities.RepFlag
			,FinalEntities.NpASort
			,FinalEntities.NPAAcc
			,FinalEntities.AccSys
			,FinalEntities.Redir
			,CASE 
				WHEN FinalEntities.RejEntityState <> 0
				THEN COALESCE	(
									CAST(FinalEntities.Day2ResponseWindowEndDateTime AS DATE)   --PICK THIS up if exists
									,CAST(LEFT(FinalEntities.MSG13ItemId,8) AS DATE)  --the date on which MSG13 is receive is SettlementDate	
									,@BusinessDate  -- if MSG13 is not received, the date on which MSG05 + 1 is SettlementDate
								)

								-- This item not submitted to switch
				WHEN FinalEntities.ItemEntityState IN (82) 
				THEN @BusinessDate 
				ELSE
					COALESCE(
							CAST(FinalEntities.Day2ResponseWindowEndDateTime AS DATE)   --PICK THIS up if exists
							,CAST(LEFT(FinalEntities.MSG13ItemId,8) AS DATE)  --the date on which MSG13 is receive is SettlementDate	
							,@NextBusinessDate  -- if MSG13 is not received, the date on which MSG05 + 1 is SettlementDate
							)
			END SettlementDate			
			,FinalEntities.ItemEntityState
			,FinalEntities.ChargingParticipant
			,FinalEntities.MessageType
			,null as cf_NPASortCode
			,FinalEntities.cf_OnBank
			,FinalEntities.ICSAmount
			,SUM(ResAmount) OVER (PARTITION BY TranSetID) AS DBSumResAmount
			,MAX(FinalEntities.CashInd) OVER (PARTITION BY FinalEntities.TranSetID ORDER BY FinalEntities.TranSetID) DebitCashInd
		FROM 
			#FinalEntities FinalEntities	
		WHERE	
			FinalEntities.isEligibleForExtract = 1 
		AND 
			FinalEntities.FinalRKD = 1

	END

GO

GRANT EXECUTE ON [RNE].[usp_CTE_ReturnAllDebits] TO [RNESVCAccess];

GO

EXEC sys.sp_addextendedproperty @name=N'Component', @value=N'STAR' , @level0type=N'SCHEMA',@level0name=N'RNE', @level1type=N'PROCEDURE',@level1name=N'usp_CTE_ReturnAllDebits'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'This stored procedure returns final set of Debits for CTE.' , @level0type=N'SCHEMA',@level0name=N'RNE', @level1type=N'PROCEDURE',@level1name=N'usp_CTE_ReturnAllDebits'
GO

EXEC sys.sp_addextendedproperty @name=N'Version', @value=N'1.1.0' , @level0type=N'SCHEMA',@level0name=N'RNE', @level1type=N'PROCEDURE',@level1name=N'usp_CTE_ReturnAllDebits'
GO
