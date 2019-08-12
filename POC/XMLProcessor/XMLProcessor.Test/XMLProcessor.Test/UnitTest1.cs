using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.IO;

namespace XMLProcessor.Test
{
    [TestClass]
    public class UnitTest1
    {
        [TestMethod]
        public void Test_CLR_XML_06MA01Message()
        {
            String Fullname = @"C:\Projects\XMLProcessor\Files\06MA01_20190205_014404_466349.xml";

            using (StreamReader reader = new StreamReader(Fullname))
            {
                string XmlContent = reader.ReadToEnd();
                XMLProcessor.SQLFunc.Functions.CLR_XML_06MA01Message(XmlContent);
            }
        }
    }
}