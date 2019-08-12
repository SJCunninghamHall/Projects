
--exec [dbo].[SampleTVPUpdate_Compiled]

CREATE procedure [dbo].[SampleTVPUpdate_Compiled]
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE='us_english')
 
	declare @dummy [Base].[tv_Document_New]
	declare @dummy2 [Base].[tv_Document_New]
	
	insert into @dummy
	([DocumentId], [ParticipantId], SubmissionDate, Mechanism,SubmissionCounter, CreatedDate)
	VALUES (1,666, getDate(),'A',0,getdate());

	insert into @dummy
	([DocumentId], [ParticipantId], SubmissionDate, Mechanism,SubmissionCounter, CreatedDate)
	VALUES (2,666, getDate(),'A',0,getdate())


	insert into @dummy
	([DocumentId], [ParticipantId], SubmissionDate, Mechanism,SubmissionCounter, CreatedDate)
	VALUES (3,668, getDate(),'A',0,getdate());

	insert into @dummy
	([DocumentId], [ParticipantId], SubmissionDate, Mechanism,SubmissionCounter, CreatedDate)
	VALUES (4,669, getDate(),'A',0,getdate());
	-- ------------------------------------------------------------------------------------------------------
 
	--UPDATE @dummy   
	--	SET [ParticipantIdA] = r.[ParticipantIdA]
	--from  
	-- (select 
	--	d.[DocumentId] as [DocumentIdA], 
	--	d.[ParticipantId] as [ParticipantIdA], 
	--	e.[DocumentId], 
	--	e.[ParticipantId]
	-- from @dummy d
	--	INNER JOIN @dummy e on d.[DocumentId] = e.[DocumentId]
	--) r 

	--Do updates on dummy
	update @dummy set Mechanism =1;

	insert into @dummy2([DocumentId], [ParticipantId], SubmissionDate, Mechanism,SubmissionCounter, CreatedDate)
	select [DocumentId], [ParticipantId], SubmissionDate, Mechanism,SubmissionCounter, CreatedDate from @dummy 

	select [DocumentId], [ParticipantId], SubmissionDate, Mechanism,SubmissionCounter, CreatedDate from @dummy

END