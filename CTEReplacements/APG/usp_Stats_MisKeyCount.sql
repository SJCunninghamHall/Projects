/****************************************************************************************
* Stored Procedure:[dbo].[usp_Stats_MisKeyCount]
* Description: Get MisKeyCount for creating MIReport.
* Author     :Bhavya 
*****************************************************************************************
* Amendment History
*****************************************************************************************
* Version		  ID							 Date                  Reason
* 1.0.0			 001			               06 Oct 2017        Get MisKeyCount for creating MIReport.
*****************************************************************************************/
CREATE PROCEDURE [dbo].[usp_Stats_MisKeyCount]
AS
	BEGIN
		SET NOCOUNT ON; 

		BEGIN TRY

			SELECT
				ICD.iAEUserid,
				CONVERT(VARCHAR, ICD.tChangeDateTime, 112) AS BusinessDate,
				COUNT(ICD.bAEStatus)						AS MiskeyCount
			INTO
				#MiskeyDetails
			FROM
				[dbo].[ItemCommonData] AS ICD
			WHERE
				ICD.bdoctype IN ( 1,
									3
								) -- 1=Good Item, 3 = Reject 
			AND ICD.baestatus = 2 -- AE Complete
			AND ICD.mamount <> ICD.mAEAmount --Amount <> AEAmount
			AND ICD.iaeuserid = ICD.iaeuserid
			GROUP BY
				ICD.iAEUserid,
				CONVERT(VARCHAR, ICD.tChangeDateTime, 112);


			CREATE CLUSTERED INDEX ci_UI_BD
			ON #MiskeyDetails (iAEUserid, BusinessDate);

			SELECT
				[MK].[BusinessDate],
				VU.sFullName	AS Username,
				[MK].[MiskeyCount]
			FROM
				[dbo].[ItemCommonData]	AS IC
			JOIN
				#MiskeyDetails			AS MK
			ON
				IC.iAEUserID = MK.iAEUserID
			AND [MK].[BusinessDate] = CONVERT(VARCHAR, IC.tChangeDateTime, 112)
			JOIN
				[dbo].[ValidUsers]		AS VU
			ON
				IC.iAEUserid = VU.iUserId
			WHERE
				IC.bdoctype IN ( 1,
								3
							) --1=Good Item, 3 = Reject 
			AND IC.fdeleted = 0 -- Not Deleted
			AND IC.baestatus <> 0
			GROUP BY
				[MK].[BusinessDate],
				IC.iAEUserid,
				VU.sFullName,
				[MK].[MiskeyCount]
			ORDER BY
				[MK].[MiskeyCount] DESC;

		END TRY
		BEGIN CATCH
			THROW;
		END CATCH;
	END;
GO
GRANT
	EXECUTE
ON [dbo].[usp_Stats_MisKeyCount]
TO
	[MI_User]
AS [dbo];
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Component',
	@value = N'Get MisKeyCount',
	@level0type = N'SCHEMA',
	@level0name = N'dbo',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Stats_MisKeyCount';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'MS_Description',
	@value = N'Get IQV Status Data',
	@level0type = N'SCHEMA',
	@level0name = N'dbo',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Stats_MisKeyCount';
GO
EXEC [sys].[sp_addextendedproperty]
	@name = N'Version',
	@value = N'$(Version)',
	@level0type = N'SCHEMA',
	@level0name = N'dbo',
	@level1type = N'PROCEDURE',
	@level1name = N'usp_Stats_MisKeyCount';
GO


