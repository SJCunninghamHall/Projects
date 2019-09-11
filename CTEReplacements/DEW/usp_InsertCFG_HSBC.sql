CREATE PROCEDURE [CFG].[usp_InsertCFG_HSBC]
	@Server VARCHAR(50)
AS
	BEGIN
		SET NOCOUNT ON;

		SET @Server = UPPER(@Server);

		IF (
			@Server = 'LIVE'
		OR		@Server = 'SIT'
		OR		@Server = 'IT'
		OR		@Server = 'TR'
		OR		@Server = 'TME'
		)
			BEGIN

				INSERT	INTO
					CFG.[Configuration]
					(
						[Name],
						[Value]
					)
				SELECT
					[Name]	,
					[Value]
				FROM
					[Import].[Configuration_HSBC];

				-----------------------------Direct Insert Into CFG tables------------------------------------------------
				UPDATE
					[import].[WorkGroup_HSBC]
				SET
				[AmountTo]	= '999999999.99'
				WHERE 
					[AmountTo]	= '1000000000';

				-----------------------------[CFG].[DecisionFunction]------------------------------------------------			
				INSERT
					[CFG].[DecisionFunction]
					(
						[DecisionFunctionId],
						[Name],
						[ForTechnicalValidation]
					)
				SELECT
					[DecisionFunctionId],
					[Name],
					[ForTechnicalValidation]
				FROM
					[Import].[DecisionFunction_HSBC];

				-----------------------------[CFG].[ImportIdentifier]------------------------------------------------
				INSERT
					[CFG].[ImportIdentifier]
					(
						[ImportIdentifierId],
						[ExceptionType]
					)
				VALUES
					(
						1, N'Default'
					);
				INSERT
					[CFG].[ImportIdentifier]
					(
						[ImportIdentifierId],
						[ExceptionType]
					)
				VALUES
					(
						2, N'EM_299'
					);
				INSERT
					[CFG].[ImportIdentifier]
					(
						[ImportIdentifierId],
						[ExceptionType]
					)
				VALUES
					(
						3, N'Other exception'
					);

				------------------[CFG].[Duplicates]---------------------------------------------------
				INSERT INTO
					[CFG].[Duplicates]
				VALUES
					(
						1, 'PART'
					);
				INSERT INTO
					[CFG].[Duplicates]
				VALUES
					(
						2, 'FULL'
					);

				------------------[CFG].[StopsCodesIndustry]---------------------------------------------------
				INSERT
					[CFG].[StopsCodesIndustry]
					(
						[StopsCodesIndustryId],
						[StopsCode]
					)
				VALUES
					(
						1, N'PARA'
					);
				INSERT
					[CFG].[StopsCodesIndustry]
					(
						[StopsCodesIndustryId],
						[StopsCode]
					)
				VALUES
					(
						2, N'FULL'
					);
				INSERT
					[CFG].[StopsCodesIndustry]
					(
						[StopsCodesIndustryId],
						[StopsCode]
					)
				VALUES
					(
						3, N'PARS'
					);

				----------------------------------[CFG].[CustomerSegment]---------------------------------------------------------
				INSERT INTO
					[CFG].[CustomerSegment]
					(
						[CustomerSegmentId],
						[Name],
						[UpdatedDate],
						[CreatedDate],
						[CreatedBy],
						[UpdatedBy],
						[DELETEd]
					)
				SELECT
					[CustomerSegmentSeq],
					[Name],
					GETDATE(),
					GETDATE(),
					ORIGINAL_LOGIN(),
					ORIGINAL_LOGIN(),
					0
				FROM
					[import].[CustomerSegment_HSBC];
				-----------------------------1.[CFG].[UserFailReason]------------------------------------------------
				INSERT INTO
					[CFG].[UserFailReason]
				SELECT
					[UserFailReasonSeq],
					FR.[Name]
				FROM
					[Import].[FailureReasons_HSBC] AS FR;

				---------------------        2.[CFG].[NoPayReasonCodesIndustry]-----------------------------------------------  
				INSERT INTO
					[CFG].[NoPayReasonCodesIndustry]
					(
						[NoPayReasonCodesIndustryId],
						[Name],
						[Code],
						[LastUpdated],
						[CreatedDate],
						[CreatedBy],
						[UpdatedBy],
						[BankMaxRepresntCount],
						[DaysDelayForRepresent]
					)
				SELECT
					[NoPayReasonCodesIndustrySeq],
					[Name],
					[Code],
					GETDATE(),
					GETDATE(),
					ORIGINAL_LOGIN(),
					ORIGINAL_LOGIN(),
					[BankMaxRepresntCount],
					[DaysDelayForRepresent]
				FROM
					[Import].[NoPayIndustry_HSBC];

				----------------------------3.[CFG].[NoPayReasonCodesIndustry_Config]--------------------------------------
				INSERT INTO
					CFG.NoPayReasonCodesIndustry_Config
					(
						[NoPayReasonCodeId],
						[MessageType],
						[CustomerNotificationReq],
						[CaseManagementReq],
						[CasePrefix]
					)
				SELECT
					NP	.[NoPayReasonCodesIndustryId],
					DNI.MESSAGETYPE,
					DNI.[CustomerNotificationReq],
					DNI.[CaseManagementReq],
					DNI.[CasePrefix]
				FROM
					[import].NoPayIndustry_HSBC		AS DNI
				JOIN
					CFG.NoPayReasonCodesIndustry	AS NP
				ON
					DNI.NoPayReasonCodesIndustrySeq = NP.NoPayReasonCodesIndustryId;

				---------------------------4.[CFG].[UserType]--------------------------------------------------------------
				INSERT INTO
					[CFG].[UserType]
					(
						[UserTypeId],
						[Name],
						[DELETEd],
						[CreatedDate],
						[UpdatedDate],
						[CreatedBy],
						[UpdatedBy]
					)
				SELECT
					[UserTypeSeq],
					[Name],
					0,
					GETDATE(),
					GETDATE(),
					ORIGINAL_LOGIN(),
					ORIGINAL_LOGIN()
				FROM
					[import].[UserType_HSBC];

				--------------------------5.[CFG].[Role]----------------------------------------------------------------
				INSERT INTO
					[CFG].[Role]
					(
						[RoleId],
						[Name],
						[ControllerName],
						[ActionName],
						[Parameter],
						[ParentId]
					)
				SELECT
					[RoleSeq],
					[Name],
					[ControllerName],
					[ActionName],
					NULL,
					NULL
				FROM
					[import].[Role_HSBC];


				UPDATE
					[CFG].[Role]
				SET
				ParentId	= NULL
				WHERE
					ParentId = 0;

				----------------------------6.[CFG].[UserTypeInRole]-------------------------------------------------------------------------

				INSERT INTO
					[CFG].[UserTypeInRole]
					(
						[UserTypeId],
						[RoleId]
					)
				SELECT
					UserTypeSeq,
					RoleSeq
				FROM
					Import.[UserTypeInRole_HSBC];

				----------------------------7.[CFG].[ADMapping]------------------------------------------------
				IF (@Server = 'LIVE')
					BEGIN
						INSERT	INTO
							[CFG].[ADMapping]
							(
								[ADMappingId],
								[UserTypeId],
								[ADGroupName],
								[ReviewThreshold],
								[DELETEd],
								[CreatedDate],
								[UpdatedDate],
								[CreatedBy],
								[UpdatedBy]
							)
						SELECT
							AD	.[ADMappingSeq],
							UT.[UserTypeId],
							AD.[ADGroupName],
							AD.[ReviewThreshold],
							0,
							GETDATE(),
							GETDATE(),
							ORIGINAL_LOGIN(),
							ORIGINAL_LOGIN()
						FROM
							[Import].[ADMapping_LI_HSBC]	AS AD
						JOIN
							CFG.UserType					AS UT
						ON
							UT.Name = AD.[UserTypeSeq];
					END;
				ELSE IF (
							@Server = 'SIT'
					OR		@Server = 'IT'
						)
						BEGIN
							INSERT	INTO
								[CFG].[ADMapping]
								(
									[ADMappingId],
									[UserTypeId],
									[ADGroupName],
									[ReviewThreshold],
									[DELETEd],
									[CreatedDate],
									[UpdatedDate],
									[CreatedBy],
									[UpdatedBy]
								)
							SELECT
								AD	.[ADMappingSeq],
								UT.[UserTypeId],
								AD.[ADGroupName],
								AD.[ReviewThreshold],
								0,
								GETDATE(),
								GETDATE(),
								ORIGINAL_LOGIN(),
								ORIGINAL_LOGIN()
							FROM
								[import].[ADMapping_SIT_IT_HSBC]	AS AD
							JOIN
								CFG.UserType						AS UT
							ON
								UT.Name = AD.[UserTypeSeq];
						END;
				ELSE IF (@Server = 'TR')
						BEGIN
							INSERT	INTO
								[CFG].[ADMapping]
								(
									[ADMappingId],
									[UserTypeId],
									[ADGroupName],
									[ReviewThreshold],
									[DELETEd],
									[CreatedDate],
									[UpdatedDate],
									[CreatedBy],
									[UpdatedBy]
								)
							SELECT
								AD	.[ADMappingSeq],
								UT.[UserTypeId],
								AD.[ADGroupName],
								AD.[ReviewThreshold],
								0,
								GETDATE(),
								GETDATE(),
								ORIGINAL_LOGIN(),
								ORIGINAL_LOGIN()
							FROM
								[import].[ADMapping_TR_HSBC]	AS AD
							JOIN
								CFG.UserType					AS UT
							ON
								UT.Name = AD.[UserTypeSeq];
						END;

				ELSE IF (@Server = 'TME')
						BEGIN
							INSERT	INTO
								[CFG].[ADMapping]
								(
									[ADMappingId],
									[UserTypeId],
									[ADGroupName],
									[ReviewThreshold],
									[DELETEd],
									[CreatedDate],
									[UpdatedDate],
									[CreatedBy],
									[UpdatedBy]
								)
							SELECT
								AD	.[ADMappingSeq],
								UT.[UserTypeId],
								AD.[ADGroupName],
								AD.[ReviewThreshold],
								0,
								GETDATE(),
								GETDATE(),
								ORIGINAL_LOGIN(),
								ORIGINAL_LOGIN()
							FROM
								[import].[ADMapping_TME_HSBC]	AS AD
							JOIN
								CFG.UserType					AS UT
							ON
								UT.Name = AD.[UserTypeSeq];
						END;


				---------------------------8.[CFG].[APGNoPayReasonCodes]----------------------------------------------------------------
				INSERT INTO
					[CFG].[APGNoPayReasonCodes]
					(
						[APGNoPayReasonCodeId],
						[APGNoPayReasonCode],
						[IsMultiIndicator]
					)
				SELECT
					[APGNoPayReasonCodeSeq],
					[APGNoPayReasonCode],
					[IsMultiIndicator]
				FROM
					[import].[APGNoPayCodes_HSBC];

				--------------------------9.[CFG].[APGNoPayReasonCodesMapIndustry]----------------------------------------------------------------
				INSERT INTO
					[CFG].[APGNoPayReasonCodesMapIndustry]
					(
						[APGNoPayReasonCodeId],
						NoPayReasonCodesIndustryId
					)
				SELECT
					AC	.[APGNoPayReasonCodeId],
					NPI.[NoPayReasonCodesIndustryId]
				FROM
					[import].[APGNoPayCodes_HSBC]	AS APR
				JOIN
					CFG.NoPayReasonCodesIndustry	AS NPI
				ON
					NPI.Code = APR.[IndustryCode]
				JOIN
					CFG.APGNoPayReasonCodes			AS AC
				ON
					AC.APGNoPayReasonCode = APR.[APGNoPayReasonCode];

				----------------------------------38--[CFG].[RangeAccountNumber]--------------------------------------------------------
				--INSERT [CFG].[RangeAccountNumber]
				--select  [RangeAccountNumberSeq] 
				--		,[From]
				--		,[To]
				--From [import].[RangeAccountNumber_HSBC] 

				-------------------------10.[CFG].[UserProcessCodes]---------------------------------
				INSERT INTO
					[CFG].[UserProcessCodes]
					(
						[UserProcessCodesId],
						[Name]
					)
				SELECT
					[INDEX],
					[NAME]
				FROM
					[import].[UserProcessCodes_HSBC];

				-------------------------11.[CFG].[UserDecision]----------------------------------------
				INSERT INTO
					[CFG].[UserDecision]
					(
						[UserDecisionId],
						[Name]
					)
				SELECT
					[UserDecisionSeq],
					[Name]
				FROM
					[import].[UserDecision_HSBC];

				------------------------12.[CFG].[ProcessInADMapping]-------------------------
				INSERT INTO
					[CFG].[ProcessInADMapping]
					(
						[ADMappingId],
						[UserProcessCodesId]
					)
				SELECT
							ADMap.ADMappingId,
							UPC.UserProcessCodesId
				FROM
							CFG.ADMapping			AS ADMap
				CROSS JOIN	CFG.UserProcessCodes	AS UPC;
				----------------------- 13.[CFG].[WorkstreamState]-----------------------------
				INSERT INTO
					[CFG].[WorkstreamState]
					(
						[WorkstreamStateId],
						[UserProcessCodesSeq],
						[Name],
						[AgencyDisplayName]
					)
				SELECT
					[INDEX],
					UG.UserProcessCodesId,
					WSS.name,
					agencydisplayname
				FROM
					[import].[WorkStreamState_HSBC] AS WSS
				LEFT OUTER JOIN
					CFG.UserProcessCodes			AS UG
				ON
					WSS.name = UG.Name;

				---------------------------------------------32.[CFG].[WORKGROUP]----------------------------------------------------------------------------------------------------------------------------------------------------  
				INSERT INTO
					[CFG].[WorkGroup]
					(
						[WorkGroupId],
						[Name],
						[PostingResponseRequired],
						[AmountFrom],
						[AmountTo],
						[Priority],
						[DELETEd],
						[AlwaysNoPay],
						[AlwaysNoPayReasonId],
						[CustomerNotificationEnabled],
						[AgencyId]
					)
				SELECT
					[WorkGroupSeq]	,
					WG.[Name],
					[PostingResponseRequired],
					[AmountFrom],
					[AmountTo],
					[Priority],
					0,
					[AlwaysNoPay],
					[NI].[NoPayReasonCodesIndustryId],
					[WG].[CustomerNotificationEnabled],
					CASE
						WHEN [AgencyId] = ''
						THEN NULL
						WHEN [AgencyId] = 'NULL'
						THEN NULL
						ELSE [AgencyId]
					END AS [AgencyId]
				FROM
					[Import].[WorkGroup_HSBC]		AS WG
				LEFT JOIN
					CFG.NoPayReasonCodesIndustry	AS NI
				ON
					NI.[Name] = WG.[AlwaysNoPayReasonSeq];

				------------------------14.[CFG].[EntityStates]---------------------------------------------------------
				INSERT INTO
					[CFG].[EntityStates]
					(
						[EntityStateId],
						[EntityState],
						[Description],
						[MessageType]
					)
				SELECT
					[EntityStateSeq],
					[EntityState],
					[Description],
					[MessageType]
				FROM
					[import].[EntityStates_HSBC];
				----------------------15.[CFG].[PostingResponseQualifier]------------------
				INSERT INTO
					[CFG].[PostingResponseQualifier]
					(
						[PostingResponseQualifierId],
						[Qualifier],
						[Name],
						[Priority]
					)
				SELECT
					[PostingResponseQualifierSeq],
					[Qualifier],
					[Name],
					[Priority]
				FROM
					[import].[PostingResponseQualifier_HSBC];

				---------------------16.[CFG].[PostingResponseStatus]-----------------------------------------------------------------
				INSERT INTO
					[CFG].[PostingResponseStatus]
					(
						[PostingResponseStatusId],
						[Code],
						[ResponseSubType],
						[ExcessManagement]
					)
				SELECT
					[PostingResponseStatusSeq]	,
					[Code],
					CASE
						WHEN [ResponseSubType] = ''
						THEN NULL
						WHEN [ResponseSubType] = 'NULL'
						THEN NULL
						ELSE [ResponseSubType]
					END							AS [ResponseSubType],
					[ExcessManagement]
				FROM
					[import].[PostingResponseStatus_HSBC];


				----------------------17.[CFG].[DecisionerMapAPGNoPayReasonCodes]-----------------------------------

				INSERT INTO
					[CFG].[DecisionerMapAPGNoPayReasonCodes]
					(
						[APGNoPayReasonCodeId],
						[DecisionFunctionId]
					)
				SELECT
					CFGANPR.APGNoPayReasonCodeId,
					DF.DecisionFunctionId
				FROM
					[import].[APGNoPayCodes_HSBC]	AS ANPR
				INNER JOIN
					[CFG].[APGNoPayReasonCodes]		AS CFGANPR
				ON
					ANPR.APGNoPayReasonCode = CFGANPR.APGNoPayReasonCode
				INNER JOIN
					[CFG].[DecisionFunction]		AS DF
				ON
					ANPR.Decisioner = DF.Name;

				------------------------------------------------18-[CFG].[WorkStream]---------------------------------------
				INSERT INTO
					[CFG].[Workstream]
					(
						[WorkstreamId],
						[WorkGroupId],
						[DecisionFunctionId],
						[Name],
						[AmountFrom],
						[AmountTo],
						[Priority],
						[DELETEd],
						[CreatedDate],
						[UpdatedDate],
						[CreatedBy],
						[UpdatedBy],
						[LinkedItemCount],
						[IsAutoNoPay]
					)
				SELECT
					[WorkstreamSeq],
					W.[WorkGroupId],
					DF.[DecisionFunctionId],
					WS.[Workstream Name],
					WS.[AmountFrom],
					WS.[AmountTo],
					WS.[Priority],
					0,
					GETDATE(),
					GETDATE(),
					ORIGINAL_LOGIN(),
					ORIGINAL_LOGIN(),
					WS.[LinkedItemCount],
					[WS].[IsAutoNoPay]
				FROM
					[import].[WorkStream_HSBC]	AS WS
				JOIN
					CFG.[DecisionFunction]		AS DF
				ON
					DF.[Name] = WS.[DecisionFunctionSeq]
				JOIN
					CFG.WorkGroup				AS W
				ON
					W.[Name] = WS.[WorkGroupSeq];

				----------------------------------------19-CFG.SUBWORKSTREAM------------------------------------------------------

				--UPDATE Subworkstream Sort and Account Number


				UPDATE
					[import].[SubWorkStream_HSBC]
				SET
				[Sort Code Range From]	= 0,
					[Sort Code Range To] = 999999
				WHERE
					[Sort Code Range From]	= ''
				AND [Sort Code Range To] = '';


				UPDATE
					[import].[SubWorkStream_HSBC]
				SET
				[Account Number Range From] = 0,
					[Account Number Range To] = 99999999
				WHERE
					[Account Number Range From] = ''
				AND [Account Number Range To] = '';

				-- ;WITH SubWorkstreamCTE(,,[SUB WORK STREAM NAME],,,[PRIORITY],DELETED, CreateDate, UpdatedDate,CreatedBy,UpdatedBy,[LinkedItemCount]) 
				-- AS
				-- (
				SELECT
					ROW_NUMBER	() OVER (PARTITION BY
										WORKSTREAMID,
										[SUB WORK STREAM NAME]
										ORDER BY
										[SUB WORK STREAM NAME]
									)	AS [UniqueWorkStream],
					WS.WorkstreamId			AS WORKSTREAMSEQ,
					SWS.[SUB WORK STREAM NAME],
					--SWS.[Amount Range From], 
					CASE
						WHEN SWS.[Amount Range From] = ''
						THEN NULL
						WHEN SWS.[Amount Range From] = 'NULL'
						THEN NULL
						ELSE SWS.[Amount Range From]
					END						AS [Amount Range From],
					--SWS.[Amount Range To],
					CASE
						WHEN SWS.[Amount Range To] = ''
						THEN NULL
						WHEN SWS.[Amount Range To] = 'NULL'
						THEN NULL
						ELSE SWS.[Amount Range To]
					END						AS [Amount Range To],
					SWS.[PRIORITY]			AS [PRIORITY],
					0						AS DELETED,
					GETDATE()				AS CreateDate,
					GETDATE()				AS UpdatedDate,
					'IPSL'					AS CreatedBy,
					'IPSL'					AS UpdatedBy,
					SWS.[LinkedItemCount]	AS [LinkedItemCount]
				INTO
					#SubWorkstreamCTE
				FROM
					[import].[SubWorkStream_HSBC]	AS SWS
				INNER JOIN
					CFG.WORKGROUP					AS WG
				ON
					SWS.[Work Group] = WG.NAME
				INNER JOIN
					CFG.WORKSTREAM					AS WS
				ON
					WS.WorkGroupId = WG.WorkGroupId
				AND SWS.[Work Stream] = WS.Name
				WHERE
					UPPER([SUB WORK STREAM NAME]) <> 'DEFAULT';
				--		)

				CREATE NONCLUSTERED INDEX nci_UniqueWorkStream
				ON #SubWorkstreamCTE (WORKSTREAMSEQ, [SUB WORK STREAM NAME], UniqueWorkStream)
				WHERE UniqueWorkStream = 1;

				INSERT INTO
					CFG.SUBWORKSTREAM
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
				SELECT
					ROW_NUMBER	() OVER (ORDER BY
										WORKSTREAMSEQ,
										[SUB WORK STREAM NAME]
									),
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
				FROM
					#SubWorkstreamCTE
				WHERE
					UniqueWorkStream = 1
				ORDER BY
					WORKSTREAMSEQ,
					[SUB WORK STREAM NAME];

				---------------------20.[CFG].[SystemDecision]--------------------------
				INSERT INTO
					CFG.SystemDecision
				SELECT
					SD	.SystemDecisionSeq,
					SD.[Name],
					E.EntityStateId
				FROM
					[import].SystemDecision_HSBC	AS SD
				LEFT JOIN
					cfg.EntityStates				AS E
				ON
					E.EntityState = SD.EntityState;

				---------------------------55-[CFG].[SortCodeMapAccountNumber]---------------------------------------------------------------------------------

				-----------------------23-[CFG].[SI_Group_EntityStates]----------------------
				INSERT INTO
					cfg.SI_Group_EntityStates
					(
						[SI_GroupID],
						[EntityState]
					)
				SELECT
					[SI_GroupID],
					[EntityState]
				FROM
					[import].[SI_GroupEntity states_HSBC];

				----------------------24-[CFG].[SI_InstructionType]-------------------------------
				INSERT INTO
					CFG.SI_InstructionType
					(
						[InstructionType],
						[ProcessCredit],
						[InstructionName],
						[InstructionCode]
					)
				SELECT
					InstructionType,
					ProcessCredit,
					InstructionName,
					InstructionCode
				FROM
					[import].SI_InstructionType_HSBC;

				------------------------------------------------25-[CFG].[WorkGroupInSortCodeRange]---------------------------------  

				INSERT INTO
					[CFG].RangeAccountNumber
					(
						[RangeAccountNumberId],
						[From],
						[To]
					)
				SELECT
					ROW_NUMBER	() OVER (ORDER BY
										[x].[AccountNumberFrom],
										[x].[AccountNumberTo]
									) AS [RangeAccountNumberId],
					[x].[AccountNumberFrom],
					[x].[AccountNumberTo]
				FROM
					(
						SELECT	DISTINCT
								CAST([AccountNumber From] AS INT) AS [AccountNumberFrom],
								CAST([AccountNumber To] AS INT)		AS [AccountNumberTo]
						FROM
								Import.WorkGroupInSortCode_HSBC
						UNION
						SELECT	DISTINCT
								CAST([AccountNumber From] AS INT) AS [AccountNumberFrom],
								CAST([AccountNumber To] AS INT)		AS [AccountNumberTo]
						FROM
								[import].[WorkStreamInAccountSortCodeRange_HSBC]
						UNION
						SELECT	DISTINCT
								CAST([Account Number Range From] AS INT)	AS [AccountNumberFrom],
								CAST([Account Number Range To] AS INT)		AS [AccountNumberTo]
						FROM
								[import].SubWorkStream_HSBC
					) AS x
				GROUP BY
					[x].[AccountNumberFrom],
					[x].[AccountNumberTo]
				HAVING
					[x].[AccountNumberTo] > 0;



				INSERT INTO
					[CFG].RangeSortCode
					(
						[RangeSortCodeId],
						[From],
						[To]
					)
				SELECT
					ROW_NUMBER	() OVER (ORDER BY
										[tab].[SortCodeRangeFrom],
										[tab].[SortCodeRangeTo]
									) AS [RangeSortCodeId],
					[tab].[SortCodeRangeFrom],
					[tab].[SortCodeRangeTo]
				FROM
					(
						SELECT	DISTINCT
								CAST([Sort Code Range From] AS INT) AS [SortCodeRangeFrom],
								CAST([Sort Code Range To] AS INT) AS [SortCodeRangeTo]
						FROM
								Import.WorkGroupInSortCode_HSBC
						UNION
						SELECT	DISTINCT
								CAST([Sort Code Range From] AS INT) AS [SortCodeRangeFrom],
								CAST([Sort Code Range To] AS INT) AS [SortCodeRangeTo]
						FROM
								[import].[WorkStreamInAccountSortCodeRange_HSBC]
						UNION
						SELECT	DISTINCT
								CAST([Sort Code Range From] AS INT) AS [SortCodeRangeFrom],
								CAST([Sort Code Range To] AS INT) AS [SortCodeRangeTo]
						FROM
								[import].SubWorkStream_HSBC
					) AS tab
				GROUP BY
					[tab].[SortCodeRangeFrom],
					[tab].[SortCodeRangeTo]
				HAVING
					[tab].[SortCodeRangeTo] > 0;




				CREATE TABLE #TT
					(
						[AccountNumberSeq]	INT,
						[SortCodeSeq]		INT
					);

				CREATE CLUSTERED INDEX ci_ANS_SCS
				ON #TT ([AccountNumberSeq], [SortCodeSeq]);

				INSERT INTO
					#TT
					(
						[AccountNumberSeq],
						[SortCodeSeq]
					)
				SELECT
					RA	.RangeAccountNumberId,
					RSC.RangeSortCodeId
				FROM
					[import].[WorkGroupInSortCode_HSBC] AS WGSC
				INNER JOIN
					CFG.WorkGroup						AS WG
				ON
					WG.Name = WGSC.[Work Group Name]
				INNER JOIN
					CFG.RangeSortCode					AS RSC
				ON
					WGSC.[Sort Code Range From] = RSC.[From]
				AND WGSC.[Sort Code Range To] = RSC.[To]
				INNER JOIN
					CFG.RangeAccountNumber				AS RA
				ON
					WGSC.[AccountNumber From] = RA.[From]
				AND WGSC.[AccountNumber To] = RA.[To]
				GROUP BY
					RSC.RangeSortCodeId,
					RA.RangeAccountNumberId;

				INSERT INTO
					#TT
					(
						[AccountNumberSeq],
						[SortCodeSeq]
					)
				SELECT
					RA	.RangeAccountNumberId,
					RSC.RangeSortCodeId
				FROM
					[import].[WorkStreamInAccountSortCodeRange_HSBC]	AS WSSC
				INNER JOIN
					CFG.RangeSortCode									AS RSC
				ON
					WSSC.[Sort Code Range From] = RSC.[From]
				AND WSSC.[Sort Code Range To] = RSC.[To]
				INNER JOIN
					CFG.RangeAccountNumber								AS RA
				ON
					WSSC.[AccountNumber From] = RA.[From]
				AND WSSC.[AccountNumber To] = RA.[To]
				LEFT JOIN
					#TT													AS SS
				ON
					[SS].[AccountNumberSeq] = RA.RangeAccountNumberId
				AND [SS].[SortCodeSeq] = RSC.RangeSortCodeId
				WHERE
					[SS].[AccountNumberSeq] IS NULL
				GROUP BY
					RSC.RangeSortCodeId,
					RA.RangeAccountNumberId;

				INSERT INTO
					#TT
					(
						[AccountNumberSeq],
						[SortCodeSeq]
					)
				SELECT
					RA	.RangeAccountNumberId,
					RSC.RangeSortCodeId
				FROM
					[import].[SubWorkStream_HSBC]	AS WSSC
				INNER JOIN
					CFG.RangeSortCode				AS RSC
				ON
					WSSC.[Sort Code Range From] = RSC.[From]
				AND WSSC.[Sort Code Range To] = RSC.[To]
				INNER JOIN
					CFG.RangeAccountNumber			AS RA
				ON
					WSSC.[Account Number Range From] = RA.[From]
				AND WSSC.[Account Number Range To] = RA.[To]
				LEFT JOIN
					#TT								AS SS
				ON
					[SS].[AccountNumberSeq] = RA.RangeAccountNumberId
				AND [SS].[SortCodeSeq] = RSC.RangeSortCodeId
				WHERE
					[SS].[AccountNumberSeq] IS NULL
				GROUP BY
					RSC.RangeSortCodeId,
					RA.RangeAccountNumberId;


				INSERT INTO
					[CFG].[SortCodeMapAccountNumber]
					(
						[SortCodeMapAccountNumberSeq],
						[AccountNumberSeq],
						[SortCodeSeq]
					)
				SELECT
					ROW_NUMBER	() OVER (ORDER BY
										[RA].[AccountNumberSeq],
										[RA].[SortCodeSeq]
									) AS SortCodeMapAccountNumberSeq,
					[RA].[AccountNumberSeq],
					[RA].[SortCodeSeq]
				FROM
					#TT AS RA
				GROUP BY
					[RA].[AccountNumberSeq],
					[RA].[SortCodeSeq];

				DROP TABLE #TT;

				INSERT INTO
					[CFG].[WorkGroupInSortCodeRange]
					(
						[WorkGroupId],
						[SortCodeMapAccountNumberSeq]
					)
				SELECT	DISTINCT
						WG.WorkGroupId,
						[SMA].SortCodeMapAccountNumberSeq
				FROM
						[import].[WorkGroupInSortCode_HSBC] AS WGSC
				INNER JOIN
						CFG.WorkGroup						AS WG
				ON
					WG.Name = WGSC.[Work Group Name]
				INNER JOIN
						CFG.RangeSortCode					AS RSC
				ON
					WGSC.[Sort Code Range From] = RSC.[From]
				AND WGSC.[Sort Code Range To] = RSC.[To]
				INNER JOIN
						CFG.RangeAccountNumber				AS RA
				ON
					WGSC.[AccountNumber From] = RA.[From]
				AND WGSC.[AccountNumber To] = RA.[To]
				INNER JOIN
						CFG.[SortCodeMapAccountNumber]		AS [SMA]
				ON
					[SMA].SortCodeSeq = [RSC].RangeSortCodeId
				AND [SMA].AccountNumberSeq = RA.RangeAccountNumberId;

				INSERT INTO
					[CFG].[WorkstreamInAccountSortCodeRange]
					(
						[WorkstreamId],
						[SortCodeMapAccountNumberSeq]
					)
				SELECT	DISTINCT
						WS.WorkstreamId,
						[SMA].SortCodeMapAccountNumberSeq
				FROM
						[import].[WorkstreamInAccountSortCodeRange_HSBC]	AS WSSC
				INNER JOIN
						CFG.Workstream										AS WS
				ON
					WS.Name = WSSC.[Work Stream Name]
				INNER JOIN
						CFG.RangeSortCode									AS RSC
				ON
					WSSC.[Sort Code Range From] = RSC.[From]
				AND WSSC.[Sort Code Range To] = RSC.[To]
				INNER JOIN
						CFG.RangeAccountNumber								AS RA
				ON
					WSSC.[AccountNumber From] = RA.[From]
				AND WSSC.[AccountNumber To] = RA.[To]
				INNER JOIN
						CFG.[SortCodeMapAccountNumber]						AS [SMA]
				ON
					[SMA].SortCodeSeq = [RSC].RangeSortCodeId
				AND [SMA].AccountNumberSeq = RA.RangeAccountNumberId
				GROUP BY
					WS.WorkstreamId,
					[SMA].SortCodeMapAccountNumberSeq;

				INSERT INTO
					CFG.[SubWorkstreamInSortCodeRange]
					(
						[SubWorkstreamId],
						[SortCodeMapAccountNumberSeq]
					)
				SELECT	DISTINCT
						WG.SubWorkstreamId,
						[SMA].SortCodeMapAccountNumberSeq
				FROM
						[import].[SubWorkStream_HSBC]	AS WSSC
				INNER JOIN
						CFG.SubWorkstream				AS WG
				ON
					WG.[Name] = WSSC.[Sub Work Stream Name]
				INNER JOIN
						CFG.RangeSortCode				AS RSC
				ON
					WSSC.[Sort Code Range From] = RSC.[From]
				AND WSSC.[Sort Code Range To] = RSC.[To]
				INNER JOIN
						CFG.RangeAccountNumber			AS RA
				ON
					WSSC.[Account Number Range From] = RA.[From]
				AND WSSC.[Account Number Range To] = RA.[To]
				INNER JOIN
						CFG.[SortCodeMapAccountNumber]	AS [SMA]
				ON
					[SMA].SortCodeSeq = [RSC].RangeSortCodeId
				AND [SMA].AccountNumberSeq = RA.RangeAccountNumberId;


				-----------------------------------------------26-[CFG].[WorkGroupInADMapping]----------------------------------------------------
				IF (@Server = 'LIVE')
					BEGIN
						INSERT	INTO
							CFG.WorkGroupInADMapping
							(
								ADMappingSeq,
								WorkGroupSeq
							)
						SELECT
							CAD.ADMappingId,
							WG.WorkGroupId
						FROM
							[import].[ADMapping_LI_HSBC]	AS AD
						INNER JOIN
							CFG.WorkGroup					AS WG
						ON
							WG.[Name] = AD.[WorkGroupSeq]
						INNER JOIN
							CFG.ADMapping					AS CAD
						ON
							CAD.ADMappingId = AD.ADMappingSeq;
					END;
				ELSE IF (
							@Server = 'SIT'
					OR		@Server = 'IT'
						)
						BEGIN
							INSERT	INTO
								CFG.WorkGroupInADMapping
								(
									ADMappingSeq,
									WorkGroupSeq
								)
							SELECT
								CAD.ADMappingId,
								WG.WorkGroupId
							FROM
								[import].[ADMapping_SIT_IT_HSBC]	AS AD
							INNER JOIN
								CFG.WorkGroup						AS WG
							ON
								WG.[Name] = AD.[WorkGroupSeq]
							INNER JOIN
								CFG.ADMapping						AS CAD
							ON
								CAD.ADMappingId = AD.ADMappingSeq;
						END;
				ELSE IF (@Server = 'TR')
						BEGIN
							INSERT	INTO
								CFG.WorkGroupInADMapping
								(
									ADMappingSeq,
									WorkGroupSeq
								)
							SELECT
								CAD.ADMappingId,
								WG.WorkGroupId
							FROM
								[import].[ADMapping_TR_HSBC]	AS AD
							INNER JOIN
								CFG.WorkGroup					AS WG
							ON
								WG.[Name] = AD.[WorkGroupSeq]
							INNER JOIN
								CFG.ADMapping					AS CAD
							ON
								CAD.ADMappingId = AD.ADMappingSeq;
						END;
				ELSE IF (@Server = 'TME')
						BEGIN
							INSERT	INTO
								CFG.WorkGroupInADMapping
								(
									ADMappingSeq,
									WorkGroupSeq
								)
							SELECT
								CAD.ADMappingId,
								WG.WorkGroupId
							FROM
								[import].[ADMapping_TME_HSBC]	AS AD
							INNER JOIN
								CFG.WorkGroup					AS WG
							ON
								WG.[Name] = AD.[WorkGroupSeq]
							INNER JOIN
								CFG.ADMapping					AS CAD
							ON
								CAD.ADMappingId = AD.ADMappingSeq;
						END;

				------------------------------22-[CFG].[WorkstreamInADMapping]-------------------------------------------------------------------------------------------

				INSERT INTO
					[CFG].[WorkstreamInADMapping]
					(
						[ADMappingId],
						[WorkstreamId]
					)
				SELECT	DISTINCT
						ADMap.ADMappingSeq,
						WS.WorkstreamId
				FROM
						CFG.WorkGroupInADMapping	AS ADMap
				INNER JOIN
						CFG.WorkGroup				AS WG
				ON
					WG.WorkGroupId = ADMap.WorkGroupSeq
				INNER JOIN
						CFG.Workstream				AS WS
				ON
					WS.WorkGroupId = WG.WorkGroupId

				------------------------27 - CFG.FINALDECISIONRULES-----------------------
				;
				WITH
					[FinalDecision_HSBC]
					([Index], [Reason For Return], [Funds Response Status], [Response Sub Type], [Funds Response Qualifier], [Final Decision], [Final Reason For Return])
				AS
					(
						SELECT
							[Index],
							[Reason For Return],
							CASE
								WHEN [Funds Response Status] = ''
								THEN NULL
								ELSE [Funds Response Status]
							END,
							CASE
								WHEN [Response Sub Type] = ''
								THEN NULL
								ELSE [Response Sub Type]
							END,
							CASE
								WHEN [Funds Response Qualifier] = ''
								THEN NULL
								ELSE [Funds Response Qualifier]
							END,
							[Final Decision],
							[Final Reason For Return]
						FROM
							[import].[FinalDecision_HSBC] AS FD
					)
				INSERT INTO
					[CFG].[FinalDecisionRule]
					(
						[FinalDecisionRuleSeq],
						[NoPaidReasonSeq],
						[PostingResponseStatusSeq],
						[PostingResponseQualifierSeq],
						[FinalDecisionSeq],
						[FinalNoPaidReasonSeq]
					)
				SELECT
					FD	.[Index],
					NP.NoPayReasonCodesIndustryId,
					PS.PostingResponseStatusId,
					PQ.PostingResponseQualifierId,
					SD.SystemDecisionId,
					NP1.NoPayReasonCodesIndustryId
				FROM
					[FinalDecision_HSBC]			AS FD
				LEFT JOIN
					[CFG].NoPayReasonCodesIndustry	AS NP
				ON
					NP.Name = FD.[Reason For Return]
				LEFT JOIN
					[CFG].[PostingResponseStatus]	AS PS
				ON
					PS.Code = FD.[Funds Response Status]
				AND ISNULL(PS.ResponseSubType, 0) = ISNULL(FD.[Response Sub Type], 0)
				LEFT JOIN
					[CFG].PostingResponseQualifier	AS PQ
				ON
					RIGHT((PQ.Qualifier + 1000000), 6) = RIGHT((FD.[Funds Response Qualifier] + 1000000), 6)
				INNER JOIN
					[CFG].SystemDecision			AS SD
				ON
					SD.Name = FD.[Final Decision]
				LEFT JOIN
					[CFG].NoPayReasonCodesIndustry	AS NP1
				ON
					NP1.Name = FD.[Final Reason For Return];

				-----------------------28.[CFG].[KappaNoPayReasonCodes]---------------------

				INSERT INTO
					[CFG].[KappaNoPayReasonCodes]
					(
						[KappaDecisionId],
						[FraudCheckResult],
						[FraudCheckReason],
						[Description]
					)
				SELECT
					KappaDecisionSeq,
					FraudCheckResult,
					CASE
						WHEN FraudCheckReason = 'NULL'
						THEN NULL
						ELSE FraudCheckReason
					END				AS [FraudCheckReason],
					[Description]
				FROM
					[import].[KappaNoPayReasons_HSBC];

				---------------------29.[CFG].[KappaNoPayReasonCodesMapIndustry]--------------------------------------------------------------------------
				INSERT INTO
					[CFG].[KappaNoPayReasonCodesMapIndustry]
					(
						[KappaDecisionId],
						[NoPayReasonCodesIndustryId]
					)
				SELECT
					KNP.KappaDecisionId,
					NP.NoPayReasonCodesIndustryId
				FROM
					[import].[KappaNoPayReasons_HSBC]	AS K
				JOIN
					[CFG].KappaNoPayReasonCodes			AS KNP
				ON
					KNP.[Description] = K.[Description]
				AND KNP.FraudCheckResult = K.FraudCheckResult
				JOIN
					[CFG].NoPayReasonCodesIndustry		AS NP
				ON
					NP.Code = K.[IndustryCode]
				ORDER BY
					KappaDecisionSeq;

				-------------------------[CFG].[MSG06Group]--------------------------------
				INSERT INTO
					[CFG].[MSG06Group]
				SELECT
					[MSG06GroupSeq],
					[Description]
				FROM
					[Import].[MSG06Group_HSBC];

				-------------------------[CFG].[WorkGroupResponsePattern]--------------------------------
				INSERT INTO
					[CFG].[WorkGroupResponsePattern]
				SELECT
					[WorkGroupResponsePatternSeq],
					[WorkGroupSeq],
					[MSG06GroupSeq]
				FROM
					[Import].[WorkGroupResponsePattern_HSBC];

				------------------------30-[CFG].[EntityState_Config]------------------------------------

				INSERT INTO
					[CFG].[PostingResponseStatusMapQualifierGroup]
					(
						[PostingResponseStatusMapQualifierGroupSeq],
						[Name]
					)
				SELECT
					[PostingResponseStatusMapQualifierGroupSeq],
					[Name]
				FROM
					[Import].[PostingResponseStatusMapQualifierGroup_HSBC];


				INSERT INTO
					[CFG].[EntityState_Config]
				SELECT
					[EntityStateConfigSeq]	,
					CASE
						WHEN [EntityStateSeq] = ''
						THEN NULL
						WHEN [EntityStateSeq] = 'NULL'
						THEN NULL
						ELSE [EntityStateSeq]
					END						AS [EntityStateSeq],
					CASE
						WHEN [PostingResponseStatusMapQualifierGroupSeq] = ''
						THEN NULL
						WHEN [PostingResponseStatusMapQualifierGroupSeq] = 'NULL'
						THEN NULL
						ELSE [PostingResponseStatusMapQualifierGroupSeq]
					END						AS [PostingResponseStatusMapQualifierGroupSeq],
					CASE
						WHEN [SystemDecisionSeq] = ''
						THEN NULL
						WHEN [SystemDecisionSeq] = 'NULL'
						THEN NULL
						ELSE [SystemDecisionSeq]
					END						AS [UserDecisionSeq],
					ESC.[NoPay],
					ESC.[PostingOverride]
				FROM
					[import].EntityState_Config_HSBC AS ESC
				WHERE
					ESC.[NoPay] <> '';

				------------------------31-[CFG].[EntityStateMapPostingResponseStatus]------------------------------------

				INSERT INTO
					[CFG].[EntityStateMapPostingResponseStatus]
				SELECT
					[EntityStateSeq],
					[PostingResponseStatusSeq]
				FROM
					[Import].[ESMapPostingResponseStatus_HSBC];

				---------------------------32-[CFG].[DecisionerMapPostingResponseQualifier]------------------------------------------------
				INSERT INTO
					CFG.DecisionerMapPostingResponseQualifier
				SELECT
					[P].PostingResponseQualifierSeq,
					[D].DecisionFunctionId
				FROM
					IMPORT.[PostingResponseQualifier_HSBC]	AS [P]
				INNER JOIN
					CFG.DecisionFunction					AS [D]
				ON
					[P].Decisioner = [D].Name;
				----------------------------33-[CFG].[DecisionItemConfig]------------------------------------------------

				INSERT
					[CFG].[DecisionItemConfig]
					(
						[Id],
						[WorkstreamStateId],
						[HeaderColor],
						[PassButtonText],
						[FailButtonText],
						[VerifyButtonText],
						[SuspendButtonText],
						[ShowADMandates],
						[ShowADStops],
						[ShowADKappa],
						[ShowADCrossExceptions],
						[ShowADReputablePayeeList]
					)
				VALUES
					(
						5, 1, N'#A9D08E', N'Pass', N'Fail', N'Verify', N'Suspend', 1, 1, 1, 1, 1
					);
				INSERT
					[CFG].[DecisionItemConfig]
					(
						[Id],
						[WorkstreamStateId],
						[HeaderColor],
						[PassButtonText],
						[FailButtonText],
						[VerifyButtonText],
						[SuspendButtonText],
						[ShowADMandates],
						[ShowADStops],
						[ShowADKappa],
						[ShowADCrossExceptions],
						[ShowADReputablePayeeList]
					)
				VALUES
					(
						6, 2, N'#FFD966', N'Pass', N'Fail', N'Verify', N'Suspend', 1, 1, 1, 1, 1
					);
				INSERT
					[CFG].[DecisionItemConfig]
					(
						[Id],
						[WorkstreamStateId],
						[HeaderColor],
						[PassButtonText],
						[FailButtonText],
						[VerifyButtonText],
						[SuspendButtonText],
						[ShowADMandates],
						[ShowADStops],
						[ShowADKappa],
						[ShowADCrossExceptions],
						[ShowADReputablePayeeList]
					)
				VALUES
					(
						7, 3, N'#F4B084', N'Pass', N'Fail', N'Verify', N'Suspend', 1, 1, 1, 1, 1
					);
				INSERT
					[CFG].[DecisionItemConfig]
					(
						[Id],
						[WorkstreamStateId],
						[HeaderColor],
						[PassButtonText],
						[FailButtonText],
						[VerifyButtonText],
						[SuspendButtonText],
						[ShowADMandates],
						[ShowADStops],
						[ShowADKappa],
						[ShowADCrossExceptions],
						[ShowADReputablePayeeList]
					)
				VALUES
					(
						8, 4, N'#9BC2E6', N'Pass', N'Fail', N'Verify', N'Suspend', 1, 1, 1, 1, 1
					);


				----------------------34--MSG13 - [CFG].[13MD_Credit_ConfigRules]------------------------------
				INSERT INTO
					CFG.[13MD_Credit_ConfigRules]
				SELECT
					[13MD_Credit_ConfigRulesSeq],
					CASE
						WHEN [CreditAPGNoPayReasonCodeSeq] = ''
						THEN NULL
						WHEN [CreditAPGNoPayReasonCodeSeq] = 'NULL'
						THEN NULL
						ELSE [CreditAPGNoPayReasonCodeSeq]
					END,
					CASE
						WHEN [CreditKappaNoPayReasonSeq] = ''
						THEN NULL
						WHEN [CreditKappaNoPayReasonSeq] = 'NULL'
						THEN NULL
						ELSE [CreditKappaNoPayReasonSeq]
					END,
					[AlternateSortCode],
					[AlternateAccount],
					[CustomerNotificationReq],
					[CaseManagementReq],
					[CaseTypeID],
					[CasePrefix]
				FROM
					[import].[13MD_Credit_ConfigRules_HSBC];

				----------------------35 -MSG13 - [CFG].[13MD_EntityStatesMapping]--------------------------
				INSERT INTO
					CFG.[13MD_EntityStatesMapping]
					(
						[13MD_EntityStatesMappingSeq],
						[IncomingEntityStateSeq],
						[OutboundEntityStateSeq],
						[13DMCreditOutbound],
						[Multicredit]
					)
				SELECT
					[ESSEQ],
					[IncomingEntityStateSeq],
					[OutboundEntityStateSeq],
					[13DMCreditOutbound],
					[Multicredit]
				FROM
					[import].[13MD_EntityStatesMapping_HSBC];

				-----------------------------36-[CFG].[FraudSubReason]--------------------------------------------------------------
				INSERT INTO
					[CFG].[FraudSubReason]
				SELECT
					[FraudReasonSeq],
					[Fraud Reason Code],
					[Fraud Reason Name],
					[Description]
				FROM
					[Import].[FraudReason_HSBC] AS FR;

				-----------------------------36-[CFG].[UserFailReasonMapFraudReason]-------------------------------------------
				INSERT INTO
					[CFG].[UserFailReasonMapFraudReason]
				SELECT
					[FailReasonSeq],
					[FraudReasonSeq]
				FROM
					[Import].[UserFailReasonMapFraudReason_HSBC] AS FR;

				----------------------36-CFG.BusinessRules---------------------------------

				INSERT INTO
					[CFG].[BusinessRule]
					(
						[BusinessRuleId],
						[WorkGroupId],
						[WorkstreamId],
						[SubWorkstreamId],
						[CustomerSegmentId],
						[CurrentStateId],
						[UserDecisionId],
						[UserFailReasonId],
						[FraudReasonId],
						[SystemInitialDecisionId],
						[NextStateId],
						[OverThresholdStateId],
						[SystemDefaultDecisionId],
						NoPayReasonCodesIndustryId,
						[DELETEd],
						[UpdatedDate],
						[CreatedDate],
						[CreatedBy],
						[UpdatedBy],
						[DefaultFraudReasonId]
					)
				SELECT
					RD	.[Index],
					WG.WorkGroupId,
					WS.WorkstreamId,
					SWS.SubWorkstreamId,
					CS.CustomerSegmentId,
					WSS.WorkstreamStateId,
					UD.UserDecisionId,
					ufr.UserFailReasonId,	--7480
					[FR].[FraudSubReasonSeq],
					sd.SystemDecisionId,
					WSS2.WorkstreamStateId,
					WSS3.WorkstreamStateId,
					sd2.SystemDecisionId,	--2860
					rc.NoPayReasonCodesIndustryId,
					0,
					'2017-02-12 09:55:19',
					'2017-02-12 09:55:19',
					'System',
					'System',
					[FR1].FraudSubReasonSeq
				FROM
					[import].[BusinessRules_HSBC]	AS RD
				INNER JOIN
					[CFG].WorkGroup					AS WG
				ON
					WG.Name = RD.[Workgroup]
				INNER JOIN
					[CFG].WorkStream				AS WS
				ON
					WS.Name = RD.[Workstream]
				AND WS.WorkGroupId = WG.WorkGroupId
				LEFT JOIN
					[CFG].SubWorkStream				AS SWS
				ON
					SWS.Name = RD.[Subworkstream]
				AND WS.WorkstreamId = SWS.WorkstreamId
				INNER JOIN
					[CFG].CustomerSegment			AS CS
				ON
					CS.Name = RD.[Customer Segment]
				LEFT JOIN
					[CFG].WorkStreamState			AS WSS
				ON
					WSS.Name = RD.[Current State]
				LEFT JOIN
					[CFG].[UserDecision]			AS UD
				ON
					UD.Name = RD.[User Decision]
				LEFT JOIN
					[CFG].[UserFailReason]			AS ufr
				ON
					ufr.Name = RD.[User Fail Reason]
				LEFT JOIN
					[CFG].[SystemDecision]			AS sd
				ON
					sd.Name = RD.[System Initial Decision]
				LEFT JOIN
					[CFG].WorkStreamState			AS WSS2
				ON
					WSS2.Name = RD.[Next State]
				LEFT JOIN
					[CFG].WorkStreamState			AS WSS3
				ON
					WSS3.Name = RD.[Over Threshold State]
				LEFT JOIN
					[CFG].[SystemDecision]			AS sd2
				ON
					sd2.Name = RD.[System Default Decision]
				LEFT JOIN
					[CFG].NoPayReasonCodesIndustry	AS rc
				ON
					rc.Name = RD.[No Pay Reason]
				LEFT JOIN
					[CFG].[FraudSubReason]			AS [FR]
				ON
					[FR].[Name] = [RD].[Fraud Reason]
				LEFT JOIN
					[CFG].[FraudSubReason]			AS [FR1]
				ON
					[FR1].[Name] = [RD].[Default Fraud Reason];

				---------------------------37--[CFG].[ChannelType]--------------------------------

				INSERT INTO
					[CFG].[ChannelType]
				SELECT
					CAST([ChannelTypeSeq] AS TINYINT),
					CASE
						WHEN [ChannelRiskType] = 'Original'
						THEN 'Orgn'
						ELSE [ChannelRiskType]
					END		AS [ChannelRiskType],
					CAST([Source] AS SMALLINT),
					[Name]
				FROM
					[Import].[ChannelType_HSBC];


				---------------------------37.1--[CFG].[GroupChannelType_HSBC]--------------------------------

				INSERT INTO
					[CFG].[GroupChannelType]
				SELECT
					CAST([GroupChannelTypeSeq] AS TINYINT),
					[Name]
				FROM
					[Import].[GroupChannelType_HSBC];

				---------------------------37.2--[CFG].[GroupChannelTypeMapChannelType_HSBC]--------------------------------

				INSERT INTO
					[CFG].[GroupChannelTypeMapChannelType]
				SELECT
					CAST([GroupChannelTypeSeq] AS TINYINT),
					CAST([ChannelTypeSeq] AS TINYINT)
				FROM
					[Import].[GroupChannelTypeMapCT_HSBC];

				-------------------------38--[CFG].[APGAdjustmentCode]---------------------

				INSERT INTO
					[CFG].[APGAdjustmentCode]
				SELECT
					CAST([APGAdjustmentCodeSeq] AS TINYINT),
					CAST([APGAdjustmentCode] AS INT)
				FROM
					[Import].[APGAdjustmentCode_HSBC];

				-------------------------38.5--[CFG].[InsertReasons]---------------------

				INSERT INTO
					[CFG].[InsertReasons]
				SELECT
					CAST([InsertReasonSeq] AS TINYINT),
					[InsertReason]
				FROM
					[Import].[InsertReasons_HSBC];

				-------------------------[CFG].[TransCode]---------------------

				INSERT INTO
					[CFG].[TransCode]
				SELECT
					CAST([TransCodeSeq] AS TINYINT),
					CASE
						WHEN [TransCode] = 'NULL'
						THEN NULL
						ELSE [TransCode]
					END AS [TransCode]
				FROM
					[Import].[TransCode_HSBC];

				-------------------------[CFG].[GroupTransCode]---------------------

				INSERT INTO
					[CFG].[GroupTransCode]
				SELECT
					CAST([GroupTransCodeSeq] AS TINYINT),
					[Name]
				FROM
					[Import].[GroupTransCode_HSBC];

				-------------------------[CFG].[GroupTransMapTransCode]---------------------

				INSERT INTO
					[CFG].[GroupTransMapTransCode]
				SELECT
					CAST([GroupTransCodeSeq] AS TINYINT),
					CAST([TransCodeSeq] AS TINYINT)
				FROM
					[Import].[GroupTransMapTransCode_HSBC];


				-------------------------[CFG].[GroupTransMapInsertReason]---------------------

				INSERT INTO
					[CFG].[GroupTransMapInsertReason]
				SELECT
					CAST([GroupTransMapInsertReasonSeq] AS TINYINT),
					CAST([GroupTransCodeSeq] AS TINYINT),
					CAST([InsertReasonSeq] AS TINYINT),
					[IsWithdraw]
				FROM
					[Import].[GroupTransMapInsertReason_HSBC];

				--*************************[01MD_Notification_Detail]************************

				INSERT INTO
					[CFG].[01MD_Notification_Detail]
				SELECT
					CAST([01MD_Notification_DetailSeq] AS SMALLINT),
					[NtfyRsn],
					[NtfyRsnDesc]
				FROM
					[Import].[01MD_Notification_Detail_HSBC];


				--*************************[01MD_Case_Detail]********************************
				INSERT INTO
					[CFG].[01MD_Case_Detail]
				SELECT
					CAST([01MD_Case_DetailSeq] AS TINYINT),
					CASE
						WHEN [CasePrefix] = ''
						THEN NULL
						WHEN [CasePrefix] = 'NULL'
						THEN NULL
						ELSE CAST([CasePrefix] AS CHAR)
					END AS [CasePrefix],
					CASE
						WHEN [CaseTypeID] = ''
						THEN NULL
						WHEN [CaseTypeID] = 'NULL'
						THEN NULL
						ELSE CAST([CaseTypeID] AS CHAR(4))
					END AS [CaseTypeID],
					CASE
						WHEN [CasePostfix] = ''
						THEN NULL
						WHEN [CasePostfix] = 'NULL'
						THEN NULL
						ELSE CAST([CasePostfix] AS CHAR(1))
					END AS [CasePostfix]
				FROM
					[Import].[01MD_Case_Detail_HSBC];

				--*************************[OnBank]*****************************************

				INSERT INTO
					[CFG].[OnBank]
				SELECT
					CAST([OnBankSeq] AS TINYINT),
					CAST([OnBank] AS TINYINT),
					[OnBankDescription]
				FROM
					[Import].[OnBank_HSBC];

				--*************************[OnBankPattern]*****************************************

				INSERT INTO
					[CFG].[OnBankPattern]
				SELECT
					CAST([OnBankPatternSeq] AS TINYINT),
					[OnBankPatternName]
				FROM
					[Import].[OnBankPattern_HSBC];

				--*************************[OnBankMapOBPattern]*****************************************

				INSERT INTO
					[CFG].[OnBankMapOBPattern]
				SELECT
					CAST([OnBankSeq] AS TINYINT),
					CAST([OnBankPatternSeq] AS TINYINT)
				FROM
					[Import].[OnBankMapOBPattern_HSBC];

				--*************************[GroupAPGNPRADJ]*****************************************

				INSERT INTO
					[CFG].[GroupAPGNPRADJ]
				SELECT
					CAST([GroupAPGNPRADJSeq] AS INT),
					CASE
						WHEN [APGNoPayReasonCodeSeq] = ''
						THEN NULL
						WHEN [APGNoPayReasonCodeSeq] = 'NULL'
						THEN NULL
						ELSE CAST([APGNoPayReasonCodeSeq] AS TINYINT)
					END AS [APGNoPayReasonCodeSeq],
					CASE
						WHEN [APGAdjustmentCodeSeq] = ''
						THEN NULL
						WHEN [APGAdjustmentCodeSeq] = 'NULL'
						THEN NULL
						ELSE CAST([APGAdjustmentCodeSeq] AS TINYINT)
					END AS [APGAdjustmentCodeSeq]
				FROM
					[Import].[GroupAPGNPRADJ_HSBC];

				--*************************[APGNPRADJPattern]*****************************************

				INSERT INTO
					[CFG].[APGNPRADJPattern]
				SELECT
					CAST([APGNPRADJPatternSeq] AS TINYINT),
					[APGNPRADJPatternDesc]
				FROM
					[Import].[APGNPRADJPattern_HSBC];

				--*************************[GroupAPGMapAPGPattern]*****************************************

				INSERT INTO
					[CFG].GroupAPGMapAPGPattern
				SELECT
					CAST([GroupAPGNPRADJSeq] AS INT),
					CAST([APGNPRADJPatternSeq] AS TINYINT)
				FROM
					[Import].[GroupAPGMapAPGPattern_HSBC];

				-----------------------39--[CFG].[01MD_EntityConfig]---------------------

				INSERT INTO
					[CFG].[01MD_EntityConfig]
				SELECT
					CAST([01EC].[EntityStateSeq] AS SMALLINT),
					CAST([01EC].[IsProblematic] AS BIT)
				FROM
					[Import].[01MD_EntityConfig_HSBC]	AS [01EC]
				INNER JOIN
					[CFG].[EntityStates]				AS [EC]
				ON
					[EC].[EntityStateId] = CAST([01EC].[EntityStateSeq] AS SMALLINT);


				----------------------[01MD_APG_OutClearingAction]--------------------------------

				INSERT INTO
					[CFG].[01MD_APG_OutClearingAction]
				SELECT
					CAST([01MD_APG_OutClearingActionSeq] AS INT),
					CAST([APGNPRADJPatternSeq] AS TINYINT),
					CAST([OutClearingActionSeq] AS TINYINT),
					CAST([ItemTypeSeq] AS TINYINT),
					CAST([GroupChannelTypeSeq] AS TINYINT),
					CAST([GroupTransMapInsertReasonSeq] AS TINYINT)
				FROM
					[Import].[01MD_APG_OutClearingAction_HSBC];

				-----------------------[01MD_APG_OutClearingConfig]-------------------------------

				INSERT INTO
					[CFG].[01MD_APG_OutClearingConfig]
				SELECT
					CAST([01MD_APG_OutClearingConfigSeq] AS INT),
					CAST([01MD_APG_OutClearingActionSeq] AS INT),
					CAST([OnBankPatternSeq] AS INT),
					CAST([TxSetOutClearingActionSeq] AS INT),
					CASE
						WHEN [EntityStateSeq] = ''
						THEN NULL
						WHEN [EntityStateSeq] = 'NULL'
						THEN NULL
						ELSE CAST([EntityStateSeq] AS TINYINT)
					END AS [EntityStateSeq],
					CAST([CustomerNotificationReq] AS BIT),
					CASE
						WHEN [01MD_Notification_DetailSeq] = ''
						THEN NULL
						WHEN [01MD_Notification_DetailSeq] = 'NULL'
						THEN NULL
						ELSE CAST([01MD_Notification_DetailSeq] AS TINYINT)
					END AS [01MD_Notification_DetailSeq],
					CAST([CaseManagementReq] AS BIT),
					CASE
						WHEN [01MD_Case_DetailSeq] = ''
						THEN NULL
						WHEN [01MD_Case_DetailSeq] = 'NULL'
						THEN NULL
						ELSE CAST([01MD_Case_DetailSeq] AS TINYINT)
					END AS [01MD_Case_DetailSeq],
					CAST([IsAgency] AS BIT)
				FROM
					[Import].[01MD_APG_OutClearingConfig_HSBC];


				-------------------------42--[CFG].[01MD_Fraud_OutClearingAction]------------------------

				INSERT INTO
					[CFG].[01MD_Fraud_OutClearingAction]
				SELECT
					CAST([01MD_Fraud_OutClearingActionSeq] AS SMALLINT),
					CAST([KappaDecisionSeq] AS TINYINT),
					CAST([OutClearingActionSeq] AS TINYINT),
					CAST([GroupChannelTypeSeq] AS TINYINT),
					CASE
						WHEN [IsAgency] = ''
						THEN NULL
						WHEN [IsAgency] = 'NULL'
						THEN NULL
						ELSE CAST([IsAgency] AS BIT)
					END AS [IsAgency]
				FROM
					[Import].[01MD_Fraud_OutClearingAction_HSBC];

				-------------------------43-[CFG].[01MD_Fraud_OutClearingConfig]------------------------

				INSERT INTO
					[CFG].[01MD_Fraud_OutClearingConfig]
				SELECT
					CAST([01MD_Fraud_OutClearingConfigSeq] AS SMALLINT),
					CASE
						WHEN [KappaDecisionSeq] = ''
						THEN NULL
						WHEN [KappaDecisionSeq] = 'NULL'
						THEN NULL
						ELSE CAST([KappaDecisionSeq] AS TINYINT)
					END AS [KappaDecisionSeq],
					CASE
						WHEN [OnBank] = ''
						THEN NULL
						WHEN [OnBank] = 'NULL'
						THEN NULL
						ELSE CAST([OnBank] AS TINYINT)
					END AS [OnBank],
					CAST([GroupChannelTypeSeq] AS TINYINT),
					CASE
						WHEN [TxSetOutClearingActionSeq] = ''
						THEN NULL
						WHEN [TxSetOutClearingActionSeq] = 'NULL'
						THEN NULL
						ELSE CAST([TxSetOutClearingActionSeq] AS TINYINT)
					END AS [TxSetOutClearingActionSeq],
					CASE
						WHEN [ItemTypeSeq] = ''
						THEN NULL
						WHEN [ItemTypeSeq] = 'NULL'
						THEN NULL
						ELSE CAST([ItemTypeSeq] AS TINYINT)
					END AS [ItemTypeSeq],
					CAST([IsAgency] AS BIT),
					CAST([CustomerNotificationReq] AS BIT),
					CAST([CaseManagementReq] AS BIT),
					CASE
						WHEN [CaseTypeID] = ''
						THEN NULL
						WHEN [CaseTypeID] = 'NULL'
						THEN NULL
						ELSE CAST([CaseTypeID] AS CHAR(4))
					END AS [CaseTypeID],
					CASE
						WHEN [CasePrefix] = ''
						THEN NULL
						WHEN [CasePrefix] = 'NULL'
						THEN NULL
						ELSE CAST([CasePrefix] AS CHAR)
					END AS [CasePrefix],
					CASE
						WHEN [CasePostfix] = ''
						THEN NULL
						WHEN [CasePostfix] = 'NULL'
						THEN NULL
						ELSE CAST([CasePostfix] AS CHAR(1))
					END AS [CasePostfix]
				FROM
					[Import].[01MD_Fraud_OutClearingConfig_HSBC];


				----------------------44--[CFG].[01MD_EntityStatesMapping]----------------------

				INSERT INTO
					[CFG].[01MD_EntityStatesMapping]
				SELECT
					[MessageType],
					CAST([ItemTypeSeq] AS TINYINT),
					CAST([OutClearingActionSeq] AS TINYINT),
					CAST([01MD_OutEntityStateSeq] AS SMALLINT)
				FROM
					[Import].[01MD_EntityStatesMapping_HSBC];

				--------------------46--[CFG].[01MD_Notification_Kappa_Config]-----------------------

				INSERT INTO
					[CFG].[01MD_Notification_Kappa_Config]
				SELECT
					CAST([01MD_NotificationKappaConfigSeq] AS SMALLINT),
					CAST([ItemTypeSeq] AS TINYINT),
					CAST([01MD_Fraud_OutClearingActionSeq] AS SMALLINT),
					[NtfyRsn],
					[NtfyRsnDesc]
				FROM
					[Import].[01MD_Notification_Kappa_Config_HSBC];

				/**********************47*[CFG].[03MD_Field]*************************************************************************************************************/
				INSERT INTO
					[CFG].[03MD_Field]
					(
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
				SELECT
					[FieldSeq]	,
					[FieldName],
					[ItemTypeSeq],
					[ValidationType],
					[ValidationLength],
					[ValidationMinLength],
					[ValidationFailureMessage],
					[ClassName],
					[Type],
					[IsCodeLine]
				FROM
					[Import].[03MD_Field_HSBC];
				--------------------48--[CFG].[03MD_Error]-----------------------
				INSERT INTO
					[CFG].[03MD_Error]
					(
						[ErrorSeq],
						[Code],
						[PossibleSolution],
						[ScreenPriority]
					)
				SELECT
					[ErrorSeq]	,
					[ErrorCode],
					[PossibleSolution],
					[ScreenPriority]
				FROM
					[Import].[03MD_Error_HSBC];

				--------------------49--[CFG].[03MD_ErrorMappingAction]-----------------------
				INSERT INTO
					[CFG].[03MD_ErrorMappingAction]
					(
						[ErrorSeq],
						[03MD_OutClearingActionSeq]
					)
				SELECT
					[ErrorSeq]	,
					[03MD_OutClearingActionSeq]
				FROM
					[Import].[03MD_ErrorMappingAction_HSBC];

				--------------------50--[CFG].[03MD_ErrorMappingField]-----------------------
				INSERT INTO
					[CFG].[03MD_ErrorMappingField]
					(
						[ErrorSeq],
						[FieldSeq]
					)
				SELECT
					[ErrorSeq]	,
					[FieldSeq]
				FROM
					[Import].[03MD_ErrorMappingField_HSBC];

				--------------------51--[CFG].[03MD_OutClearingConfig]-----------------------
				INSERT INTO
					[CFG].[03MD_OutClearingConfig]
					(
						[03MD_OutClearingConfigSeq],
						[ErrorSeq],
						[OnBank],
						[IsAgency],
						[ItemTypeSeq],
						[ActionSeq],
						[TxSetOutClearingActionSeq],
						[IsCodeline],
						[CustomerNotificationReq],
						[CaseManagementReq],
						[CaseTypeID],
						[CasePrefix],
						[CasePostfix],
						[NtfyRsn],
						[NtfyRsnDesc],
						[ItemAdjustmentCode]
					)
				SELECT
					[03MD_OutClearingConfigSeq],
					CASE
						WHEN [ErrorSeq] = 'NULL'
						THEN NULL
						ELSE [ErrorSeq]
					END							AS [ErrorSeq],
					CASE
						WHEN [OnBank] = 'NULL'
						THEN NULL
						ELSE [OnBank]
					END							AS [OnBank],
					[IsAgency],
					[ItemTypeSeq],
					CASE
						WHEN [ActionSeq] = 'NULL'
						THEN NULL
						ELSE [ActionSeq]
					END							AS [ActionSeq],
					CASE
						WHEN [TxSetOutClearingActionSeq] = 'NULL'
						THEN NULL
						ELSE [TxSetOutClearingActionSeq]
					END							AS [TxSetOutClearingActionSeq],
					CASE
						WHEN [IsCodeline] = 'NULL'
						THEN NULL
						ELSE [IsCodeline]
					END							AS [IsCodeline],
					[CustomerNotificationReq],
					[CaseManagementReq],
					CASE
						WHEN [CaseTypeID] = 'NULL'
						THEN NULL
						ELSE [CaseTypeID]
					END							AS [CaseTypeID],
					CASE
						WHEN [CasePrefix] = 'NULL'
						THEN NULL
						ELSE [CasePrefix]
					END							AS [CasePrefix],
					CASE
						WHEN [CasePostfix] = 'NULL'
						THEN NULL
						ELSE [CasePostfix]
					END							AS [CasePostfix],
					CASE
						WHEN [NtfyRsn] = 'NULL'
						THEN NULL
						ELSE [NtfyRsn]
					END							AS [NtfyRsn],
					CASE
						WHEN [NtfyRsnDesc] = 'NULL'
						THEN NULL
						ELSE [NtfyRsnDesc]
					END							AS [NtfyRsn],
					[ItemAdjustmentCode]
				FROM
					[Import].[03MD_OutClearingConfig_HSBC];

				--------------------52--[CFG].[03DM_EntityStatesMapping]-----------------------
				INSERT INTO
					[CFG].[03DM_EntityStatesMapping]
					(
						[03DM_EntityStatesMappingSeq],
						[ItemTypeSeq],
						[03MD_OutClearingActionSeq],
						[03DM_OutEntityStateSeq],
						[IsCodeline],
						[IsItemError]
					)
				SELECT
					[03DM_EntityStatesMappingSeq],
					[ItemTypeSeq],
					CASE
						WHEN [03MD_OutClearingActionSeq] = 'NULL'
						THEN NULL
						ELSE [03MD_OutClearingActionSeq]
					END								AS [03MD_OutClearingActionSeq],
					[03DM_OutEntityStateSeq],
					CASE
						WHEN [IsCodeline] = 'NULL'
						THEN NULL
						ELSE [IsCodeline]
					END								AS [IsCodeline],
					CASE
						WHEN [IsItemError] = 'NULL'
						THEN NULL
						ELSE [IsItemError]
					END								AS [IsItemError]
				FROM
					[Import].[03DM_EntityStatesMapping_HSBC];

				--------------------52--[CFG].[03DM_EntityStatesMapping]-----------------------
				INSERT INTO
					[CFG].[06MD_APG_InClearingAction]
				SELECT
					[APGNoPayReasonCodeSeq],
					[CasePrefix],
					[CaseTypeId],
					[Suffix]
				FROM
					[Import].[06MD_APG_InClearingAction_HSBC]

				--------------------30--MSG13 - [CFG].[SI_GroupMapping]-----------------------------

				;
				WITH
					TransformedSITable
					(SI_GroupId, SpecialInstructionType, IsRepresentable)
				AS
					(
						SELECT
							SI_GroupId	,
							SIType,
							IsRepresentable
						FROM
							[import].[SI_GroupMapping_HSBC]
							UNPIVOT
								(
									SIApplicable
											FOR SIType IN ([Additional Details],
															[Alternative Address],
															[Detailed Advice],
															[Alternative Account],
															[Lotted Account],
															[Default],
															[SI Not Representable]
														)
								) AS Unp
						WHERE
							SIApplicable != 0
					)
				INSERT INTO
					CFG.SI_GroupMapping
					(
						InstructionType,
						Representable,
						SI_GroupID
					)
				SELECT
					InsType.InstructionType,
					IsRepresentable,
					SI_GroupId
				FROM
					TransformedSITable		AS TSI
				INNER JOIN
					CFG.SI_InstructionType	AS InsType
				ON
					TSI.SpecialInstructionType = InsType.InstructionName;

				-----------------------24-[CFG].[ReputablePayee]------------------------------------------------------------------

				INSERT INTO
					[CFG].[ReputablePayee]
					(
						ReputablePayeeId,
						[Name],
						[CreatedDate],
						UpdatedDate,
						CreatedBy,
						UpdatedBy,
						Deleted
					)
				SELECT
					[ReputablePayeeSequence],
					[Name],
					GETDATE(),
					GETDATE(),
					ORIGINAL_LOGIN(),
					ORIGINAL_LOGIN(),
					0
				FROM
					[Import].[ReputablePayee_HSBC];

				-----------------------25-[CFG].[FinalDecisionText]------------------------------------------------------------------
				INSERT INTO
					[CFG].[FinalDecisionText]
					(
						[FinalDecisionTextSeq],
						[SystemDecisionSeq],
						[UserDecisionSeq],
						[BusinessRuleDecisionSeq],
						[FinalDecisionSeq],
						[PostingDecisionSeq],
						[FinalPaymentStatusText]
					)
				SELECT
					[FinalDecisionTextSeq]	,
					CASE
						WHEN [SystemDecisionSeq] = 'NULL'
						THEN NULL
						ELSE [SystemDecisionSeq]
					END AS [SystemDecisionSeq],
					CASE
						WHEN [UserDecisionSeq] = 'NULL'
						THEN NULL
						ELSE [UserDecisionSeq]
					END AS [UserDecisionSeq],
					CASE
						WHEN [BusinessRuleDecisionSeq] = 'NULL'
						THEN NULL
						ELSE [BusinessRuleDecisionSeq]
					END AS [BusinessRuleDecisionSeq],
					CASE
						WHEN [FinalDecisionSeq] = 'NULL'
						THEN NULL
						ELSE [FinalDecisionSeq]
					END AS [FinalDecisionSeq],
					CASE
						WHEN [PostingDecisionSeq] = 'NULL'
						THEN NULL
						ELSE [PostingDecisionSeq]
					END AS [PostingDecisionSeq],
					CASE
						WHEN [FinalPaymentStatusText] = 'NULL'
						THEN NULL
						ELSE [FinalPaymentStatusText]
					END AS [FinalPaymentStatusText]
				FROM
					[Import].[FinalDecisionText_HSBC];

				INSERT INTO
					[CFG].[IndustryNoPayReasonMapUserFailReason]
					(
						[NoPayReasonCodesIndustrySeq],
						[UserFailReasonSeq]
					)
				SELECT
					[NoPayReasonCodesIndustrySeq],
					[UserFailReasonSeq]
				FROM
					[Import].[IndustryNoPayReasonMapUserFailReason_HSBC];

				-----------------------26-[CFG].[DecisionFunctionMapKappaNopayReason]------------------------------------------------------------------
				INSERT INTO
					[CFG].[DecisionFunctionMapKappaNopayReason]
					(
						KappaDecisionId,
						DecisionFunctionId
					)
				SELECT
					KappaDecisionId,
					DecisionFunctionId
				FROM
					[Import].[DecisionFunctionMapKappaNopayReason_HSBC];

				---------------------------53-[CFG].[WorkStreamCassConfig]---------------------------------------------------------------------------------

				INSERT INTO
					[CFG].[WorkStreamCassConfig]
					(
						[WorkStreamCassConfigSeq],
						[WorkStreamSeq],
						[IsSwitchedItem],
						[IsISOStop],
						[IsAPGStop],
						[IsISODuplicate],
						[IsAPGDuplicate]
					)
				SELECT
					[WorkStreamCassConfigSeq],
					[WorkStreamSeq],
					[IsSwitchedItem],
					[IsISOStop],
					[IsAPGStop],
					[IsISODuplicate],
					[IsAPGDuplicate]
				FROM
					[Import].[WorkStreamCassConfig_HSBC];

				---------------------------54-[CFG].[[UserPreference]]---------------------------------------------------------------------------------

				INSERT INTO
					[CFG].[UserPreference]
					(
						[UserPreferenceSeq],
						[IsAdditionalDetailCNRequired],
						[NarrativePrefix]
					)
				SELECT
					[UserPreferenceSeq],
					[IsAdditionalDetailCNRequired],
					[NarrativePrefix]
				FROM
					[Import].[UserPreference_HSBC];


				---------------------------54-[CFG].[AgencyType]---------------------------------------------------------------------------------
				INSERT INTO
					[CFG].[AgencyType]
					(
						[AgencyTypeId],
						[Description],
						[IsPayingFlow],
						[IsCollectingFlow],
						[IsBeneficiaryFlow]
					)
				SELECT
					[AgencyTypeId]	,
					[Description],
					[IsPayingFlow],
					[IsCollectingFlow],
					[IsBeneficiaryFlow]
				FROM
					[Import].[AgencyType_HSBC];

				---------------------------54-[CFG].[WorkstreamInSortCodeRange]---------------------------------------------------------------------------------



				---------------------------56-[CFG].[PostingResponseStatusMapQualifier]---------------------------------------------------------
				INSERT INTO
					[CFG].[PostingResponseStatusMapQualifier]
					(
						[PostingResponseStatusMapQualifierSeq],
						[PostingResponseStatusMapQualifierGroupSeq],
						[PostingResponseStatusSeq],
						[PostingResponseQualifierSeq]
					)
				SELECT
					[PostingResponseStatusMapQualifierSeq]	,
					[PostingResponseStatusMapQualifierGroupSeq],
					CASE
						WHEN [PostingResponseStatusSeq] = ''
						THEN NULL
						WHEN [PostingResponseStatusSeq] = 'NULL'
						THEN NULL
						ELSE [PostingResponseStatusSeq]
					END AS [PostingResponseStatusSeq],
					CASE
						WHEN [PostingResponseQualifierSeq] = ''
						THEN NULL
						WHEN [PostingResponseQualifierSeq] = 'NULL'
						THEN NULL
						ELSE [PostingResponseQualifierSeq]
					END AS [PostingResponseQualifierSeq]
				FROM
					[Import].[PostingResponseStatusMapQualifier_HSBC];

				---------------------------57-[CFG].[WorkgroupFinalResponse]---------------------------------------------------------
				INSERT INTO
					[CFG].[WorkgroupFinalResponse]
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
				FROM
					[Import].[WorkgroupFinalResponse_HSBC];
			END;

	END;
GO

EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'1.0.0',
	@level0type = N'SCHEMA',
	@level0name = N'CFG',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_InsertCFG_HSBC';

GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Insert into HSBC CFG Tables',
	@level0type = N'SCHEMA',
	@level0name = N'CFG',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_InsertCFG_HSBC';

GO
EXECUTE [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'iPSL.iCE.DEW.Database',
	@level0type = N'SCHEMA',
	@level0name = N'CFG',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_InsertCFG_HSBC';
