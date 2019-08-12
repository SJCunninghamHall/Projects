/* 
	
		--Test Code
		DECLARE @RC				int;
		DECLARE @tv_StgCore		[Base].[tv_StgCore];
		DECLARE @xmlMessageId	bigint;
		DECLARE @ShredTime		datetime2(2);
		DECLARE @TransformTime	datetime2(2);
		DECLARE @BusinessDate    VARCHAR (10);	 

		

		-- ----------------------------------------------------------------------------------
		-- StgCore
		-- ----------------------------------------------------------------------------------
		DECLARE @ExtractId               VARCHAR (26);
		DECLARE @ProcessingParticipantId VARCHAR (6);
		DECLARE @ExtMessageType          VARCHAR (6);
		DECLARE @IntMessageType          VARCHAR (6);
		DECLARE @MessageSource           VARCHAR (5);
		DECLARE @MessageDestination      VARCHAR (5);
		DECLARE @RecordCount             INT;
		DECLARE @ICN_Id                  BIGINT;

		SET @ExtractId	='1';				--VARCHAR (26)
		SET @ProcessingParticipantId='';	--VARCHAR (6)
		SET @ExtMessageType	='MSG06';		--VARCHAR (6)
		SET @IntMessageType	='06MA01';		--VARCHAR (6)
		SET @MessageSource	='MO';			--VARCHAR (5)
		SET @MessageDestination	='IA';		--VARCHAR (5)
		SET @RecordCount	=3000		  	--INT;
		SET @ICN_Id	=	0;				--BIGINT;

		INSERT INTO @tv_StgCore
		(
			[BusinessDate],
			[ExtractId],
			[ProcessingParticipantId],
			[ExtMessageType],
			[IntMessageType],
			[MessageSource],
			[MessageDestination],
			[RecordCount],
			[ICN_Id]
		)
		VALUES 
		(
			@BusinessDate,
			@ExtractId,
			@ProcessingParticipantId,
			@ExtMessageType,
			@IntMessageType,
			@MessageSource,
			@MessageDestination,
			@RecordCount,
			@ICN_Id
		);

		EXECUTE @RC = [Base].[WriteTVPToDatabase] @tv_StgCore;
		GO

*/
CREATE PROCEDURE [Base].[WriteTVPToDatabase]
		@tv_StgCore			tv_StgCore READONLY
 AS
BEGIN
	SET NOCOUNT ON 

	DECLARE @CoreId BIGINT; 
	SELECT 
		'Result' as result, 
		s.* 
	from 
		@tv_StgCore s

END