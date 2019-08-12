USE [XMLProcessor]
GO


--To Remove Assembly
--1. Drop Function
DROP function [dbo].[CLR_XML_06MA01Message];
GO
 
--2. Drop Assembly
DROP ASSEMBLY [XMLProcessor.SQLFunc]
GO

--To Add The Assembly
--After building the c# code, in debug or release... Change path!
--1. Create the assembly
CREATE ASSEMBLY [XMLProcessor.SQLFunc]  
FROM 'C:\Projects\XMLProcessor\XMLProcessor.SQLFunc\bin\Debug\XMLProcessor.SQLFunc.dll'
WITH PERMISSION_SET = SAFE
GO

--2. Create the function
--CREATE FUNCTION [dbo].[CLR_XML_06MA01Message](@Input [nvarchar](max))
--RETURNS [nvarchar](max) WITH EXECUTE AS CALLER
--AS 
--EXTERNAL NAME [XMLProcessor.SQLFunc].[XMLProcessor.SQLFunc.Functions].[CLR_XML_06MA01Message]
--GO

CREATE FUNCTION [dbo].[CLR_XML_06MA01Message](@Input [nvarchar](max))
RETURNS [nvarchar](max) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [XMLProcessor.SQLFunc].[XMLProcessor.SQLFunc.Functions].[CLR_XML_06MA01Message]
GO