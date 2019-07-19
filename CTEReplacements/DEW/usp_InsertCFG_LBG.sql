CREATE  PROCEDURE [CFG].[usp_InsertCFG_LBG]
@Server VARCHAR(50)
AS
    BEGIN 
    SET NOCOUNT ON; 
			
			SET @Server = UPPER(@Server)

			IF (@Server = 'LIVE' OR  @Server ='SIT' OR @Server ='IT' OR @Server ='TR' OR @Server ='TME' OR @Server ='PPE')
			BEGIN

			INSERT INTO CFG.[Configuration]([Name],[Value])
			SELECT [Name],[Value]
			FROM [Import].[Configuration_LBG]

		-----------------------------Direct Insert Into CFG tables------------------------------------------------
			UPDATE [Import].[WorkGroup_LBG] SET [AmountTo] = '999999999.99'
			WHERE [AmountTo] = '1000000000'
		-----------------------------[CFG].[DecisionFunction]------------------------------------------------			
			INSERT [CFG].[DecisionFunction] ([DecisionFunctionId], [Name], [ForTechnicalValidation]) 
			SELECT [DecisionFunctionId], [Name], [ForTechnicalValidation] FROM [Import].[DecisionFunction_LBG]
			-----------------------------[CFG].[ImportIdentifier]------------------------------------------------
			INSERT [CFG].[ImportIdentifier] ([ImportIdentifierId], [ExceptionType]) VALUES (1, N'Default')
			INSERT [CFG].[ImportIdentifier] ([ImportIdentifierId], [ExceptionType]) VALUES (2, N'EM_299')
			INSERT [CFG].[ImportIdentifier] ([ImportIdentifierId], [ExceptionType]) VALUES (3, N'Other exception')

			------------------[CFG].[Duplicates]---------------------------------------------------
			INSERT INTO [CFG].[Duplicates] VALUES (1,'PART')
			INSERT INTO [CFG].[Duplicates] VALUES (2,'FULL') 

				------------------[CFG].[StopsCodesIndustry]---------------------------------------------------
			INSERT [CFG].[StopsCodesIndustry] ([StopsCodesIndustryId], [StopsCode]) VALUES (1, N'PARA')
			INSERT [CFG].[StopsCodesIndustry] ([StopsCodesIndustryId], [StopsCode]) VALUES (2, N'FULL')
			INSERT [CFG].[StopsCodesIndustry] ([StopsCodesIndustryId], [StopsCode]) VALUES (3, N'PARS')

			----------------------------------[CFG].[CustomerSegment]---------------------------------------------------------
			INSERT INTO 
				[CFG].[CustomerSegment] 
				(
					[CustomerSegmentId]
					,[Name]
					,[UpdatedDate]
					,[CreatedDate]
					,[CreatedBy]
					,[UpdatedBy]
					,[DELETEd]
				)
			SELECT 
				[CustomerSegmentSeq]
				,[Name]
				,GETDATE()
				,GETDATE()
				,Original_Login()        
				,Original_Login()        
				,0
			FROM 
				[import].[CustomerSegment_LBG]
		-----------------------------1.[CFG].[UserFailReason]------------------------------------------------
			INSERT INTO 
				[CFG].[UserFailReason]
			SELECT 
				[UserFailReasonSeq]
				,FR.[Name]	
			FROM 
				[Import].[FailureReasons_LBG] FR

		-----------------------------2.[CFG].[NoPayReasonCodesIndustry]-----------------------------------------------  
		INSERT INTO 
			[CFG].[NoPayReasonCodesIndustry]
			(	
				[NoPayReasonCodesIndustryId] 
				,[Name]
				,[Code]
				,[LastUpdated] 
				,[CreatedDate]        
				,[CreatedBy]        
				,[UpdatedBy]        
				,[BankMaxRepresntCount]        
				,[DaysDelayForRepresent]
			)   
		SELECT 
			[NoPayReasonCodesIndustrySeq]         
			,[Name]        
			,[Code]       
			,GetDate()
			,GetDate()
			,Original_Login()
			,Original_Login()        
			,[BankMaxRepresntCount]        
			,[DaysDelayForRepresent]    
		FROM 
			[Import].[NoPayIndustry_LBG]

		----------------------------3.[CFG].[NoPayReasonCodesIndustry_Config]--------------------------------------
		INSERT INTO 
			CFG.NoPayReasonCodesIndustry_Config
			(
				[NoPayReasonCodeId],
				[MessageType] ,
				[CustomerNotificationReq],
				[CaseManagementReq],
				[CasePrefix]
			)
		SELECT 
			NP.[NoPayReasonCodesIndustryId], 
			DNI.MESSAGETYPE,
			DNI.[CustomerNotificationReq],
			DNI.[CaseManagementReq],DNI.[CasePrefix] 
		FROM 
			[import].NoPayIndustry_LBG DNI 
		JOIN 
			CFG.NoPayReasonCodesIndustry NP 
		ON 
			DNI.NoPayReasonCodesIndustrySeq=NP.NoPayReasonCodesIndustryId

		 ---------------------------4.[CFG].[UserType]--------------------------------------------------------------
		INSERT INTO 
			[CFG].[UserType]
			([UserTypeId]
			,[Name]
			,[DELETEd]
			,[CreatedDate]
			,[UpdatedDate]
			,[CreatedBy]
			,[UpdatedBy])
		SELECT 
			[UserTypeSeq] 
			,[Name]
			,0
			,GetDate()
			,GetDate()
			,Original_Login()
			,Original_Login()
		FROM 
			[import].[UserType_LBG] 
		
		 --------------------------5.[CFG].[Role]----------------------------------------------------------------
		INSERT INTO 
			[CFG].[Role] 
			(
				[RoleId]
				,[Name]
				,[ControllerName]
				,[ActionName]
				,[Parameter]
				,[ParentId]
			)
		SELECT 
			[RoleSeq]
			,[Name]
			,[ControllerName]
			,[ActionName]
			,NULL
			,NULL
		FROM 
			[import].[Role_LBG] 


		UPDATE [CFG].[Role] 
		SET ParentId = Null
		WHERE ParentId = 0   

		----------------------------6.[CFG].[UserTypeInRole]-------------------------------------------------------------------------
  
		INSERT INTO [CFG].[UserTypeInRole] ([UserTypeId],[RoleId])
		SELECT UserTypeSeq, RoleSeq
		FROM Import.[UserTypeInRole_LBG]

		----------------------------7.[CFG].[ADMapping]------------------------------------------------
		IF (UPPER(@Server) = 'LIVE')
			BEGIN
				 INSERT INTO [CFG].[ADMapping]
					  ([ADMappingId]
					  ,[UserTypeId]     
					  ,[ADGroupName]
					  ,[ReviewThreshold]
					  ,[DELETEd]
					  ,[CreatedDate]
					  ,[UpdatedDate]
					  ,[CreatedBy]
					  ,[UpdatedBy])

				SELECT AD.[ADMappingSeq]
					  ,UT.[UserTypeId]     
					  ,AD.[ADGroupName]
					  ,AD.[ReviewThreshold]
					  ,0
					  ,GetDate()
					  ,GetDate()
					  ,Original_Login()
					  ,Original_Login() 
				FROM [Import].[ADMapping_LI_LBG] AD 
				JOIN CFG.UserType UT on UT.Name=AD.[UserTypeSeq]
			END
		ELSE IF (UPPER(@Server) = 'SIT'  OR UPPER(@Server) = 'IT')
			BEGIN
					 INSERT INTO [CFG].[ADMapping]
						  ([ADMappingId]
						  ,[UserTypeId]     
						  ,[ADGroupName]
						  ,[ReviewThreshold]
						  ,[DELETEd]
						  ,[CreatedDate]
						  ,[UpdatedDate]
						  ,[CreatedBy]
						  ,[UpdatedBy])

					SELECT AD.[ADMappingSeq]
						  ,UT.[UserTypeId]     
						  ,AD.[ADGroupName]
						  ,AD.[ReviewThreshold]
						  ,0
						  ,GetDate()
						  ,GetDate()
						  ,Original_Login()
						  ,Original_Login() 
					FROM [import].[ADMapping_SIT_IT_LBG] AD 
					JOIN CFG.UserType UT on UT.Name=AD.[UserTypeSeq]
				END
			ELSE IF (UPPER(@Server) = 'TR')
				BEGIN
						 INSERT INTO [CFG].[ADMapping]
							  ([ADMappingId]
							  ,[UserTypeId]     
							  ,[ADGroupName]
							  ,[ReviewThreshold]
							  ,[DELETEd]
							  ,[CreatedDate]
							  ,[UpdatedDate]
							  ,[CreatedBy]
							  ,[UpdatedBy])

						SELECT AD.[ADMappingSeq]
							  ,UT.[UserTypeId]     
							  ,AD.[ADGroupName]
							  ,AD.[ReviewThreshold]
							  ,0
							  ,GetDate()
							  ,GetDate()
							  ,Original_Login()
							  ,Original_Login() 
						FROM [import].[ADMapping_TR_LBG] AD 
						JOIN CFG.UserType UT on UT.Name=AD.[UserTypeSeq]
					END

				ELSE IF (UPPER(@Server) = 'TME')
				BEGIN
						 INSERT INTO [CFG].[ADMapping]
							  ([ADMappingId]
							  ,[UserTypeId]     
							  ,[ADGroupName]
							  ,[ReviewThreshold]
							  ,[DELETEd]
							  ,[CreatedDate]
							  ,[UpdatedDate]
							  ,[CreatedBy]
							  ,[UpdatedBy])

						SELECT AD.[ADMappingSeq]
							  ,UT.[UserTypeId]     
							  ,AD.[ADGroupName]
							  ,AD.[ReviewThreshold]
							  ,0
							  ,GetDate()
							  ,GetDate()
							  ,Original_Login()
							  ,Original_Login() 
						FROM [import].[ADMapping_TME_LBG] AD 
						JOIN CFG.UserType UT on UT.Name=AD.[UserTypeSeq]
					END
				ELSE IF (UPPER(@Server) = 'PPE')
				BEGIN
						 INSERT INTO [CFG].[ADMapping]
							  ([ADMappingId]
							  ,[UserTypeId]     
							  ,[ADGroupName]
							  ,[ReviewThreshold]
							  ,[DELETEd]
							  ,[CreatedDate]
							  ,[UpdatedDate]
							  ,[CreatedBy]
							  ,[UpdatedBy])

						SELECT AD.[ADMappingSeq]
							  ,UT.[UserTypeId]     
							  ,AD.[ADGroupName]
							  ,AD.[ReviewThreshold]
							  ,0
							  ,GetDate()
							  ,GetDate()
							  ,Original_Login()
							  ,Original_Login() 
						FROM [import].[ADMapping_PPE_LBG] AD 
						JOIN CFG.UserType UT on UT.Name=AD.[UserTypeSeq]
					END
		---------------------------8.[CFG].[APGNoPayReasonCodes]----------------------------------------------------------------
		Insert Into [CFG].[APGNoPayReasonCodes]
			([APGNoPayReasonCodeId]
			,[APGNoPayReasonCode]
			,[IsMultiIndicator]
			)
		Select [APGNoPayReasonCodeSeq]
			  ,[APGNoPayReasonCode]
			  ,[IsMultiIndicator]
		From [import].[APGNoPayCodes_LBG]

		--------------------------9.[CFG].[APGNoPayReasonCodesMapIndustry]----------------------------------------------------------------
		INSERT INTO [CFG].[APGNoPayReasonCodesMapIndustry]
			([APGNoPayReasonCodeId]
			,NoPayReasonCodesIndustryId)
		SELECT AC.[APGNoPayReasonCodeId]
			  ,NPI.[NoPayReasonCodesIndustryId]
		FROM [import].[APGNoPayCodes_LBG] APR
		JOIN CFG.NoPayReasonCodesIndustry NPI on NPI.Code= APR.[IndustryCode]
		JOIN CFG.APGNoPayReasonCodes AC on AC.APGNoPayReasonCode=APR.[APGNoPayReasonCode]

		----------------------------------38--[CFG].[RangeAccountNumber]--------------------------------------------------------
		--INSERT [CFG].[RangeAccountNumber]
		--select  [RangeAccountNumberSeq] 
		--		,[From]
		--		,[To]
		--From [import].[RangeAccountNumber_LBG] 

		-------------------------10.[CFG].[UserProcessCodes]---------------------------------
		INSERT INTO [CFG].[UserProcessCodes]
				   ([UserProcessCodesId]
				   ,[Name])

		SELECT [INDEX] ,
			   [NAME]
		FROM [import].[UserProcessCodes_LBG]

		-------------------------11.[CFG].[UserDecision]----------------------------------------
		INSERT INTO [CFG].[UserDecision]
			  ([UserDecisionId]
			  ,[Name])
		SELECT  [UserDecisionSeq]
			  ,[Name]
		FROM [import].[UserDecision_LBG] 

		------------------------12.[CFG].[ProcessInADMapping]-------------------------
		INSERT INTO [CFG].[ProcessInADMapping]([ADMappingId],[UserProcessCodesId])
		SELECT ADMap.ADMappingId, UPC.UserProcessCodesId
		FROM CFG.ADMapping ADMap
		CROSS JOIN 
		CFG.UserProcessCodes UPC

		----------------------- 13.[CFG].[WorkstreamState]-----------------------------
		INSERT INTO [CFG].[WorkstreamState]
				   ([WorkstreamStateId]
				   ,[UserProcessCodesSeq]
				   ,[Name]
				   ,[AgencyDisplayName])

		SELECT [INDEX],
		UG.UserProcessCodesId,
		WSS.name,
		agencydisplayname
		FROM [import].[WorkStreamState_LBG] WSS
		LEFT OUTER JOIN CFG.UserProcessCodes UG on WSS.name=UG.Name

		 ---------------------------------------------32.[CFG].[WORKGROUP]----------------------------------------------------------------------------------------------------------------------------------------------------  
		INSERT INTO [CFG].[WorkGroup]   
		([WorkGroupId],[Name],[PostingResponseRequired],[AmountFrom],[AmountTo],[Priority],[DELETEd],[AlwaysNoPay],[AlwaysNoPayReasonId], [CustomerNotificationEnabled], [AgencyId])  
		SELECT  [WorkGroupSeq]
		,WG.[Name],[PostingResponseRequired]
		,[AmountFrom]
		,[AmountTo]
		,[Priority]
		,0
		,[AlwaysNoPay]
		,[NI].[NoPayReasonCodesIndustryId]  
		,[WG].[CustomerNotificationEnabled]
		,CASE	WHEN [AgencyId] = ''		
					THEN NULL 
				WHEN [AgencyId] = 'NULL'	
					THEN NULL 
				ELSE [AgencyId]
		END  [AgencyId]
		FROM [Import].[WorkGroup_LBG] WG  
		LEFT JOIN CFG.NoPayReasonCodesIndustry NI ON NI.[Name]= WG.[AlwaysNoPayReasonSeq] 
		------------------------14.[CFG].[EntityStates]---------------------------------------------------------
		INSERT INTO [CFG].[EntityStates]
				([EntityStateId]
				,[EntityState]
				,[Description]
				,[MessageType])
		
		SELECT    [EntityStateSeq],
				  [EntityState],
				  [Description],
				  [MessageType]
		FROM [import].[EntityStates_LBG]
		----------------------15.[CFG].[PostingResponseQualifier]------------------
		INSERT INTO [CFG].[PostingResponseQualifier]
			   ([PostingResponseQualifierId]
			  ,[Qualifier]
			  ,[Name]
			  ,[Priority])

		SELECT [PostingResponseQualifierSeq]
			  ,[Qualifier]
			  ,[Name]
			  ,[Priority]
		FROM [import].[PostingResponseQualifier_LBG] 

		---------------------16.[CFG].[PostingResponseStatus]-----------------------------------------------------------------
		INSERT INTO [CFG].[PostingResponseStatus] 
			  ([PostingResponseStatusId]
			  ,[Code]
			  ,[ResponseSubType]
			  ,[ExcessManagement]
			  )
		SELECT [PostingResponseStatusSeq]
			  ,[Code]	 
			  ,CASE	WHEN [ResponseSubType] = '' THEN NULL 
					WHEN [ResponseSubType] = 'NULL' THEN NULL 
						ELSE [ResponseSubType]
			   END  [ResponseSubType]
			  ,[ExcessManagement]
		FROM [import].[PostingResponseStatus_LBG] 


		----------------------17.[CFG].[DecisionerMapAPGNoPayReasonCodes]-----------------------------------

		INSERT INTO [CFG].[DecisionerMapAPGNoPayReasonCodes]([APGNoPayReasonCodeId],[DecisionFunctionId])
		SELECT CFGANPR.APGNoPayReasonCodeId,DF.DecisionFunctionId
		FROM  [import].[APGNoPayCodes_LBG] ANPR  
		INNER JOIN [CFG].[APGNoPayReasonCodes] CFGANPR ON ANPR.APGNoPayReasonCode = CFGANPR.APGNoPayReasonCode
		INNER JOIN [CFG].[DecisionFunction] DF ON ANPR.Decisioner = DF.Name

		------------------------------------------------18-[CFG].[WorkStream]---------------------------------------
		INSERT INTO [CFG].[Workstream]
			([WorkstreamId]
			,[WorkGroupId]
			,[DecisionFunctionId]
			,[Name]
			,[AmountFrom]
			,[AmountTo]
			,[Priority]
			,[DELETEd]
			,[CreatedDate]
			,[UpdatedDate]
			,[CreatedBy]
			,[UpdatedBy]
			,[LinkedItemCount]
			,[IsAutoNoPay])


		SELECT [WorkstreamSeq] 
			,W.[WorkGroupId]
			,DF.[DecisionFunctionId]
			,WS.[Workstream Name]
			,WS.[AmountFrom]
			,WS.[AmountTo]
			,WS.[Priority]
			,0
			,GetDate()
			,GetDate()
			,Original_Login()
			,Original_Login() 
			,[LinkedItemCount]
			,WS.[IsAutoNoPay] 
		FROM [import].[WorkStream_LBG] WS
		JOIN CFG.[DecisionFunction] DF ON DF.[Name]=WS.[DecisionFunctionSeq]
		JOIN CFG.WorkGroup W on W.[Name]=WS.[WorkGroupSeq] 

		----------------------------------------19-CFG.SUBWORKSTREAM------------------------------------------------------
		
		--UPDATE Subworkstream Sort and Account Number

		
		UPDATE [import].[SubWorkStream_LBG]  SET [Sort Code Range From] =0, [Sort Code Range To] =999999
		where [Sort Code Range From]='' AND [Sort Code Range To]=''


		UPDATE [import].[SubWorkStream_LBG]  SET [Account Number Range From] =0, [Account Number Range To] =99999999
		where [Account Number Range From]='' AND [Account Number Range To]=''

		
		;WITH 
			SubWorkstreamCTE
			(
				UniqueWorkStream,
				WORKSTREAMSEQ,
				[SUB WORK STREAM NAME],
				[Amount Range From],
				[Amount Range To],
				[PRIORITY],
				DELETED, 
				CreateDate, 
				UpdatedDate,
				CreatedBy,
				UpdatedBy,
				[LinkedItemCount]
			) 
		AS
		(
			SELECT  
				ROW_NUMBER()  OVER(PARTITION BY  WORKSTREAMID,[SUB WORK STREAM NAME] ORDER BY [SUB WORK STREAM NAME]) [uni],
				WS.WorkstreamId,
				SWS.[SUB WORK STREAM NAME],
				--SWS.[Amount Range From], 
				CASE	
					WHEN SWS.[Amount Range From] = '' 
					THEN NULL 
					WHEN SWS.[Amount Range From] = 'NULL' 
					THEN NULL 
					ELSE SWS.[Amount Range From]
				END,
				--SWS.[Amount Range To],
				CASE	
					WHEN SWS.[Amount Range To] = '' 
					THEN NULL 
					WHEN SWS.[Amount Range To] = 'NULL' 
					THEN NULL 
					ELSE SWS.[Amount Range To]
				END,
				SWS.[PRIORITY] [PRIORITY], 
				0 DELETED, 
				GETDATE() CreateDate,
				GETDATE() UpdatedDate,
				'IPSL' CreatedBy,
				'IPSL' UpdatedBy,
				SWS.[LinkedItemCount] AS [LinkedItemCount]
			FROM 
				[import].[SubWorkStream_LBG] SWS
			INNER JOIN 
				CFG.WORKGROUP WG  
			ON 
				SWS.[Work Group] = WG.NAME 
			INNER JOIN 
				CFG.WORKSTREAM WS   
			ON 
				WS.WorkGroupId = WG.WorkGroupId 
			AND 
				SWS.[Work Stream] = WS.Name 
			WHERE 
				UPPER([SUB WORK STREAM NAME]) <> 'DEFAULT'
		)
		
		
		INSERT INTO CFG.SUBWORKSTREAM
		(
			SubWorkstreamId,
			WorkstreamId,
			[NAME],
			[AMOUNTFrom],
			AMOUNTTO,
			[PRIORITY],
			[DELETED], 
			CREATEDDATE, 
			UPDATEDDATE, 
			CREATEDBY, 
			UPDATEDBY,
			[LinkedItemCount]
			) 
		SELECT	 ROW_NUMBER()  OVER( ORDER BY WORKSTREAMSEQ,[SUB WORK STREAM NAME]),
				WORKSTREAMSEQ,
				[SUB WORK STREAM NAME],
				[Amount Range From],
				[Amount Range To],
				[PRIORITY],
				DELETED,
				CreateDate,
				UpdatedDate,
				CreatedBy,
				UpdatedBy,
				[LinkedItemCount]
		FROM SubWorkstreamCTE
		WHERE UniqueWorkStream=1
		ORDER BY WORKSTREAMSEQ,[SUB WORK STREAM NAME]

		  ---------------------20.[CFG].[SystemDecision]--------------------------
		INSERT INTO CFG.SystemDecision
		SELECT SD.SystemDecisionSeq,SD.[Name],E.EntityStateId From [import].SystemDecision_LBG SD
		LEFT JOIN cfg.EntityStates E on E.EntityState=SD.EntityState

		 ----------------------------------------------21-[CFG].[RangeSortCode]-------------------------------------------------------------
		--INSERT INTO [CFG].[RangeSortCode]
		--	   ([RangeSortCodeId]
		--	  ,[From]
		--	  ,[To])
		--SELECT [RangeSortCodeSeq] 
		--	  ,[From]
		--	  ,[To]
		--FROM [import].[RangeSortCode_LBG]


		---------------------------56-[CFG].[SortCodeMapAccountNumber]---------------------------------------------------------------------------------
             INSERT INTO [CFG].[SortCodeMapAccountNumber]
			 (
			 [AccountNumberSeq],
			 [SortCodeMapAccountNumberSeq],
			 [SortCodeSeq]
			 )
			 SELECT  [AccountNumberSeq],
			         [SortCodeMapAccountNumberSeq],
			         [SortCodeSeq]
		    FROM [Import].[SortCodeMapAccountNumber_LBG]
			

		-----------------------------------39--[CFG].[SUBWORKSTREAMINSORTCODERANGE]------------------------------------------
		--	;WITH SubWorkstreamCTE(WORKSTREAMSEQ,[SUB WORK STREAM NAME],[Sort_Code_Range_From],[Sort_Code_Range_To]) 
		--	AS
		--	(
		--	SELECT  
				
		--		WS.WorkstreamId,
		--		SWS.[SUB WORK STREAM NAME],
	 
		--			CASE	WHEN SWS.[Sort Code Range From] = '' THEN NULL 
		--					WHEN SWS.[Sort Code Range From] = 'NULL' THEN NULL 
		--					ELSE SWS.[Sort Code Range From]
		--		END,
	
		--			CASE	WHEN SWS.[Sort Code Range To] = '' THEN NULL 
		--					WHEN SWS.[Sort Code Range To] = 'NULL' THEN NULL 
		--					ELSE SWS.[Sort Code Range To]
		--		END
		--	FROM [import].[SubWorkStream_LBG] SWS
		--	INNER JOIN CFG.WORKGROUP WG  ON SWS.[Work Group] = WG.NAME  
		--	INNER JOIN CFG.WORKSTREAM WS   ON WS.WorkGroupId = WG.WorkGroupId AND SWS.[Work Stream] = WS.Name 
		--	WHERE UPPER([SUB WORK STREAM NAME])<> 'DEFAULT'
		--	)
		--	INSERT INTO CFG.[SubWorkstreamInSortCodeRange] ([SortCodeMapAccountNumberSeq],[SubWorkstreamId])
		--	SELECT	DISTINCT SWS.SubWorkstreamId,
		--			         [SMA].SortCodeMapAccountNumberSeq			
		--	FROM SubWorkstreamCTE			    SCTE
		--	INNER  JOIN CFG.SubWorkstream		SWS		ON SCTE.WorkstreamSeq = SWS.WorkstreamId AND scte.[SUB WORK STREAM NAME] = SWS.Name 
		--	INNER JOIN CFG.RangeSortCode		RSC		ON SCTE.Sort_Code_Range_From = RSC.[From] AND RSC.[To] = SCTE.Sort_Code_Range_To
		--	INNER JOIN CFG.[SortCodeMapAccountNumber] [SMA] on [sma].SortCodeSeq = [rsc].RangeSortCodeId 

		---------------------------------40-[CFG].[SubWorkStreamInAccountNumberRange]-----------------------------------------------------------------

		--	;WITH SubWorkstreamCTE(WORKSTREAMSEQ,[SUB WORK STREAM NAME],[Account Number Range From],[Account Number Range To],[PRIORITY],DELETED, CreateDate, UpdatedDate,CreatedBy,UpdatedBy) 
		--	AS
		--	(
		--	SELECT  
		--		WS.WORKSTREAMID,
		--		SWS.[SUB WORK STREAM NAME],	
		--		CASE	WHEN SWS.[Account Number Range From] = '' THEN NULL 
		--				WHEN SWS.[Account Number Range From] = 'NULL' THEN NULL 
		--		ELSE SWS.[Account Number Range From]
		--		END
		--		,CASE	WHEN SWS.[Account Number Range To] = '' THEN NULL 
		--		WHEN SWS.[Account Number Range To]= 'NULL' THEN NULL 
		--		ELSE SWS.[Account Number Range To]
		--		END,	
		--		SWS.[PRIORITY] [PRIORITY], 
		--		0 DELETED, 
		--		GETDATE() CreateDate,
		--		GETDATE() UpdatedDate,
		--		'IPSL' CreatedBy,
		--		'IPSL' UpdatedBy
		--	FROM [import].[SubWorkStream_LBG] SWS
		--	INNER JOIN CFG.WORKGROUP WG  ON SWS.[Work Group] = WG.NAME  
		--	INNER JOIN CFG.WORKSTREAM WS   ON WS.WorkGroupId = WG.WorkGroupId AND SWS.[Work Stream] = WS.Name 
		--	WHERE UPPER([SUB WORK STREAM NAME])<> 'DEFAULT'
		--	)
		--	INSERT INTO CFG.[SubWorkstreamInAccountNumberRange] ([SubWorkstreamId],[RangeAccountNumberId])
		--	SELECT	 DISTINCT SWS.SubWorkstreamId
		--			,ISNULL(RSC.RangeAccountNumberId,RSC1.RangeAccountNumberId)
		--	FROM SubWorkstreamCTE					SCTE
		--	LEFT JOIN CFG.SubWorkstream				SWS		ON SCTE.WORKSTREAMSEQ = SWS.WorkstreamId AND scte.[SUB WORK STREAM NAME] = SWS.Name 
		--	LEFT JOIN CFG.RangeAccountNumber		RSC		ON SCTE.[Account Number Range From] = RSC.[From] AND RSC.[To] = SCTE.[Account Number Range To] 
		--	LEFT JOIN CFG.RangeAccountNumber		RSC1	ON SCTE.[Account Number Range From] = RSC1.[To] AND RSC1.[To] = SCTE.[Account Number Range To] 
		--	WHERE  
		--	 [Account Number Range From] IS NOT NULL

					

		-----------------------23-[CFG].[SI_Group_EntityStates]----------------------
		INSERT INTO cfg.SI_Group_EntityStates 
			([SI_GroupID],[EntityState])

		SELECT 
		[SI_GroupID],
		[EntityState] FROM [import].[SI_GroupEntity states_LBG]

		----------------------24-[CFG].[SI_InstructionType]-------------------------------
		INSERT INTO CFG.SI_InstructionType
		([InstructionType],
		[ProcessCredit],
		[InstructionName],
		[InstructionCode])
		SELECT 
		InstructionType,
		ProcessCredit,
		InstructionName,
		InstructionCode
		FROM [import].SI_InstructionType_LBG

		------------------------------------------------25-[CFG].[WorkGroupInSortCodeRange]---------------------------------  
	    INSERT INTO [CFG].RangeAccountNumber([RangeAccountNumberId],[From],[To])
		SELECT ROW_NUMBER() OVER( ORDER BY [AccountNumberFrom],[AccountNumberTo] ) AS [RangeAccountNumberId],
				[AccountNumberFrom],[AccountNumberTo]
		FROM (
		SELECT  DISTINCT 
		CAST([AccountNumber From] AS INT)  AS [AccountNumberFrom],
		CAST([AccountNumber To] AS INT) AS [AccountNumberTo] 
		FROM Import.WorkGroupInSortCode_LBG
		UNION
		SELECT  DISTINCT 
		CAST([AccountNumber From] AS INT)  AS [AccountNumberFrom],
		CAST([AccountNumber To] AS INT) AS [AccountNumberTo] 
		FROM [import].[WorkStreamInAccountSortCodeRange_LBG]
		UNION
		SELECT  DISTINCT 
		CAST([Account Number Range From] AS INT)  AS [AccountNumberFrom],
		CAST([Account Number Range To] AS INT) AS [AccountNumberTo] 
		FROM [import].SubWorkStream_LBG
		)x
		GROUP BY [AccountNumberFrom],[AccountNumberTo]
		HAVING [AccountNumberTo] > 0

		
		
		INSERT INTO [CFG].RangeSortCode([RangeSortCodeId],[From],[To])
		SELECT ROW_NUMBER() OVER( ORDER BY [SortCodeRangeFrom],[SortCodeRangeTo] ) AS [RangeSortCodeId] ,
			  [SortCodeRangeFrom],[SortCodeRangeTo]
		FROM (
		SELECT  DISTINCT 
		CAST([Sort Code Range From] AS INT)  AS [SortCodeRangeFrom],
		CAST([Sort Code Range To] AS INT) AS [SortCodeRangeTo] 
		FROM Import.WorkGroupInSortCode_LBG
		UNION
		SELECT  DISTINCT 
		CAST([Sort Code Range From]AS INT)   AS [SortCodeRangeFrom],
		CAST([Sort Code Range To]AS INT)  AS [SortCodeRangeTo] 
		FROM [import].[WorkStreamInAccountSortCodeRange_LBG]
		UNION
		SELECT  DISTINCT 
		CAST([Sort Code Range From] AS INT)  AS [SortCodeRangeFrom],
		CAST([Sort Code Range To] AS INT)  AS [SortCodeRangeTo] 
		FROM [import].SubWorkStream_LBG		
		)tab
		GROUP BY [SortCodeRangeFrom],[SortCodeRangeTo]
		HAVING [SortCodeRangeTo] > 0 


		Create TABLE #TT  (
		[AccountNumberSeq]  int ,
		[SortCodeSeq] int
		)		
		INSERT INTO #TT
			 (
			 [AccountNumberSeq],			 
			 [SortCodeSeq]
			 ) 	
			 SELECT RA.RangeAccountNumberId, RSC.RangeSortCodeId
		FROM
		[import].[WorkGroupInSortCode_LBG] WGSC
		INNER JOIN CFG.WorkGroup WG ON WG.Name = WGSC.[Work Group Name]
		INNER JOIN CFG.RangeSortCode RSC ON WGSC.[Sort Code Range From] = RSC.[From] AND WGSC.[Sort Code Range To] = RSC.[To]		
		INNER JOIN CFG.RangeAccountNumber RA ON WGSC.[AccountNumber From] = RA.[From] AND WGSC.[AccountNumber To] = RA.[To]
		GROUP BY RSC.RangeSortCodeId,RA.RangeAccountNumberId
		
		INSERT INTO #TT
			 (
			 [AccountNumberSeq],			 
			 [SortCodeSeq]
			 ) 	
		 SELECT RA.RangeAccountNumberId, RSC.RangeSortCodeId
		FROM
		[import].[WorkStreamInAccountSortCodeRange_LBG] WSSC		
		INNER JOIN CFG.RangeSortCode RSC ON WSSC.[Sort Code Range From] = RSC.[From] AND WSSC.[Sort Code Range To] = RSC.[To]
		INNER JOIN CFG.RangeAccountNumber RA ON WSSC.[AccountNumber From] = RA.[From] AND WSSC.[AccountNumber To] = RA.[To]
		LEFT JOIN #TT SS ON SS.AccountNumberSeq = RA.RangeAccountNumberId AND SS.SortCodeSeq = RSC.RangeSortCodeId
		WHERE SS.[AccountNumberSeq] IS NULL 
		GROUP BY RSC.RangeSortCodeId,RA.RangeAccountNumberId
				
			INSERT INTO #TT
			 (
			 [AccountNumberSeq],			 
			 [SortCodeSeq]
			 ) 	
		 SELECT RA.RangeAccountNumberId, RSC.RangeSortCodeId
		FROM
		[import].[SubWorkStream_LBG]  WSSC		
		INNER JOIN CFG.RangeSortCode RSC ON WSSC.[Sort Code Range From] = RSC.[From] AND WSSC.[Sort Code Range To] = RSC.[To]
		INNER JOIN CFG.RangeAccountNumber RA ON WSSC.[Account Number Range From] = RA.[From] AND WSSC.[Account Number Range To] = RA.[To]
		LEFT JOIN #TT SS ON SS.AccountNumberSeq = RA.RangeAccountNumberId AND SS.SortCodeSeq = RSC.RangeSortCodeId
		WHERE SS.[AccountNumberSeq] IS NULL 
		GROUP BY RSC.RangeSortCodeId,RA.RangeAccountNumberId
 

		INSERT INTO [CFG].[SortCodeMapAccountNumber]
			 ([SortCodeMapAccountNumberSeq],[AccountNumberSeq],[SortCodeSeq]
			 )
			 SELECT ROW_NUMBER() over( order by [AccountNumberSeq],SortCodeSeq ) AS SortCodeMapAccountNumberSeq , RA.[AccountNumberSeq], RA.SortCodeSeq FROM #TT RA
			 GROUP BY [AccountNumberSeq], SortCodeSeq

        Drop TABLE #TT;

		INSERT INTO [CFG].[WorkGroupInSortCodeRange]([WorkGroupId],[SortCodeMapAccountNumberSeq])
		SELECT DISTINCT WG.WorkGroupId,	[SMA].SortCodeMapAccountNumberSeq
		FROM
		[import].[WorkGroupInSortCode_LBG] WGSC
		INNER JOIN CFG.WorkGroup WG ON WG.Name = WGSC.[Work Group Name]
		INNER JOIN CFG.RangeSortCode RSC ON WGSC.[Sort Code Range From] = RSC.[From] AND WGSC.[Sort Code Range To] = RSC.[To]	
		INNER JOIN CFG.RangeAccountNumber RA ON WGSC.[AccountNumber From] = RA.[From] AND WGSC.[AccountNumber To] = RA.[To]
		INNER JOIN CFG.[SortCodeMapAccountNumber] [SMA] ON [SMA].SortCodeSeq = [rsc].RangeSortCodeId 
												AND [SMA].AccountNumberSeq  = RA.RangeAccountNumberId
		
		INSERT INTO [CFG].[WorkstreamInAccountSortCodeRange]([WorkstreamId],[SortCodeMapAccountNumberSeq])
		SELECT  DISTINCT WS.WorkstreamId,[SMA].SortCodeMapAccountNumberSeq
		FROM
		[import].[WorkstreamInAccountSortCodeRange_LBG] WSSC			
		INNER JOIN CFG.Workstream WS ON WS.Name = WSSC.[Work Stream Name] 
		INNER JOIN CFG.RangeSortCode RSC ON WSSC.[Sort Code Range From] = RSC.[From] AND WSSC.[Sort Code Range To] = RSC.[To]
		INNER JOIN CFG.RangeAccountNumber RA ON WSSC.[AccountNumber From] = RA.[From] AND WSSC.[AccountNumber To] = RA.[To]
		INNER JOIN CFG.[SortCodeMapAccountNumber] [SMA] ON [SMA].SortCodeSeq = [rsc].RangeSortCodeId 
												AND [SMA].AccountNumberSeq  = RA.RangeAccountNumberId
        GROUP BY WS.WorkstreamId,[SMA].SortCodeMapAccountNumberSeq

        INSERT INTO CFG.[SubWorkstreamInSortCodeRange] ([SubWorkstreamId],[SortCodeMapAccountNumberSeq])
		SELECT DISTINCT WG.SubWorkstreamId,	[SMA].SortCodeMapAccountNumberSeq
		FROM [import].[SubWorkStream_LBG] WSSC	
		INNER JOIN CFG.SubWorkstream WG ON  WG.[Name] = WSSC.[Sub Work Stream Name] 		
		INNER JOIN CFG.RangeSortCode RSC ON WSSC.[Sort Code Range From] = RSC.[From] AND WSSC.[Sort Code Range To] = RSC.[To]
		INNER JOIN CFG.RangeAccountNumber RA ON WSSC.[Account Number Range From] = RA.[From] AND WSSC.[Account Number Range To] = RA.[To]
		INNER JOIN CFG.[SortCodeMapAccountNumber] [SMA] ON [SMA].SortCodeSeq = [rsc].RangeSortCodeId 
												AND [SMA].AccountNumberSeq  = RA.RangeAccountNumberId
		

		 -----------------------------------------------26-[CFG].[WorkGroupInADMapping]----------------------------------------------------
		IF (@Server = 'LIVE')
			BEGIN
				INSERT INTO CFG.WorkGroupInADMapping 
				 (ADMappingSeq,WorkGroupSeq)

				SELECT CAD.ADMappingId, WG.WorkGroupId
				FROM [import].[ADMapping_LI_LBG] AD 
				INNER JOIN CFG.WorkGroup WG on WG.[Name] = AD.[WorkGroupSeq] 
				INNER JOIN CFG.ADMapping CAD ON CAD.ADMappingId =AD.ADMappingSeq 
		END
		ELSE IF (@Server = 'SIT'  OR @Server = 'IT')
			BEGIN
				INSERT INTO CFG.WorkGroupInADMapping 
				 (ADMappingSeq,WorkGroupSeq)

				SELECT CAD.ADMappingId, WG.WorkGroupId
				FROM [import].[ADMapping_SIT_IT_LBG] AD 
				INNER JOIN CFG.WorkGroup WG on WG.[Name] = AD.[WorkGroupSeq] 
				INNER JOIN CFG.ADMapping CAD ON CAD.ADMappingId =AD.ADMappingSeq 
			END
		ELSE IF (@Server = 'TR' )
			BEGIN
			INSERT INTO CFG.WorkGroupInADMapping 
				 (ADMappingSeq,WorkGroupSeq)

				SELECT CAD.ADMappingId, WG.WorkGroupId
				FROM [import].[ADMapping_TR_LBG] AD 
				INNER JOIN CFG.WorkGroup WG on WG.[Name] = AD.[WorkGroupSeq] 
				INNER JOIN CFG.ADMapping CAD ON CAD.ADMappingId =AD.ADMappingSeq 
			END
		ELSE IF (@Server = 'TME' )
			BEGIN
			INSERT INTO CFG.WorkGroupInADMapping 
				 (ADMappingSeq,WorkGroupSeq)

				SELECT CAD.ADMappingId, WG.WorkGroupId
				FROM [import].[ADMapping_TME_LBG] AD 
				INNER JOIN CFG.WorkGroup WG on WG.[Name] = AD.[WorkGroupSeq] 
				INNER JOIN CFG.ADMapping CAD ON CAD.ADMappingId =AD.ADMappingSeq 
			END
		------------------------------22-[CFG].[WorkstreamInADMapping]-------------------------------------------------------------------------------------------
		
		INSERT INTO 
			[CFG].[WorkstreamInADMapping]
			(
				[ADMappingId],
				[WorkstreamId]
			)
		SELECT DISTINCT 
			ADMap.ADMappingSeq,
			WS.WorkstreamId
		FROM
			CFG.WorkGroupInADMapping ADMap 
		INNER JOIN 
			CFG.WorkGroup WG 
		ON 
			WG.WorkGroupId = ADMap.WorkGroupSeq
		INNER JOIN 
			CFG.Workstream WS 
		ON 
			WS.WorkGroupId = WG.WorkGroupId 

		------------------------27 - CFG.FINALDECISIONRULES-----------------------
/* 		;WITH 
			[FinalDecision_LBG]
			(
				[Index]
				,[Reason For Return]
				,[Funds Response Status]
				,[Response Sub Type]
				,[Funds Response Qualifier] 
				,[Final Decision]
				,[Final Reason For Return]
			)
		AS
		( */
		
		SELECT 
			[Index],
			[Reason For Return], 
			CASE 
				WHEN [Funds Response Status]='' 
				THEN NULL 
				ELSE [Funds Response Status] 
			END AS [Funds Response Status],
			CASE 
				WHEN [Response Sub Type]='' 
				THEN NULL 
				ELSE [Response Sub Type] 
			END AS [Response Sub Type],
			CASE 
				WHEN [Funds Response Qualifier]='' 
				THEN NULL 
				ELSE [Funds Response Qualifier] 
			END AS [Funds Response Qualifier],
			[Final Decision], 
			[Final Reason For Return]
		INTO
			#FinalDecision_LBG
		FROM 
			[import].[FinalDecision_LBG] FD

		CREATE CLUSTERED INDEX ci_ReasonForReturn ON #FinalDecision_LBG([Reason For Return])
		CREATE NONCLUSTERED INDEX ci_FundsResponseStatus_ResponseSubType ON #FinalDecision_LBG([Funds Response Status], [Response Sub Type])
		CREATE NONCLUSTERED INDEX ci_FinalDecision ON #FinalDecision_LBG([Final Decision])
		CREATE NONCLUSTERED INDEX ci_FinalReasonForReturn ON #FinalDecision_LBG([Final Reason For Return])

		INSERT INTO 
			[CFG].[FinalDecisionRule]
			(
				[FinalDecisionRuleSeq]
				,[NoPaidReasonSeq]
				,[PostingResponseStatusSeq]
				,[PostingResponseQualifierSeq]
				,[FinalDecisionSeq]
				,[FinalNoPaidReasonSeq]
			)
		SELECT 
			FD.[Index] ,
			NP.NoPayReasonCodesIndustryId
			,PS.PostingResponseStatusId
			,PQ.PostingResponseQualifierId 
			,SD.SystemDecisionId
			,NP1.NoPayReasonCodesIndustryId
		FROM 
			#FinalDecision_LBG FD
		LEFT JOIN 
			[CFG].NoPayReasonCodesIndustry NP 
		ON 
			NP.Name=FD.[Reason For Return] 
		LEFT JOIN 
			[CFG].[PostingResponseStatus] PS 
		ON 
			PS.Code=FD.[Funds Response Status] 
		AND 
			ISNULL(PS.ResponseSubType,0) = ISNULL(FD.[Response Sub Type],0)
		LEFT JOIN 
			[CFG].PostingResponseQualifier PQ 
		ON 
			RIGHT((PQ.Qualifier + 1000000),6)=RIGHT((FD.[Funds Response Qualifier]+ 1000000),6) 
		INNER JOIN 
			[CFG].SystemDecision SD 
		ON 
			SD.Name=FD.[Final Decision]
		LEFT JOIN 
			[CFG].NoPayReasonCodesIndustry NP1 
		ON 
			NP1.Name=FD.[Final Reason For Return] 

		-----------------------28.[CFG].[KappaNoPayReasonCodes]---------------------

		INSERT INTO [CFG].[KappaNoPayReasonCodes]
           ([KappaDecisionId]
           ,[FraudCheckResult]
           ,[FraudCheckReason]
           ,[Description])

			 SELECT		 KappaDecisionSeq,
						 FraudCheckResult,
						 CASE WHEN FraudCheckReason = 'NULL'
						 THEN NULL 
						 ELSE FraudCheckReason
						 END AS [FraudCheckReason],
						 [Description] 
			 FROM  [import].[KappaNoPayReasons_LBG]

		 ---------------------29.[CFG].[KappaNoPayReasonCodesMapIndustry]--------------------------------------------------------------------------
		INSERT INTO [CFG].[KappaNoPayReasonCodesMapIndustry]( [KappaDecisionId]
			  ,[NoPayReasonCodesIndustryId])
		SELECT KNP.KappaDecisionId, NP.NoPayReasonCodesIndustryId FROM [import].[KappaNoPayReasons_LBG] K
		JOIN [CFG].KappaNoPayReasonCodes KNP on KNP.[Description]=K.[Description] and KNP.FraudCheckResult=K.FraudCheckResult
		JOIN [CFG].NoPayReasonCodesIndustry NP on NP.Code=K.[IndustryCode] ORDER BY KappaDecisionSeq
		-------------------------[CFG].[MSG06Group]--------------------------------
		INSERT INTO [CFG].[MSG06Group]
		SELECT [MSG06GroupSeq], [Description] FROM [Import].[MSG06Group_LBG]
		-------------------------[CFG].[WorkGroupResponsePattern]--------------------------------
		INSERT INTO [CFG].[WorkGroupResponsePattern]
		SELECT [WorkGroupResponsePatternSeq], [WorkGroupSeq], [MSG06GroupSeq] FROM [Import].[WorkGroupResponsePattern_LBG]
		 ------------------------30-[CFG].[EntityState_Config]------------------------------------
		 INSERT INTO [CFG].[PostingResponseStatusMapQualifierGroup]
			   (
				[PostingResponseStatusMapQualifierGroupSeq],
				[Name]
			   )
			   SELECT 
					[PostingResponseStatusMapQualifierGroupSeq],
					[Name]
			   FROM [Import].[PostingResponseStatusMapQualifierGroup_LBG]


		
		INSERT INTO [CFG].[EntityState_Config]
		SELECT [EntityStateConfigSeq],
		CASE	WHEN [EntityStateSeq] = '' THEN NULL 
					WHEN [EntityStateSeq] = 'NULL' THEN NULL 
				ELSE [EntityStateSeq]
		END [EntityStateSeq],
		CASE	WHEN [PostingResponseStatusMapQualifierGroupSeq] = '' THEN NULL 
					WHEN [PostingResponseStatusMapQualifierGroupSeq] = 'NULL' THEN NULL 
				ELSE [PostingResponseStatusMapQualifierGroupSeq]
		END  [PostingResponseStatusMapQualifierGroupSeq],
		CASE	WHEN [SystemDecisionSeq] = '' THEN NULL 
					WHEN [SystemDecisionSeq] = 'NULL' THEN NULL 
				ELSE [SystemDecisionSeq]
		END [UserDecisionSeq],
		ESC.[NoPay]
		,ESC.[PostingOverride]
		FROM [import].EntityState_Config_LBG ESC
		WHERE 
		ESC.[NoPay] <>'' 

		 ------------------------31-[CFG].[EntityStateMapPostingResponseStatus]------------------------------------

		INSERT INTO [CFG].[EntityStateMapPostingResponseStatus]
		SELECT [EntityStateSeq]
				,[PostingResponseStatusSeq]
		FROM [Import].[ESMapPostingResponseStatus_LBG] 

		---------------------------32-[CFG].[DecisionerMapPostingResponseQualifier]------------------------------------------------
		INSERT INTO CFG.DecisionerMapPostingResponseQualifier
		SELECT [P].PostingResponseQualifierSeq,
			   [D].DecisionFunctionId
		FROM IMPORT.[PostingResponseQualifier_LBG] [P]
		INNER JOIN CFG.DecisionFunction [D] ON [P].Decisioner=[D].Name
		

		----------------------------33-[CFG].[DecisionItemConfig]------------------------------------------------
		
		INSERT [CFG].[DecisionItemConfig] ([Id], [WorkstreamStateId], [HeaderColor], [PassButtonText], [FailButtonText], [VerifyButtonText], [SuspendButtonText], [ShowADMandates], [ShowADStops], [ShowADKappa], [ShowADCrossExceptions], [ShowADReputablePayeeList]) VALUES (9, 1, N'#A9D08E', N'Pass', N'Fail', N'Verify', N'Suspend', 1, 1, 1, 1, 1)
		INSERT [CFG].[DecisionItemConfig] ([Id], [WorkstreamStateId], [HeaderColor], [PassButtonText], [FailButtonText], [VerifyButtonText], [SuspendButtonText], [ShowADMandates], [ShowADStops], [ShowADKappa], [ShowADCrossExceptions], [ShowADReputablePayeeList]) VALUES (10, 2, N'#FFD966', N'Pass', N'Fail', N'Verify', N'Suspend', 1, 1, 1, 1, 1)
		INSERT [CFG].[DecisionItemConfig] ([Id], [WorkstreamStateId], [HeaderColor], [PassButtonText], [FailButtonText], [VerifyButtonText], [SuspendButtonText], [ShowADMandates], [ShowADStops], [ShowADKappa], [ShowADCrossExceptions], [ShowADReputablePayeeList]) VALUES (11, 3, N'#F4B084', N'Pass', N'Fail', N'Verify', N'Suspend', 1, 1, 1, 1, 1)
		INSERT [CFG].[DecisionItemConfig] ([Id], [WorkstreamStateId], [HeaderColor], [PassButtonText], [FailButtonText], [VerifyButtonText], [SuspendButtonText], [ShowADMandates], [ShowADStops], [ShowADKappa], [ShowADCrossExceptions], [ShowADReputablePayeeList]) VALUES (12, 4, N'#9BC2E6', N'Pass', N'Fail', N'Verify', N'Suspend', 1, 1, 1, 1, 1)
		

		----------------------34--MSG13 - [CFG].[13MD_Credit_ConfigRules]------------------------------
		INSERT INTO CFG.[13MD_Credit_ConfigRules]
		SELECT 
			[13MD_Credit_ConfigRulesSeq]
			,CASE	WHEN [CreditAPGNoPayReasonCodeSeq] = '' THEN NULL 
				WHEN [CreditAPGNoPayReasonCodeSeq] = 'NULL' THEN NULL 
			ELSE [CreditAPGNoPayReasonCodeSeq]
			END
			, CASE	WHEN [CreditKappaNoPayReasonSeq] = '' THEN NULL 
				WHEN [CreditKappaNoPayReasonSeq] = 'NULL' THEN NULL 
			ELSE [CreditKappaNoPayReasonSeq]
			END	
			,[AlternateSortCode]
			,[AlternateAccount]
			,[CustomerNotificationReq]
			,[CaseManagementReq]
			,[CaseTypeID]
			,[CasePrefix]
		FROM [import].[13MD_Credit_ConfigRules_LBG]

		----------------------35 -MSG13 - [CFG].[13MD_EntityStatesMapping]--------------------------
		INSERT INTO CFG.[13MD_EntityStatesMapping]
		([13MD_EntityStatesMappingSeq],[IncomingEntityStateSeq],
		[OutboundEntityStateSeq],
		[13DMCreditOutbound],
		[Multicredit])
		SELECT  [ESSEQ]
			  ,[IncomingEntityStateSeq]
			  ,[OutboundEntityStateSeq]
			  ,[13DMCreditOutbound]
			  ,[Multicredit]
		FROM [import].[13MD_EntityStatesMapping_LBG]

		-----------------------------36-[CFG].[FraudSubReason]--------------------------------------------------------------
		INSERT INTO [CFG].[FraudSubReason]	  
		SELECT [FraudReasonSeq]
			  ,[Fraud Reason Code]
			  ,[Fraud Reason Name]
			  ,[Description]
		FROM  [Import].[FraudReason_LBG] FR

		-----------------------------36-[CFG].[UserFailReasonMapFraudReason]-------------------------------------------
		INSERT INTO [CFG].[UserFailReasonMapFraudReason]	  
		SELECT [FailReasonSeq]
			  ,[FraudReasonSeq] 
		FROM  [Import].[UserFailReasonMapFraudReason_LBG] FR

		----------------------36-CFG.BusinessRules---------------------------------

			INSERT INTO [CFG].[BusinessRule]
			   ([BusinessRuleId]
			   ,[WorkGroupId]
			   ,[WorkstreamId]
			   ,[SubWorkstreamId]
			   ,[CustomerSegmentId]
			   ,[CurrentStateId]
			   ,[UserDecisionId]
			   ,[UserFailReasonId]
			   ,[FraudReasonId]
			   ,[SystemInitialDecisionId]
			   ,[NextStateId]
			   ,[OverThresholdStateId]
			   ,[SystemDefaultDecisionId]
			   ,NoPayReasonCodesIndustryId
			   ,[DELETEd]
			   ,[UpdatedDate]
			   ,[CreatedDate]
			   ,[CreatedBy]
			   ,[UpdatedBy]
			   ,[DefaultFraudReasonId]
				)
			SELECT RD.[Index] 
					,WG.WorkGroupId  
					,WS.WorkstreamId 
					,SWS.SubWorkstreamId
					,CS.CustomerSegmentId    
					,WSS.WorkstreamStateId
					,UD.UserDecisionId
					,ufr.UserFailReasonId 
					,[FR].[FraudSubReasonSeq]
					,sd.SystemDecisionId
					,wss2.WorkstreamStateId
					,wss3.WorkstreamStateId
					,sd2.SystemDecisionId 
					,rc.NoPayReasonCodesIndustryId
					,0
					,'2017-02-12 09:55:19'
					,'2017-02-12 09:55:19'
					,'System'
					,'System'
					,[FR1].FraudSubReasonSeq
					FROM [import].[BusinessRules_LBG] RD
					INNER JOIN [CFG].WorkGroup WG on WG.Name = RD.[Workgroup] 
					INNER JOIN [CFG].WorkStream WS on WS.Name = RD.[Workstream] and ws.WorkGroupId = wg.WorkGroupId 
					LEFT  JOIN [CFG].SubWorkStream SWS on  SWS.Name = RD.[Subworkstream] and ws.WorkstreamId = sws.WorkstreamId
					INNER JOIN [CFG].CustomerSegment CS on cs.Name = RD.[Customer Segment] 
					LEFT JOIN [CFG].WorkStreamState WSS on wss.Name = RD.[Current State]
					LEFT JOIN  [CFG].[UserDecision] UD on  ud.Name = RD.[User Decision]
					LEFT JOIN [CFG].[UserFailReason] ufr on ufr.Name = rd.[User Fail Reason]
					LEFT JOIN [CFG].[SystemDecision] sd on sd.Name = rd.[System Initial Decision]
					LEFT JOIN [CFG].WorkStreamState WSS2 on wss2.Name = rd.[Next State] 
					LEFT JOIN [CFG].WorkStreamState WSS3 on wss3.Name = rd.[Over Threshold State] 
					LEFT JOIN [CFG].[SystemDecision] sd2 on sd2.Name = rd.[System Default Decision] 
					LEFT JOIN [CFG].NoPayReasonCodesIndustry rc on rc.Name = rd.[No Pay Reason]
					LEFT JOIN [CFG].[FraudSubReason] [FR] ON [FR].[Name] = [RD].[Fraud Reason]
					LEFT JOIN [CFG].[FraudSubReason] [FR1] ON [FR1].[Name] = [RD].[Default Fraud Reason]

			---------------------------37--[CFG].[ChannelType]--------------------------------

			INSERT INTO [CFG].[ChannelType]
			SELECT CAST ([ChannelTypeSeq] AS TINYINT), 
			CASE WHEN [ChannelRiskType] = 'Original'
				THEN 'Orgn'
				ELSE [ChannelRiskType]
				END AS [ChannelRiskType], CAST([Source] AS smallint),
			[Name] 
			FROM [Import].[ChannelType_LBG]

			---------------------------37.1--[CFG].[GroupChannelType]--------------------------------

			INSERT INTO [CFG].[GroupChannelType]
			SELECT CAST ([GroupChannelTypeSeq] AS TINYINT), 			
			[Name] 
			FROM [Import].[GroupChannelType_LBG]

			---------------------------37.2--[CFG].[GroupChannelTypeMapChannelType]--------------------------------

			INSERT INTO [CFG].[GroupChannelTypeMapChannelType]
			SELECT CAST ([GroupChannelTypeSeq] AS TINYINT), 			
			CAST ([ChannelTypeSeq] AS TINYINT)
			FROM [Import].[GroupChannelTypeMapCT_LBG]	

			-------------------------38--[CFG].[APGAdjustmentCode]---------------------

			INSERT INTO [CFG].[APGAdjustmentCode]
			SELECT CAST([APGAdjustmentCodeSeq] AS tinyint),
			CAST([APGAdjustmentCode] AS int) 
			FROM [Import].[APGAdjustmentCode_LBG]

			-------------------------38.5--[CFG].[InsertReasons]---------------------

			INSERT INTO [CFG].[InsertReasons]
			SELECT CAST([InsertReasonSeq] AS tinyint) AS [InsertReasonSeq],[InsertReason]			
			FROM [Import].[InsertReasons_LBG]

			-------------------------[CFG].[TransCode]---------------------

			INSERT INTO [CFG].[TransCode]
			SELECT CAST([TransCodeSeq] AS tinyint) AS [TransCodeSeq],
			CASE WHEN [TransCode] ='NULL' THEN NULL ELSE [TransCode] END [TransCode]				
			FROM [Import].[TransCode_LBG]

			-------------------------[CFG].[GroupTransCode]---------------------

			INSERT INTO [CFG].[GroupTransCode]
			SELECT CAST([GroupTransCodeSeq] AS tinyint) AS [GroupTransCodeSeq],[Name]			
			FROM [Import].[GroupTransCode_LBG]

			-------------------------[CFG].[GroupTransMapTransCode]---------------------

			INSERT INTO [CFG].[GroupTransMapTransCode]
			SELECT CAST([GroupTransCodeSeq] AS tinyint) AS [GroupTransCodeSeq], CAST([TransCodeSeq] AS tinyint)	AS [TransCodeSeq]		
			FROM [Import].[GroupTransMapTransCode_LBG]


			-------------------------[CFG].[GroupTransMapInsertReason]---------------------

			INSERT INTO [CFG].[GroupTransMapInsertReason]
			SELECT CAST([GroupTransMapInsertReasonSeq] AS TINYINT),CAST([GroupTransCodeSeq] AS tinyint), CAST([InsertReasonSeq] AS tinyint), [IsWithdraw]			
			FROM [Import].[GroupTransMapInsertReason_LBG]

			--*************************[01MD_Notification_Detail]************************

			INSERT INTO [CFG].[01MD_Notification_Detail]
			SELECT 
				CAST([01MD_Notification_DetailSeq] AS SMALLINT),	 
				[NtfyRsn],
				[NtfyRsnDesc]
			FROM [Import].[01MD_Notification_Detail_LBG]


			--*************************[01MD_Case_Detail]********************************
			INSERT INTO [CFG].[01MD_Case_Detail]
			SELECT 
					CAST([01MD_Case_DetailSeq] AS TINYINT),
					CASE	WHEN [CasePrefix] = '' THEN NULL 
							WHEN [CasePrefix] = 'NULL' THEN NULL 
								ELSE CAST([CasePrefix] AS char)
							END [CasePrefix],
					CASE	WHEN [CaseTypeID] = '' THEN NULL 
							WHEN [CaseTypeID] = 'NULL' THEN NULL 
								ELSE CAST([CaseTypeID] AS char(4))
							END [CaseTypeID],
					CASE	WHEN [CasePostfix] = '' THEN NULL 
							WHEN [CasePostfix] = 'NULL' THEN NULL 
								ELSE CAST([CasePostfix] AS char(1))
							END [CasePostfix]
			 FROM [Import].[01MD_Case_Detail_LBG]

			 --*************************[OnBank]*****************************************

			 INSERT INTO [CFG].[OnBank]
			 SELECT 
					CAST([OnBankSeq] AS TINYINT),			
					CAST([OnBank] AS TINYINT),			
					[OnBankDescription]
			 FROM [Import].[OnBank_LBG]

			 --*************************[OnBankPattern]*****************************************

			 INSERT INTO [CFG].[OnBankPattern]
			 SELECT 
					CAST([OnBankPatternSeq] AS TINYINT),
					[OnBankPatternName]
			 FROM [Import].[OnBankPattern_LBG]

			 --*************************[OnBankMapOBPattern]*****************************************

			 INSERT INTO [CFG].[OnBankMapOBPattern]
			 SELECT 
					CAST([OnBankSeq] AS TINYINT),
					CAST([OnBankPatternSeq] AS TINYINT)
			 FROM [Import].[OnBankMapOBPattern_LBG]

			  --*************************[GroupAPGNPRADJ]*****************************************

			 INSERT INTO [CFG].[GroupAPGNPRADJ]
			 SELECT 
					CAST([GroupAPGNPRADJSeq] AS INT),
					CASE	WHEN [APGNoPayReasonCodeSeq] = '' THEN NULL 
					WHEN [APGNoPayReasonCodeSeq] = 'NULL' THEN NULL 
						ELSE CAST([APGNoPayReasonCodeSeq] AS TINYINT)
					END [APGNoPayReasonCodeSeq],			
					CASE	WHEN [APGAdjustmentCodeSeq] = '' THEN NULL 
					WHEN [APGAdjustmentCodeSeq] = 'NULL' THEN NULL 
						ELSE CAST([APGAdjustmentCodeSeq] AS TINYINT)
					END [APGAdjustmentCodeSeq]
			 FROM [Import].[GroupAPGNPRADJ_LBG]

			 --*************************[APGNPRADJPattern]*****************************************

			 INSERT INTO [CFG].[APGNPRADJPattern]
			 SELECT 
					CAST([APGNPRADJPatternSeq] AS TINYINT),
					[APGNPRADJPatternDesc]
			 FROM [Import].[APGNPRADJPattern_LBG]

			 --*************************[GroupAPGMapAPGPattern]*****************************************

			 INSERT INTO [CFG].GroupAPGMapAPGPattern
			 SELECT 
					CAST([GroupAPGNPRADJSeq]   AS INT),
					CAST([APGNPRADJPatternSeq] AS TINYINT)
			 FROM [Import].[GroupAPGMapAPGPattern_LBG]

			-----------------------39--[CFG].[01MD_EntityConfig]---------------------

			INSERT INTO [CFG].[01MD_EntityConfig]
			SELECT CAST([01EC].[EntityStateSeq] AS SMALLINT),
			CAST([01EC].[IsProblematic] AS BIT) FROM [Import].[01MD_EntityConfig_LBG] [01EC]
			INNER JOIN [CFG].[EntityStates] [EC]
			ON [EC].[EntityStateId]  = CAST([01EC].[EntityStateSeq] AS SMALLINT)
						
			----------------------[01MD_APG_OutClearingAction]--------------------------------

			INSERT INTO [CFG].[01MD_APG_OutClearingAction]
			SELECT 
					CAST([01MD_APG_OutClearingActionSeq] AS INT),
					CAST([APGNPRADJPatternSeq] AS TINYINT),
					CAST([OutClearingActionSeq] AS TINYINT),
					CAST([ItemTypeSeq] AS TINYINT),
					CAST([GroupChannelTypeSeq] AS TINYINT),					
					CAST([GroupTransMapInsertReasonSeq] AS TINYINT)		
			FROM [Import].[01MD_APG_OutClearingAction_LBG]

			-----------------------[01MD_APG_OutClearingConfig]-------------------------------

			INSERT INTO [CFG].[01MD_APG_OutClearingConfig]
			SELECT 
					CAST ([01MD_APG_OutClearingConfigSeq] AS INT),
					CAST ([01MD_APG_OutClearingActionSeq] AS INT),
					CAST ([OnBankPatternSeq] AS INT),
					CAST ([TxSetOutClearingActionSeq] AS INT),
					CASE	WHEN [EntityStateSeq] = '' THEN NULL 
							WHEN [EntityStateSeq] = 'NULL' THEN NULL 
								ELSE CAST([EntityStateSeq] AS TINYINT)
							END [EntityStateSeq],
					CAST ([CustomerNotificationReq] AS BIT),
					CASE	WHEN [01MD_Notification_DetailSeq] = '' THEN NULL 
							WHEN [01MD_Notification_DetailSeq] = 'NULL' THEN NULL 
								ELSE CAST([01MD_Notification_DetailSeq] AS TINYINT)
							END [01MD_Notification_DetailSeq],
					CAST ([CaseManagementReq] AS BIT),
					CASE	WHEN [01MD_Case_DetailSeq] = '' THEN NULL 
							WHEN [01MD_Case_DetailSeq] = 'NULL' THEN NULL 
							ELSE CAST([01MD_Case_DetailSeq] AS TINYINT)
							END [01MD_Case_DetailSeq],
					CAST ([IsAgency] AS BIT)
			 FROM [Import].[01MD_APG_OutClearingConfig_LBG] 
 
		 -------------------------42--[CFG].[01MD_Fraud_OutClearingAction]------------------------

		 INSERT INTO [CFG].[01MD_Fraud_OutClearingAction]
		 SELECT CAST([01MD_Fraud_OutClearingActionSeq] AS smallint),
		 CAST([KappaDecisionSeq] AS tinyint),
		 CAST([OutClearingActionSeq] AS tinyint),
		 CAST([GroupChannelTypeSeq] AS tinyint),
		 CASE	WHEN [IsAgency] = '' THEN NULL 
					WHEN [IsAgency] = 'NULL' THEN NULL 
						ELSE CAST([IsAgency] AS BIT)
				END [IsAgency]
		 FROM [Import].[01MD_Fraud_OutClearingAction_LBG]

		 -------------------------43-[CFG].[01MD_Fraud_OutClearingConfig]------------------------

		INSERT INTO [CFG].[01MD_Fraud_OutClearingConfig]
		SELECT CAST ([01MD_Fraud_OutClearingConfigSeq] AS smallint),
		CASE	WHEN [KappaDecisionSeq] = '' THEN NULL 
					WHEN [KappaDecisionSeq] = 'NULL' THEN NULL 
						ELSE CAST([KappaDecisionSeq] AS tinyint)
				END [KappaDecisionSeq],
		CASE	WHEN [OnBank] = '' THEN NULL 
					WHEN [OnBank] = 'NULL' THEN NULL 
						ELSE CAST([OnBank] AS tinyint)
				END [OnBank],
		CAST([GroupChannelTypeSeq] AS tinyint),
		CASE	WHEN [TxSetOutClearingActionSeq] = '' THEN NULL 
					WHEN [TxSetOutClearingActionSeq] = 'NULL' THEN NULL 
						ELSE CAST([TxSetOutClearingActionSeq] AS tinyint)
				END [TxSetOutClearingActionSeq],
		CASE	WHEN [ItemTypeSeq] = '' THEN NULL 
					WHEN [ItemTypeSeq] = 'NULL' THEN NULL 
						ELSE CAST([ItemTypeSeq] AS tinyint)
				END [ItemTypeSeq],
		CAST([IsAgency] AS BIT),
		CAST([CustomerNotificationReq] AS BIT),
		CAST([CaseManagementReq] AS bit),
		CASE	WHEN [CaseTypeID] = '' THEN NULL 
					WHEN [CaseTypeID] = 'NULL' THEN NULL 
						ELSE CAST([CaseTypeID] AS char(4))
				END [CaseTypeID],
		CASE	WHEN [CasePrefix] = '' THEN NULL 
					WHEN [CasePrefix] = 'NULL' THEN NULL 
						ELSE CAST([CasePrefix] AS char)
				END [CasePrefix],
		CASE	WHEN [CasePostfix] = '' THEN NULL 
					WHEN [CasePostfix] = 'NULL' THEN NULL 
						ELSE CAST([CasePostfix] AS char(1))
				END [CasePostfix]
		 FROM [Import].[01MD_Fraud_OutClearingConfig_LBG]
		 ----------------------44--[CFG].[01MD_EntityStatesMapping]----------------------

		 INSERT INTO [CFG].[01MD_EntityStatesMapping]
		 SELECT [MessageType],CAST([ItemTypeSeq] AS TINYINT),
		 CAST([OutClearingActionSeq] AS tinyint),
		 CAST([01MD_OutEntityStateSeq] AS smallint) FROM [Import].[01MD_EntityStatesMapping_LBG]		 		 

		--------------------46--[CFG].[01MD_Notification_Kappa_Config]-----------------------

		INSERT INTO [CFG].[01MD_Notification_Kappa_Config]
		SELECT CAST ([01MD_NotificationKappaConfigSeq] AS smallint),
		CAST ([ItemTypeSeq] AS tinyint),
		CAST([01MD_Fraud_OutClearingActionSeq] AS smallint),
		[NtfyRsn],[NtfyRsnDesc]
		FROM [Import].[01MD_Notification_Kappa_Config_LBG]

		/**********************47*[CFG].[03MD_Field]*************************************************************************************************************/
		INSERT INTO [CFG].[03MD_Field] (
					[FieldSeq], 
					[FieldName], 
					[ItemTypeSeq], 
					[ValidationType], 
					[ValidationLength], 
					[ValidationMinLength], 
					[ValidationFailureMessage], 
					[ClassName], 
					[Type], 
					[IsCodeLine]
					) 
		SELECT	[FieldSeq], 
				[FieldName], 
				[ItemTypeSeq], 
				[ValidationType], 
				[ValidationLength], 
				[ValidationMinLength], 
				[ValidationFailureMessage], 
				[ClassName], 
				[Type], 
				[IsCodeLine] 
		FROM [Import].[03MD_Field_LBG]

		--------------------48--[CFG].[03MD_Error]-----------------------
		INSERT INTO [CFG].[03MD_Error]
				   ([ErrorSeq]
				   ,[Code]
				   ,[PossibleSolution]
				   ,[ScreenPriority])
		SELECT [ErrorSeq]
			  ,[ErrorCode]
			  ,[PossibleSolution]
			  ,[ScreenPriority]
		  FROM [Import].[03MD_Error_LBG]

		  --------------------49--[CFG].[03MD_ErrorMappingAction]-----------------------
			INSERT INTO [CFG].[03MD_ErrorMappingAction]
				   ([ErrorSeq]
				   ,[03MD_OutClearingActionSeq])
			SELECT [ErrorSeq]
			  ,[03MD_OutClearingActionSeq]
			FROM [Import].[03MD_ErrorMappingAction_LBG]

		 --------------------50--[CFG].[03MD_ErrorMappingField]-----------------------
			INSERT INTO [CFG].[03MD_ErrorMappingField]
					   ([ErrorSeq]
					   ,[FieldSeq])
			SELECT [ErrorSeq]
				  ,[FieldSeq]
			FROM [Import].[03MD_ErrorMappingField_LBG]

			--------------------51--[CFG].[03MD_OutClearingConfig]-----------------------
			INSERT INTO [CFG].[03MD_OutClearingConfig]
					   ([03MD_OutClearingConfigSeq]
					   ,[ErrorSeq]
					   ,[OnBank]
					   ,[IsAgency]
					   ,[ItemTypeSeq]
					   ,[ActionSeq]
					   ,[TxSetOutClearingActionSeq]
					   ,[IsCodeline]
					   ,[CustomerNotificationReq]
					   ,[CaseManagementReq]
					   ,[CaseTypeID]
					   ,[CasePrefix]
					   ,[CasePostfix]
					   ,[NtfyRsn]
					   ,[NtfyRsnDesc]
					   ,[ItemAdjustmentCode])
			SELECT [03MD_OutClearingConfigSeq]
				  ,CASE WHEN [ErrorSeq]='NULL' THEN NULL ELSE [ErrorSeq] END [ErrorSeq]
				  ,CASE WHEN [OnBank]='NULL' THEN NULL ELSE [OnBank] END [OnBank]
				  ,[IsAgency]
				  ,[ItemTypeSeq]
				  ,CASE WHEN [ActionSeq]='NULL' THEN NULL ELSE [ActionSeq] END [ActionSeq]
				  ,CASE WHEN [TxSetOutClearingActionSeq]='NULL' THEN NULL ELSE [TxSetOutClearingActionSeq] END [TxSetOutClearingActionSeq]
				  ,CASE WHEN [IsCodeline]='NULL' THEN NULL ELSE [IsCodeline] END [IsCodeline]
				  ,[CustomerNotificationReq]
				  ,[CaseManagementReq]
				  ,CASE WHEN [CaseTypeID]='NULL' THEN NULL ELSE [CaseTypeID] END [CaseTypeID]
				  ,CASE WHEN [CasePrefix]='NULL' THEN NULL ELSE [CasePrefix] END [CasePrefix]
				  ,CASE WHEN [CasePostfix]='NULL' THEN NULL ELSE [CasePostfix] END [CasePostfix]
				  ,CASE WHEN [NtfyRsn]='NULL' THEN NULL ELSE [NtfyRsn] END [NtfyRsn]
				  ,CASE WHEN [NtfyRsnDesc]='NULL' THEN NULL ELSE [NtfyRsnDesc] END [NtfyRsn]
				  ,[ItemAdjustmentCode]
			  FROM [Import].[03MD_OutClearingConfig_LBG]

			--------------------52--[CFG].[03DM_EntityStatesMapping]-----------------------
			INSERT INTO [CFG].[03DM_EntityStatesMapping]
					   ([03DM_EntityStatesMappingSeq]
					   ,[ItemTypeSeq]
					   ,[03MD_OutClearingActionSeq]
					   ,[03DM_OutEntityStateSeq]
					   ,[IsCodeline]
					   ,[IsItemError])
				SELECT [03DM_EntityStatesMappingSeq]
					   ,[ItemTypeSeq]
					   ,CASE WHEN [03MD_OutClearingActionSeq]='NULL' THEN NULL ELSE [03MD_OutClearingActionSeq] END [03MD_OutClearingActionSeq]
					   ,[03DM_OutEntityStateSeq]
					   ,CASE WHEN [IsCodeline]='NULL' THEN NULL ELSE [IsCodeline] END [IsCodeline]
					   ,CASE WHEN [IsItemError]='NULL' THEN NULL ELSE [IsItemError] END [IsItemError]
			  FROM [Import].[03DM_EntityStatesMapping_LBG]

			  --------------------52--[CFG].[03DM_EntityStatesMapping]-----------------------
			 INSERT INTO [CFG].[06MD_APG_InClearingAction]
			 SELECT [APGNoPayReasonCodeSeq],
					[CasePrefix],
					[CaseTypeId],
					[Suffix]
			 FROM  [Import].[06MD_APG_InClearingAction_LBG]

			  --------------------30--MSG13 - [CFG].[SI_GroupMapping]-----------------------------
 
				;WITH TransformedSITable(SI_GroupId,SpecialInstructionType ,IsRepresentable)
				AS(
				SELECT		SI_GroupId,SIType 
						,	IsRepresentable
				FROM		[import].[SI_GroupMapping_LBG]
				UNPIVOT 
				(	
							SIApplicable  FOR SIType IN 
							([Additional Details]
						,	[Alternative Address]
						,	[Detailed Advice]
						,	[Alternative Account]
						,	[Lotted Account]
						,   [Default]
						,	[SI Not Representable]
						)
				) AS Unp
				WHERE SIApplicable != 0
				)
				INSERT INTO CFG.SI_GroupMapping
				(
							InstructionType
						,	Representable
						,	SI_GroupID
				)
				SELECT  
							InsType.InstructionType
						,	IsRepresentable
						,	SI_GroupId
				FROM		TransformedSITable TSI
				INNER JOIN	CFG.SI_InstructionType InsType ON TSI.SpecialInstructionType  = InsType.InstructionName

			-----------------------24-[CFG].[ReputablePayee]------------------------------------------------------------------

			INSERT INTO [CFG].[ReputablePayee] (ReputablePayeeId,[Name],[CreatedDate],UpdatedDate,CreatedBy,UpdatedBy,Deleted)
			SELECT [ReputablePayeeSequence]
				  ,
				  [Name]
				  ,GetDate()
				  ,GetDate()
				  ,Original_Login()
				  ,Original_Login()
				  ,0
			FROM [Import].[ReputablePayee_LBG] 

			-----------------------25-[CFG].[FinalDecisionText]------------------------------------------------------------------
			INSERT INTO [CFG].[FinalDecisionText] ([FinalDecisionTextSeq],
						[SystemDecisionSeq],
						[UserDecisionSeq],
						[BusinessRuleDecisionSeq],
						[FinalDecisionSeq],
						[PostingDecisionSeq],
						[FinalPaymentStatusText])
			SELECT 
			[FinalDecisionTextSeq]
			,CASE WHEN [SystemDecisionSeq] ='NULL' THEN NULL ELSE [SystemDecisionSeq] END [SystemDecisionSeq]
			,CASE WHEN [UserDecisionSeq] ='NULL' THEN NULL ELSE [UserDecisionSeq] END [UserDecisionSeq]
			,CASE WHEN [BusinessRuleDecisionSeq] ='NULL' THEN NULL ELSE [BusinessRuleDecisionSeq] END [BusinessRuleDecisionSeq]
			,CASE WHEN [FinalDecisionSeq] ='NULL' THEN NULL ELSE [FinalDecisionSeq] END [FinalDecisionSeq]
			,CASE WHEN [PostingDecisionSeq] ='NULL' THEN NULL ELSE [PostingDecisionSeq] END [PostingDecisionSeq]
			,CASE WHEN [FinalPaymentStatusText] ='NULL' THEN NULL ELSE [FinalPaymentStatusText] END [FinalPaymentStatusText]
			FROM  [Import].[FinalDecisionText_LBG]

		    INSERT INTO [CFG].[IndustryNoPayReasonMapUserFailReason]
					([NoPayReasonCodesIndustrySeq],
					 [UserFailReasonSeq])
			SELECT [NoPayReasonCodesIndustrySeq],
				   [UserFailReasonSeq]
		    FROM [Import].[IndustryNoPayReasonMapUserFailReason_LBG]

			-----------------------26-[CFG].[DecisionFunctionMapKappaNopayReason]------------------------------------------------------------------
			INSERT INTO [CFG].[DecisionFunctionMapKappaNopayReason] (KappaDecisionId, DecisionFunctionId)
			SELECT KappaDecisionId, DecisionFunctionId FROM [Import].[DecisionFunctionMapKappaNopayReason_LBG]

			
			---------------------------54-[CFG].[[UserPreference]]---------------------------------------------------------------------------------
			
			INSERT INTO [CFG].[UserPreference]
				(
				 [UserPreferenceSeq], 
				 [IsAdditionalDetailCNRequired],                     
				 [NarrativePrefix] 
				)
			SELECT	 [UserPreferenceSeq]
					,[IsAdditionalDetailCNRequired] 
					,[NarrativePrefix]									
			FROM [Import].[UserPreference_LBG] 

			---------------------------55-[CFG].[WorkStreamCassConfig]---------------------------------------------------------------------------------
			
			INSERT INTO [CFG].[WorkStreamCassConfig]
				(
					[WorkStreamCassConfigSeq]
					,[WorkStreamSeq]
					,[IsSwitchedItem]
					,[IsISOStop]		
					,[IsAPGStop]		
					,[IsISODuplicate]
					,[IsAPGDuplicate]
				)
			SELECT	[WorkStreamCassConfigSeq]
					,[WorkStreamSeq]
					,[IsSwitchedItem]
					,[IsISOStop]		
					,[IsAPGStop]		
					,[IsISODuplicate]
					,[IsAPGDuplicate]									
			FROM [Import].[WorkStreamCassConfig_LBG] 


			---------------------------54-[CFG].[AgencyType]---------------------------------------------------------------------------------
			INSERT INTO [CFG].[AgencyType]
				(
				[AgencyTypeId],
				[Description],
				[IsPayingFlow],
				[IsCollectingFlow],
				[IsBeneficiaryFlow]
				)
			SELECT	[AgencyTypeId],
					[Description],
					[IsPayingFlow],
					[IsCollectingFlow],
					[IsBeneficiaryFlow]									
			FROM [Import].[AgencyType_LBG]
				   ---------------------------55-[CFG].[WorkstreamInSortCodeRange]---------------------------------------------------------------------------------
			
			   ---------------------------54-[CFG].[WorkstreamInSortCodeRange]---------------------------------------------------------------------------------
			

		---------------------------55-[CFG].[PostingResponseStatusMapQualifierGroup]---------------------------------------------------------
			
		 ---------------------------56-[CFG].[PostingResponseStatusMapQualifier]---------------------------------------------------------
			    INSERT INTO [CFG].[PostingResponseStatusMapQualifier]
			   (
				[PostingResponseStatusMapQualifierSeq],
				[PostingResponseStatusMapQualifierGroupSeq],
				[PostingResponseStatusSeq],
				[PostingResponseQualifierSeq]
			   )
			   SELECT 
					[PostingResponseStatusMapQualifierSeq],
					[PostingResponseStatusMapQualifierGroupSeq],
					CASE 
						WHEN [PostingResponseStatusSeq] = '' THEN NULL 
						WHEN [PostingResponseStatusSeq] = 'NULL' THEN NULL 
				    ELSE [PostingResponseStatusSeq]
				    END  [PostingResponseStatusSeq],
					CASE	WHEN [PostingResponseQualifierSeq] = '' THEN NULL 
							WHEN [PostingResponseQualifierSeq] = 'NULL' THEN NULL 
					ELSE [PostingResponseQualifierSeq]
					END  [PostingResponseQualifierSeq]
			   FROM [Import].[PostingResponseStatusMapQualifier_LBG]

			    ---------------------------57-[CFG].[WorkgroupFinalResponse]---------------------------------------------------------
			   INSERT INTO [CFG].[WorkgroupFinalResponse]
			   (
				[WorkgroupFinalResponseSeq],
				[MSG06GroupSeq],
				[EntityStateConfigSeq],
				[FinalProcess]
			   )
			   SELECT 
					[WorkgroupFinalResponseSeq],
					[MSG06GroupSeq],
					[EntityStateConfigSeq],
					[FinalProcess]
			   FROM [Import].[WorkgroupFinalResponse_LBG]	


		END

    END;
GO

EXECUTE [sys].[sp_addextendedproperty] @name = N'Version', @value = N'1.0.0',
    @level0type = N'SCHEMA', @level0name = N'CFG',
    @level1type = N'PROCEDURE', @level1name = N'usp_InsertCFG_LBG';

GO
EXECUTE [sys].[sp_addextendedproperty] @name = N'MS_Description',
    @value = N'Insert into LBG CFG Tables',
    @level0type = N'SCHEMA', @level0name = N'CFG',
    @level1type = N'PROCEDURE', @level1name = N'usp_InsertCFG_LBG';

GO
EXECUTE [sys].[sp_addextendedproperty] @name = N'Component',
    @value = N'iPSL.iCE.DEW.Database', @level0type = N'SCHEMA',
    @level0name = N'CFG', @level1type = N'PROCEDURE',
    @level1name = N'usp_InsertCFG_LBG';
