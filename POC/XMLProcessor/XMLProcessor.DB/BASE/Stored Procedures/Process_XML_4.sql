/*
		
	Initial Test Data: 06MA01_20190205_014404_466349
     
	 Scenario        Stored Procedure              TVP In Memory     In Memnory Table        Possible        SP Name(s)
                               
        1            Not Compiled   (Single)         Yes                  Yes*              ??              Process_XML_1
                
        2            Header Not Compiled             Yes                  Yes*              ??              Process_XML_2
                     Child Compiled   

        3            Header Compiled                 Yes                  Yes*              ??              Process_XML_3
          
        4            Header Compiled                 Yes                  Yes*              ??              Process_XML_4
                     Child Compiled 

*/
CREATE PROCEDURE BASE.Process_XML_4
	@tv_StgCore			tv_StgCore READONLY
AS
BEGIN
	SELECT 1
END