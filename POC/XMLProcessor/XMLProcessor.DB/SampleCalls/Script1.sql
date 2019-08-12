USE [ XMLProcessor]
GO



drop function [dbo].[ProcessMessage];
go

DROP ASSEMBLY [XMLProcessor.SQLFunc]
GO

--Build the c# code

CREATE ASSEMBLY [XMLProcessor.SQLFunc]  
FROM 'C:\Projects\XMLProcessor\XMLProcessor.SQLFunc\bin\Release\XMLProcessor.SQLFunc.dll'
WITH PERMISSION_SET = SAFE
GO


CREATE FUNCTION [dbo].[ProcessMessage](@Input [nvarchar](max))
RETURNS [nvarchar](max) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [XMLProcessor.SQLFunc].[XMLProcessor.SQLFunc.Functions].[ProcessMessage]
GO


DECLARE @Input nvarchar(max);
SET @Input = '<XMLMessage>fred</XMLMessage>'
SELECT [dbo].[ProcessMessage] (@Input)
GO





/*
CREATE FUNCTION [dbo].[CLRProcess_XML_1](@Input [nvarchar](max))
RETURNS [nvarchar](max) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [XMLProcessor.SQLFunc].[XMLProcessor.SQLFunc.Functions].[CLRProcess_XML_1]
GO


CREATE FUNCTION [dbo].[CLRProcess_XML_2](@Input [nvarchar](max))
RETURNS [nvarchar](max) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [XMLProcessor.SQLFunc].[XMLProcessor.SQLFunc.Functions].[CLRProcess_XML_2]
GO


CREATE FUNCTION [dbo].[CLRProcess_XML_3](@Input [nvarchar](max))
RETURNS [nvarchar](max) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [XMLProcessor.SQLFunc].[XMLProcessor.SQLFunc.Functions].[CLRProcess_XML_3]
GO

CREATE FUNCTION [dbo].[CLRProcess_XML_4](@Input [nvarchar](max))
RETURNS [nvarchar](max) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [XMLProcessor.SQLFunc].[XMLProcessor.SQLFunc.Functions].[CLRProcess_XML_4]
GO
*/