CREATE PROCEDURE [Base].[usp_Calculate_Final_Credit_Item_ISO_native]
    @TVPCredit Base.tv_Credit_New READONLY,
    @MessageType VARCHAR(6),
	@IntMessageType VARCHAR(6) = NULL,
	@ExtractIdParam VARCHAR(26) = NULL,
	@ChargingParticipantId VARCHAR(6) = NULL,
	@ICNEntityHolder [Base].[ICNEntity_New] READONLY

/****************************************************************************************************************************
* Name				: [Base].[usp_Calculate_Final_Credit_Item_ISO]
* Description		: This stored procedure calculates the final credit items.
* Type of Procedure : Interpreted stored procedure

* 1.0.0		001		19-JUl-2019		Alpa Buddhabhatti		initial Release
*****************************************************************************************************************************/
--WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER  
-- AS BEGIN ATOMIC WITH  (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE=N'us_english')  
 AS
 Begin
 print 1;
 end;