/*****************************************************************************************************
* Name              : [usp_GetTSBSortCodeOutboundToFraud]
* Description  	    : This Stored Procedure will fetch the Sortcode from EISCD table.
* Author			: Jaisankar Navarathinam
*******************************************************************************************************
*Parameter Name				Type							   Description
*------------------------------------------------------------------------------------------------------

*******************************************************************************************************************************
* Amendment History
*------------------------------------------------------------------------------------------------------------------------------
* ID			Date             User					Reason
*****************************************************************************************************
* 001			23/02/2017 		Jaisankar N.			Initial version
* 002			09/05/2017 		Divya Singh				Changed Schema from LBG to RefOut
* 003			12/05/2017		Divya Singh				Changed the LogExecption sp name to SqlErrorLog
* 004			25/05/2017		Jaisankar N		        Bug Fix ID 105962
* 005			08/06/2017 		Divya Singh				Added AgenyName , AgencyFlag, AgencyAccount column
* 006			13/06/2017 		Nisha Merline			Code review action 109399
* 007			15/06/2017      Champika B				Added Header and Footer Records
* 008			16/06/2017		Shiju B					Added Status <> 'N' in CNCCC Table condition
* 009			27/06/2017		Bhaskar Reddy			Removed unused spaces from SP
* 009			19/07/2017 		Divya Singh				Bug Fix(119857) Changed where condition ParticipantMaster to GroupBankConfig
* 010			26/07/2017		Shiju					Bug Fix Agency Name restricted to 50 instead of 20  
* 011			27/07/2017		Champika B				Code Review Action Deadlock Proof Changes
* 012			01/08/2017		Champika B				SQL code alignment
* 013			24/08/2017		Champika B				BrandMaster table for BrandName
* 014			04/09/2017		Champika B				Code Review Action remove version number
* 015			14/09/2017		Byamakesh Mohapatra		('00' + SettlementBank) replaced with DebitAgencySortCode
* 016			15/09/2017		Champika B				Number of Deadlock  retry value to config table
* 017			02/11/2017		Subrat					Brand master changes
* 018			09/11/2017		Subrat					Status <> 'D' changes 
* 019			13/02/2018		Champika B				Temporal logic and  @Environment added
* 020		    27/02/2018		Champika B				Get @Environment from ConfigSettings   
******************************************************************************************************/
CREATE PROCEDURE [RefOut].[usp_GetTSBSortCodeOutboundToFraud]
	@Date	DATETIME	= NULL
AS
	BEGIN

		SET NOCOUNT ON;

		DECLARE @ErrorNumber INT;
		DECLARE @ErrorMessage VARCHAR(4000);
		DECLARE @Severity INT;
		DECLARE @State INT;
		DECLARE @Procedure VARCHAR(128);
		DECLARE @Line INT;
		DECLARE @Tries INT = 1;
		DECLARE @TriesVal INT;
		DECLARE @Environment SMALLINT	=
					(
						SELECT
							[Value]
						FROM
							[Base].[ConfigSettings]
						WHERE
							[NAME]	= 'DefaultEnvironmentSetting'
					);

		SET @TriesVal =
			(
				SELECT
					[VALUE]
				FROM
					base.ConfigSettings
				WHERE
					[Name]	= 'DeadLockRetry'
			);
		SET @Date = ISNULL(@Date, GETDATE());

		WHILE @Tries <= @TriesVal
			BEGIN

				BEGIN TRY

					BEGIN TRAN;

					SELECT
						'1'									AS RecordType,
						CAST(BO.SortCode AS VARCHAR(20))	AS SortCodeID,
						--,(CASE  WHEN BR.BrandName  IS NULL  THEN (SELECT BM.BrandName FROM Manual.BrandMaster BM WHERE BM.ClientParticipantID = ASPA.ParentParticipantId) ELSE BR.BrandName END )AS BrandId
						(CASE
							WHEN 1 = 1
							THEN
								(
									SELECT	(CASE
												WHEN NOT EXISTS
															(
																SELECT
																	1
																FROM
																	[Manual].[BrandMaster]
																	FOR SYSTEM_TIME AS OF @Date AS BM
																INNER JOIN
																	[Manual].BrandSortCodeDetails
																	FOR SYSTEM_TIME AS OF @Date AS BSD
																ON
																	BM.BrandID = BSD.BrandMasterID
																AND BM.Environment = @Environment
																AND BSD.Environment = @Environment
																WHERE
																	BSD.SortCode = BO.SortCode
															)
												THEN
													(
														-----------------------------------------------------------
														SELECT	(CASE
																	WHEN EXISTS
																			(
																				SELECT
																					1
																				FROM
																					Base.GroupBankConfig		AS GBC
																				INNER JOIN
																					[Manual].BrandMaster
																					FOR SYSTEM_TIME AS OF @Date AS BM1
																				ON
																					BM1.BrandID = GBC.BrandId
																				AND BM1.Environment = @Environment
																				WHERE
																					GBC.ParticipantId =
																					(
																						SELECT	TOP 1
																								DebitAgencySortCode AS ParticipantId
																						FROM
																								base.EISCDBankOffice	AS BO1
																						INNER JOIN
																								Base.EISCDCNCCC			AS CC
																						ON
																							CC.BankOfficeID = BO1.ID
																						WHERE
																								SortCode = BO.SortCode
																					)
																			)
																	THEN (
																			(
																				SELECT
																					BM1.BrandName
																				FROM
																					Base.GroupBankConfig		AS GBC
																				INNER JOIN
																					[Manual].BrandMaster
																					FOR SYSTEM_TIME AS OF @Date AS BM1
																				ON
																					BM1.BrandID = GBC.BrandId
																				AND BM1.Environment = @Environment
																				WHERE
																					GBC.ParticipantId =
																					(
																						SELECT	TOP 1
																								RIGHT('000000' + BankCode, 6) AS ParticipantId
																						FROM
																								base.EISCDBankOffice	AS BO1
																						INNER JOIN
																								Base.EISCDBank			AS EB
																						ON
																							EB.ID = BO1.BankId
																						WHERE
																								SortCode = BO.SortCode
																					)
																			)
																		)
																END
																)	AS BrandName
													---------------------------------------------------------------------
													)
												ELSE
												(
													SELECT
														BM	.BrandName
													FROM
														[Manual].[BrandMaster]
														FOR SYSTEM_TIME AS OF @Date AS BM
													INNER JOIN
														[Manual].BrandSortCodeDetails
														FOR SYSTEM_TIME AS OF @Date AS BSD
													ON
														BM.BrandID = BSD.BrandMasterID
													AND BSD.Environment = @Environment
													WHERE
														BSD.SortCode = BO.SortCode
												)
											END
											)	AS BrandName
								)
						END
						)									AS BrandID,
						ParticipantMaster.ParticipantId		AS ParticipantID,
						CASE
							WHEN ISNULL(GBC.ParticipantId, 0) = 0
							THEN 'Y'
							ELSE 'N'
						END									AS AgencyFlag,
						NULL								AS AgencyAccount,
						SUBSTRING(ASPA.Name, 1, 50)			AS AgencyBankName,
						'D'									AS DirectIndirect
					INTO
						#CTE
					FROM
						[Base].[EISCDBankOffice]						AS BO
					LEFT JOIN
						Base.EISCDBank									AS EB
					ON
						EB.ID = BO.BankId
					AND
					(
							BO.BankOfficeType = 'M'
					OR		BO.BankOfficeType = 'L'
						)
					INNER JOIN
						[Base].[EISCDCNCCC]								AS C
					ON
						BO.ID = C.BankOfficeID
					AND
					(
							C.[Status] = 'F'
					OR		C.[Status] = 'M'
						)
					INNER JOIN
						[Base].[EISCDParticipantMaster]					AS ParticipantMaster
					ON
						ParticipantMaster.BankCode = EB.BankCode
					INNER JOIN
						[Common].[udf_GetBankParticipantID]('Lloyds')	AS GroupBank
					ON
						GroupBank.ParticipantId = C.DebitAgencySortCode
					LEFT JOIN
						Base.GroupBankConfig							AS GBC
					ON
						GBC.ParticipantId = ParticipantMaster.ParticipantId
					LEFT JOIN
						Manual.BrandMaster
						FOR SYSTEM_TIME AS OF @Date					AS BR
					ON
						BR.BrandID = GBC.BrandId
					AND BR.Environment = @Environment
					LEFT JOIN
						(
							SELECT
								AM	.Name,
								PA.ParticipantId,
								AM.ParentParticipantId
							FROM
								Manual.AgencyMaster
								FOR SYSTEM_TIME AS OF @Date AS AM
							INNER JOIN
								Manual.ParticipantAgency	AS PA
							ON
								PA.AgencyId = AM.AgencyId
							AND AM.Environment = @Environment
						)												AS ASPA
					ON
						ParticipantMaster.ParticipantId = ASPA.ParticipantId;

					SELECT
						'0'					AS RecordType,
						'Sortcode'			AS Sortcode,
						'BrandID'			AS BrandID,
						'ParticipantID'		AS ParticipantID,
						'AgencyFlag'		AS AgencyFlag,
						'AgencyAccount'		AS AgencyAccount,
						'AgencyBankName'	AS AgencyBankName,
						'DirectIndirect'	AS DirectIndirect
					UNION ALL
					SELECT
						RecordType	,
						SortCodeID		AS Sortcode,
						BrandID			AS BrandID,
						ParticipantID,
						AgencyFlag,
						AgencyAccount,
						AgencyBankName,
						DirectIndirect
					FROM
						#CTE
					WHERE
						UPPER(BrandID) = 'TSB'
					UNION ALL
					SELECT
						'2'								AS RecordType,
						CAST(GETDATE() AS VARCHAR(20))	AS Sortcode,
						CAST(
							(
								SELECT
									COUNT(*)
								FROM
									#CTE
								WHERE
									UPPER(BrandID) = 'TSB'
							) AS VARCHAR(20))	AS BrandID,
						NULL							AS ParticipantID,
						NULL							AS AgencyFlag,
						NULL							AS AgencyAccount,
						NULL							AS AgencyBankName,
						NULL							AS DirectIndirect;

					IF (XACT_STATE()) = 1
						BEGIN
							COMMIT	TRANSACTION;
						END;
					BREAK;
				END TRY
				BEGIN CATCH
					IF (ERROR_NUMBER() = 1205)
						BEGIN
							SET @Tries = @Tries + 1;
							IF @Tries <= 5
								CONTINUE;
							ELSE
								THROW;
						END;
					ELSE
					-- transaction Rollback
					IF (XACT_STATE()) <> 0
						BEGIN
							ROLLBACK TRANSACTION;
						END;
					SET @ErrorNumber = ERROR_NUMBER();
					SET @ErrorMessage = ERROR_MESSAGE();
					SET @Severity = ERROR_SEVERITY();
					SET @State = ERROR_STATE();
					SET @Line = ERROR_LINE();
					SET @Procedure = ERROR_PROCEDURE();
					EXEC [Base].[usp_SqlErrorLog]
						@ErrorNumber,
						@Severity,
						@State,
						@Procedure,
						@Line,
						@ErrorMessage;

					THROW;
				END CATCH;
			END;
	END;
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'iPSL.ReferenceDataDB',
	@level0type = N'SCHEMA',
	@level0name = N'RefOut',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetTSBSortCodeOutboundToFraud';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This Stored Procedure will fetch the Sortcode from EISCD tables.',
	@level0type = N'SCHEMA',
	@level0name = N'RefOut',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetTSBSortCodeOutboundToFraud';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'RefOut',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetTSBSortCodeOutboundToFraud';
GO
GRANT
	EXECUTE
ON OBJECT::[RefOut].[usp_GetTSBSortCodeOutboundToFraud]
TO
	[Reference_Lloyds_Access];

