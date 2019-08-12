
CREATE PROCEDURE [Base].native_test
 @TVPDocument [Base].t_test  readonly
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE='us_english')
 DECLARE @i INT,  @max INT, @DocMessId INT, @XMLMessID INT
 --DECLARE @TVPDocument						[Base].t_test 
				SELECT  @i =  min( [Recordnumber]), @max = Count( [Recordnumber]) FROM @TVPDocument Doc
				

				WHILE @i <= @max
				BEGIN
					SELECT @DocMessId = Id
					FROM @TVPDocument Doc
				--	LEFT OUTER JOIN [Lookup].[MessageType] DocType ON DocType.MessageType = Doc.DocumentTypeXML collate SQL_Latin1_General_CP1_CI_AS
					WHERE [Recordnumber] = @i
					UPDATE [dbo].[t_test] 
							SET name1= 'Hi'
							WHERE Id = @DocMessId
					--SET @i +=1;
					SELECT  @i =  min( [Recordnumber]) FROM @TVPDocument Doc
				--	LEFT OUTER JOIN [Lookup].[MessageType] DocType ON DocType.MessageType = Doc.DocumentTypeXML collate SQL_Latin1_General_CP1_CI_AS
					Where [Recordnumber] > @i

				END
       
END