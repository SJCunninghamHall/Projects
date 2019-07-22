/*****************************************************************************************************
* Name              : [RefOut_GetAgencySortCodeData]
* Description  	    : This Stored Procedure will fetch the records from AgencySortCode table.
* Author			: Nisha Merline				   
*******************************************************************************************************
*Parameter Name				Type							   Description
*------------------------------------------------------------------------------------------------------

*******************************************************************************************************************************
* Amendment History
*------------------------------------------------------------------------------------------------------------------------------
* ID          Date             User					Reason
*****************************************************************************************************
* 001			28/02/2017 		Nisha Merline			Initial version
* 002			27/03/2017 		Ashish Kr Singh			Updated Schema
* 003			06/04/2017		Divya Singh			    Rename AgencyTokenId to ExternalAgencyId
* 004			10/04/2017 		Nisha Merline	        Changed condition Effective From and Expiry Date
* 005			12/04/2017 		Ashish Kr Singh	        Enchance sp and include wildcard concept
* 006			20/04/2017 		Ashish Kr Singh	        Fixed bug
* 007			25/04/2017 		Ashish Kr Singh	        Fixed bug for Wildcardcharacter
* 008			05/05/2017		Shiju					Joined three more tables(EISCDCNCCC,EISCDParticipantMaster and CTE) to get bank details)
* 009		    12/05/2017		Shiju                   Renamed HSBC and LBG Schema to REFOUT
* 010			12/05/2017		Divya Singh				Changed the LogExecption sp name to SqlErrorLog
* 011			24/07/2017		Divya Singh				Code Review Action remove unused Parameter 
* 012			27/07/2017		Champika B				Code Review Action Deadlock Proof Changes
* 013			01/08/2017		Champika B				SQL code alignment
* 014			02/08/2017		Shiju					Added AccountNumber as new column  Replaced StartAccountNumber and EndAccountNumber
* 015			04/09/2017		Champika B				Code Review Action remove version number
* 016			15/09/2017		Champika B				Number of Deadlock  retry value to config table
* 017			15/09/2017	    Champika B				DebitAgencySortCode replaced with ('00' + SettlementBank) 
														SettlementBank changed with DebitAgencySortCode in logic
* 018			09/11/2017		Subrat					Status <> 'D' changes
* 019			31/01/2018		Shiju					Added Date parameter and removed expiry date condition
* 020		    12/02/2018 	    Champika			    Added Temporal table logic to 
* 021		    25/08/2018 	    Jaisankar N.			Bug - 193813 fixed - Removed NULL condition for agency id and Modified condition to 
                                                        remove AgencySortCode - Sortcode if exists in EISCD resultset
* 022			28/08/2018		Champika B				Removed temp table		
* 023		    18/03/2019 	    Vasanthi Kharvi			CR - 204038 	
* 024		    21/03/2019 	    Nisha Merline			Code Review Action - 213254	
* 025		    27/03/2019 	    Nisha Merline			CR - 204038 - Modified @Agency NULL condition to fetch existing records	
******************************************************************************************************/
CREATE PROCEDURE [RefOut].[usp_GetAgencySortCodeData]
	@Date		DATETIME	= NULL,
	@AgencyType VARCHAR(6)	= NULL
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
		SET @TriesVal =
			(
				SELECT
					[VALUE]
				FROM
					Base.ConfigSettings
				WHERE
					[Name]	= 'DeadLockRetry'
			);
		SET @Date = ISNULL(@Date, CAST(GETDATE() AS DATE));
		SET @Date += ' 23:59:59';

		WHILE @Tries <= @TriesVal
			BEGIN

				BEGIN TRY

					SELECT
						GBC.ParticipantId,
						EPM.BankCode
					INTO
						#CTE
					FROM
						Base.EISCDParticipantMaster					AS EPM
					INNER JOIN
						[RefOut].[udf_GetAllBankParticipantID]()	AS GBC
					ON
						EPM.ParticipantId = GBC.ParticipantId;

					CREATE CLUSTERED INDEX nci_ParticipantId
					ON #CTE (ParticipantId, BankCode);

					SELECT
						AM	.AgencyId,
						AGSC.SortCode,
						AGSC.AccountNumber	AS StartAccountNumber,
						AGSC.AccountNumber	AS EndAccountNumber,
						AM.Name				AS AgencyName,
						AM.AgencyType		AS AgencyType,
						AM.ExternalAgencyId AS ExternalAgency,
						AGSC.Workflow		AS Workflow
					INTO
						#CTE_Agency
					FROM
						Manual.AgencyMaster
						FOR SYSTEM_TIME AS OF @Date AS AM
					INNER JOIN
						#CTE						AS GBC
					ON
						AM.ParentParticipantId = GBC.ParticipantId
					INNER JOIN
						Manual.AgencySortCode
						FOR SYSTEM_TIME AS OF @Date AS AGSC
					ON
						AM.AgencyId = AGSC.AgencyId
					WHERE
						(@AgencyType IS NULL)
					OR
						(
							@AgencyType IS NOT NULL
					AND
					(
							(AM.AgencyType IN
								(
									SELECT
										value
									FROM
										STRING_SPLIT(@AgencyType, ',')
								)
							)
					OR		AM.AgencyType IS NULL
						)
						);

					--- RESULT SET 1 - It contains all the AgencyId for Group Bank from AgencyMaster table which exists in AgencySortCode table.

					SELECT
						AgencyId,
						SortCode,
						StartAccountNumber,
						EndAccountNumber,
						AgencyName,
						AgencyType,
						ExternalAgency,
						Workflow
					FROM
						#CTE_Agency
					UNION ALL

					--- RESULT SET 2 - It is a resultset of SortCode for Group Bank which doest not exists in AgencySortCode table. 
					--  So we need to take sortcode by joining EISCDBankOffice, EISCDBank and EISCDParticipant Master based on ParticipantID exists in ParticipantAgency. 

					SELECT
						AM	.AgencyId,
						EBO.SortCode,
						NULL			AS StartAccountNumber,
						NULL			AS EndAccountNumber,
						AgencyName,
						AgencyType,
						ExternalAgency,
						0	--Workflow hardcoded to 0 for EISC data
					FROM
						Base.EISCDParticipantMaster AS EPM
					INNER JOIN
						(
							SELECT
								PA	.ParticipantId,
								AM.AgencyId,
								AM.Name				AS AgencyName,
								AM.AgencyType		AS AgencyType,
								AM.ExternalAgencyId AS ExternalAgency,
								GBC.BankCode
							FROM
								Manual.AgencyMaster
								FOR SYSTEM_TIME AS OF @Date AS AM
							INNER JOIN
								#CTE						AS GBC
							ON
								AM.ParentParticipantId = GBC.ParticipantId
							LEFT JOIN
								Manual.AgencySortCode
								FOR SYSTEM_TIME AS OF @Date AS AGSC
							ON
								AM.AgencyId = AGSC.AgencyId
							INNER JOIN
								Manual.ParticipantAgency
								FOR SYSTEM_TIME AS OF @Date AS PA
							ON
								AM.AgencyId = PA.AgencyId
							WHERE
								(@AgencyType IS NULL)
							OR
								(
									@AgencyType IS NOT NULL
							AND
							(
									(AM.AgencyType IN
										(
											SELECT
												value
											FROM
												STRING_SPLIT(@AgencyType, ',')
										)
									)
							OR		AM.AgencyType IS NULL
								)
								)
						)							AS AM
					ON
						EPM.ParticipantId = AM.ParticipantId
					INNER JOIN
						Base.EISCDBank				AS EB
					ON
						EB.BankCode = EPM.BankCode
					INNER JOIN
						Base.EISCDBankOffice		AS EBO
					ON
						EBO.BankId = EB.ID
					INNER JOIN
						Base.EISCDCNCCC				AS C
					ON
						C.BankOfficeID = EBO.ID
					INNER JOIN
						(
							SELECT
								CT	.Bankcode
							FROM
								Base.EISCDParticipantMaster AS PM
							INNER JOIN
								#CTE						AS CT
							ON
								CT.ParticipantId = PM.ParticipantId
						)							AS PMCT
					ON
						RIGHT('000000' + PMCT.BankCode, 6) = C.DebitAgencySortCode
					WHERE
						(
							EBO.[BankOfficeType] = 'M'
					OR		EBO.[BankOfficeType] = 'L'
						)
					AND
					(
							C.[Status] = 'M'
					OR		C.[Status] = 'F'
						)
					AND SortCode NOT IN
							(
								SELECT
									SortCode
								FROM
									#CTE_Agency
							)
					UNION ALL
					--- RESULT SET 3 - It is a resultset of SortCode for Group Bank exists in AgencySortCode table

					SELECT
						AM	.AgencyId,
						AGSC.SortCode,
						AGSC.AccountNumber	AS StartAccountNumber,
						AGSC.AccountNumber	AS EndAccountNumber,
						AM.Name				AS AgencyName,
						AM.AgencyType		AS AgencyType,
						AM.ExternalAgencyId AS ExternalAgency,
						AGSC.Workflow		AS Workflow
					FROM
						Manual.AgencyMaster
						FOR SYSTEM_TIME AS OF @Date AS AM
					INNER JOIN
						#CTE						AS GBC
					ON
						AM.ParentParticipantId = GBC.ParticipantId
					INNER JOIN
						Manual.AccessibleAgency
						FOR SYSTEM_TIME AS OF @Date AS AA
					ON
						AM.AgencyId = AA.AgencyId
					INNER JOIN
						Manual.AgencySortCode
						FOR SYSTEM_TIME AS OF @Date AS AGSC
					ON
						AGSC.AgencyId = AA.AccessibleAgencyId
					WHERE
						(@AgencyType IS NULL)
					OR
						(
							@AgencyType IS NOT NULL
					AND
					(
							(AM.AgencyType IN
								(
									SELECT
										value
									FROM
										STRING_SPLIT(@AgencyType, ',')
								)
							)
					OR		AM.AgencyType IS NULL
						)
						)
					UNION ALL
					--  SortCode exists in AgencySortCode table

					SELECT
						AM	.AgencyId,
						EBO.SortCode,
						NULL			AS StartAccountNumber,
						NULL			AS EndAccountNumber,
						AgencyName,
						AgencyType,
						ExternalAgency,
						0	--Workflow hardcoded to 0 for EISC data
					FROM
						Base.EISCDParticipantMaster AS EPM
					INNER JOIN
						(
							SELECT
								PA	.ParticipantId,
								AM.AgencyId,
								AM.Name				AS AgencyName,
								AM.AgencyType		AS AgencyType,
								AM.ExternalAgencyId AS ExternalAgency
							FROM
								Manual.AgencyMaster
								FOR SYSTEM_TIME AS OF @Date AS AM
							INNER JOIN
								#CTE						AS GBC
							ON
								AM.ParentParticipantId = GBC.ParticipantId
							INNER JOIN
								Manual.AccessibleAgency
								FOR SYSTEM_TIME AS OF @Date AS AA
							ON
								AM.AgencyId = AA.AgencyId
							LEFT JOIN
								Manual.AgencySortCode
								FOR SYSTEM_TIME AS OF @Date AS AGSC
							ON
								AGSC.AgencyId = AA.AccessibleAgencyId
							INNER JOIN
								Manual.ParticipantAgency
								FOR SYSTEM_TIME AS OF @Date AS PA
							ON
								AA.AccessibleAgencyId = PA.AgencyId
							WHERE
								(@AgencyType IS NULL)
							OR
								(
									@AgencyType IS NOT NULL
							AND
							(
									(AM.AgencyType IN
										(
											SELECT
												value
											FROM
												STRING_SPLIT(@AgencyType, ',')
										)
									)
							OR		AM.AgencyType IS NULL
								)
								)
						)							AS AM
					ON
						EPM.ParticipantId = AM.ParticipantId
					INNER JOIN
						Base.EISCDBank				AS EB
					ON
						EB.BankCode = EPM.BankCode
					INNER JOIN
						Base.EISCDBankOffice		AS EBO
					ON
						EBO.BankId = EB.ID
					INNER JOIN
						Base.EISCDCNCCC				AS C
					ON
						C.BankOfficeID = EBO.ID
					INNER JOIN
						(
							SELECT
								CT	.Bankcode
							FROM
								Base.EISCDParticipantMaster AS PM
							INNER JOIN
								#CTE						AS CT
							ON
								CT.ParticipantId = PM.ParticipantId
						)							AS PMCT
					ON
						RIGHT('000000' + PMCT.BankCode, 6) = C.DebitAgencySortCode
					WHERE
						(
							EBO.[BankOfficeType] = 'M'
					OR		EBO.[BankOfficeType] = 'L'
						)
					AND
					(
							C.[Status] = 'M'
					OR		C.[Status] = 'F'
						)
					AND SortCode NOT IN
							(
								SELECT
									SortCode
								FROM
									#CTE_Agency
							)
					UNION ALL

					--- RESULT SET 4 SortCode exists in AgencySortCode table

					SELECT
						GM	.AgencyId,
						AGSC.SortCode,
						AGSC.AccountNumber	AS StartAccountNumber,
						AGSC.AccountNumber	AS EndAccountNumber,
						GM.AgencyName,
						GM.AgencyType,
						GM.ExternalAgency,
						AGSC.Workflow		AS Workflow
					FROM
						Manual.AgencyMaster
						FOR SYSTEM_TIME AS OF @Date AS AM
					INNER JOIN
						#CTE						AS GBC
					ON
						AM.ParentParticipantId = GBC.ParticipantId
					INNER JOIN
						Manual.AgencySortCode
						FOR SYSTEM_TIME AS OF @Date AS AGSC
					ON
						AM.AgencyId = AGSC.AgencyId
					CROSS JOIN
						(
							SELECT
								AM	.AgencyId,
								AA.AccessibleAgencyId,
								AM.Name				AS AgencyName,
								AM.AgencyType		AS AgencyType,
								AM.ExternalAgencyId AS ExternalAgency
							FROM
								Manual.AgencyMaster
								FOR SYSTEM_TIME AS OF @Date AS AM
							INNER JOIN
								#CTE						AS GBC
							ON
								AM.ParentParticipantId = GBC.ParticipantId
							LEFT JOIN
								Manual.AccessibleAgency
								FOR SYSTEM_TIME AS OF @Date AS AA
							ON
								AM.AgencyId = AA.AgencyId
							WHERE
								AA.AccessibleAgencyId = 0
						)							AS GM
					WHERE
						GM.AgencyId != AM.AgencyId
					AND
					(
							(@AgencyType IS NULL)
					OR
						(
							@AgencyType IS NOT NULL
					AND
					(
							(AM.AgencyType IN
								(
									SELECT
										value
									FROM
										STRING_SPLIT(@AgencyType, ',')
								)
							)
					OR		AM.AgencyType IS NULL
						)
						)
						)
					UNION ALL

					--- SortCode does not exists in AgencySortCode table
					SELECT
						GmAgencyID	,
						EBO.SortCode,
						NULL			AS StartAccountNumber,
						NULL			AS EndAccountNumber,
						AgencyName,
						AgencyType,
						ExternalAgency,
						0	--Workflow hardcoded to 0 for EISC data
					FROM
						Base.EISCDParticipantMaster AS EPM
					INNER JOIN
						(
							SELECT
								PA	.ParticipantId,
								GM.AgencyId		AS GmAgencyID,
								GM.AgencyName,
								GM.AgencyType	AS AgencyType,
								GM.ExternalAgency
							FROM
								Manual.AgencyMaster
								FOR SYSTEM_TIME AS OF @Date AS AM
							INNER JOIN
								#CTE						AS GBC
							ON
								AM.ParentParticipantId = GBC.ParticipantId
							INNER JOIN
								Manual.ParticipantAgency
								FOR SYSTEM_TIME AS OF @Date AS PA
							ON
								AM.AgencyId = PA.AgencyId
							LEFT JOIN
								Manual.AgencySortCode
								FOR SYSTEM_TIME AS OF @Date AS AGSC
							ON
								AM.AgencyId = AGSC.AgencyId
							CROSS JOIN
								(
									SELECT
										AM	.AgencyId,
										AA.AccessibleAgencyId,
										AM.Name				AS AgencyName,
										AM.AgencyType		AS AgencyType,
										AM.ExternalAgencyId AS ExternalAgency
									FROM
										Manual.AgencyMaster
										FOR SYSTEM_TIME AS OF @Date AS AM
									INNER JOIN
										#CTE						AS GBC
									ON
										AM.ParentParticipantId = GBC.ParticipantId
									LEFT JOIN
										Manual.AccessibleAgency
										FOR SYSTEM_TIME AS OF @Date AS AA
									ON
										AM.AgencyId = AA.AgencyId
									WHERE
										AA.AccessibleAgencyId = 0
								)							AS GM
							WHERE
								GM.AgencyId != AM.AgencyId
							AND SortCode IS NULL
							AND
							(
									(@AgencyType IS NULL)
							OR
								(
									@AgencyType IS NOT NULL
							AND
							(
									(AM.AgencyType IN
										(
											SELECT
												value
											FROM
												STRING_SPLIT(@AgencyType, ',')
										)
									)
							OR		AM.AgencyType IS NULL
								)
								)
								)
						)							AS AM
					ON
						EPM.ParticipantId = AM.ParticipantId
					INNER JOIN
						Base.EISCDBank				AS EB
					ON
						EB.BankCode = EPM.BankCode
					INNER JOIN
						Base.EISCDBankOffice		AS EBO
					ON
						EBO.BankId = EB.ID
					INNER JOIN
						Base.EISCDCNCCC				AS C
					ON
						C.BankOfficeID = EBO.ID
					INNER JOIN
						(
							SELECT
								CT	.Bankcode
							FROM
								Base.EISCDParticipantMaster AS PM
							INNER JOIN
								#CTE						AS CT
							ON
								CT.ParticipantId = PM.ParticipantId
						)							AS PMCT
					ON
						RIGHT('000000' + PMCT.BankCode, 6) = C.DebitAgencySortCode
					WHERE
						(
							EBO.[BankOfficeType] = 'M'
					OR		EBO.[BankOfficeType] = 'L'
						)
					AND
					(
							C.[Status] = 'M'
					OR		C.[Status] = 'F'
						);

					BREAK;

				END TRY
				BEGIN CATCH
					IF (ERROR_NUMBER() = 1205)
						BEGIN
							SET @Tries = @Tries + 1;
							IF @Tries <= @TriesVal
								CONTINUE;
							ELSE
								THROW;
						END;
					ELSE
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
	@level1name = N'usp_GetAgencySortCodeData';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'This Stored Procedure will fetch the records from AgencySortCode table',
	@level0type = N'SCHEMA',
	@level0name = N'RefOut',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetAgencySortCodeData';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'RefOut',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_GetAgencySortCodeData';
GO
GRANT
	EXECUTE
ON OBJECT::[RefOut].[usp_GetAgencySortCodeData]
TO
	[Reference_Lloyds_Access];
GO
GRANT
	EXECUTE
ON OBJECT::[RefOut].[usp_GetAgencySortCodeData]
TO
	[Reference_HSBC_Access];