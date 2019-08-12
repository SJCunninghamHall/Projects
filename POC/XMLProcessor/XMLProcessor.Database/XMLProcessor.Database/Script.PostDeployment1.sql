/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

:r .\ReferenceData\Lookup.Currency.sql			
:r .\ReferenceData\Lookup.ItemType.sql	
:r .\ReferenceData\Lookup.MessageType.sql	
GO
--CREATE ASSEMBLY [XMLProcessor.SQLFunc]  
--FROM 'C:\Projects\XMLProcessor\XMLProcessor.SQLFunc\bin\dEBUG\XMLProcessor.SQLFunc.dll'
--WITH PERMISSION_SET = SAFE
--GO

--CREATE FUNCTION [dbo].[CLR_XML_06MA01Message](@Input [nvarchar](max))
--RETURNS [nvarchar](max) WITH EXECUTE AS CALLER
--AS 
--EXTERNAL NAME [XMLProcessor.SQLFunc].[XMLProcessor.SQLFunc.Functions].[CLR_XML_06MA01Message]
--GO