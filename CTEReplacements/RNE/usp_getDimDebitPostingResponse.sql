CREATE	PROCEDURE [RNEReport].[usp_getDimDebitPostingResponse]
@BusinessDateRangeStart BIGINT
,@BusinessDateRangeEnd BIGINT
/*****************************************************************************************************
* Name				: [RNEReport].[usp_getDimDebitPostingResponse]
* Description		: This stored procedure exports the data for DimDebitPostingResponse from STAR to RnEReportDataWarehouse.
* Type of Procedure : Interpreted stored procedure
* Author			: Pavan Kumar Manneru
* Creation Date		: 29/08/2017
* Last Modified		: N/A
*******************************************************************************************************/
AS 

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;

	SELECT	
		RD.InternalId
		,FD.DebitId
		,PostingType
		,ResponseStatus
		--Response state will be updated for CreditId in case of Benficiary flow hence giving preference 
		,COALESCE(En1.EntityId,En.EntityId) AS EntityId 
		,COALESCE(En1.EntityState,En.EntityState) AS EntityState
		,ROW_NUMBER () OVER (
		
		PARTITION BY 
			RD.InternalId 
		ORDER BY
			CASE 
				--In MultipleDebit scenario, Single Credit Entity state has to match with all debits hence hard code values
				WHEN ResponseStatus = 'N' AND En.EntityState = 960 THEN 1
				WHEN ResponseStatus = 'Y' AND En.EntityState = 970 THEN 2 
				ELSE 9 
			END
		
		) RKD
		,NPAAccount
		,NPASortCode
	INTO 
		#DebitItems
	FROM 
		Post.ResponseDetail RD
	INNER JOIN 
		RNE.vw_FinalDebit_TSet FD
	ON 
		RD.ItemId = FD.DebitId
	INNER JOIN 
		RNE.vw_FinalCredit_TSet FC
	ON 
		FD.TransactionSetId = FC.TransactionSetId
	INNER JOIN 
		Post.Response resp
	ON 
		RD.ResponseId = resp.InternalId
	LEFT JOIN 
		Base.Entity En1
	ON 
		Resp.CoreId = En1.CoreId
	AND 
		RD.ItemId = En1.EntityIdentifier
	LEFT JOIN 
		Base.Entity En
	ON 
		Resp.CoreId = En.CoreId
	AND 
		FC.CreditId = En.EntityIdentifier		
	WHERE 
		RD.InternalId BETWEEN @BusinessDateRangeStart AND @BusinessDateRangeEnd	


	SELECT	
		InternalId
		,DebitId
		,PostingType
		,ResponseStatus
		,EntityId
		,EntityState
		,NPAAccount
		,NPASortCode
	FROM 
		DebitItems
	WHERE 
		RKD = 1

END		
GO

GRANT Execute ON [RNEReport].[usp_getDimDebitPostingResponse] to [RNEReportAccess]

GO

EXECUTE sp_addextendedproperty @name = N'Version', @value = N'$(Version)',
    @level0type = N'SCHEMA', @level0name = N'RNEReport', @level1type = N'PROCEDURE',
    @level1name = N'usp_getDimDebitPostingResponse';
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'This stored procedure exports the data for DimDebitPostingResponse from STAR to RnEReportDataWarehouse.',
    @level0type = N'SCHEMA', @level0name = N'RNEReport', @level1type = N'PROCEDURE',
    @level1name = N'usp_getDimDebitPostingResponse';
GO
EXECUTE sp_addextendedproperty @name = N'Component', @value = N'STAR',
    @level0type = N'SCHEMA', @level0name = N'RNEReport', @level1type = N'PROCEDURE',
    @level1name = N'usp_getDimDebitPostingResponse';
GO