﻿CREATE FUNCTION [dbo].[CLR_XML_06MA01Message]
(@Input NVARCHAR (MAX) NULL)
RETURNS NVARCHAR (MAX)
AS
 EXTERNAL NAME [XMLProcessor.SQLFunc].[XMLProcessor.SQLFunc.Functions].[CLR_XML_06MA01Message]
