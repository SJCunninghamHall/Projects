create procedure dbo.SampleTVPUpdate
AS
BEGIN
	declare @dummy [Base].[tv_Document_New]

	insert into @dummy
	([DocumentId], [ParticipantId], SubmissionDate, Mechanism,SubmissionCounter, CreatedDate)
	VALUES (1,666, getDate(),'A',0,getdate());

	insert into @dummy
	([DocumentId], [ParticipantId], SubmissionDate, Mechanism,SubmissionCounter, CreatedDate)
	VALUES (2,667, getDate(),'A',0,getdate())

	select * from @dummy;


	UPDATE  @dummy set [ParticipantId] =900 where [ParticipantId] =666
	select * from @dummy;
END