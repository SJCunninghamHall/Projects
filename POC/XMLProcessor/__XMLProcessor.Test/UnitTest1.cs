using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

 
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Xml.Linq;
using System.Diagnostics;

namespace XMLProcessor.Test
{
    [TestClass]
    public class UnitTest1
    {
        [TestMethod]
        public void TestMethod1()
        {
            String file = @"C:\Projects\XMLProcessor\Files\06MA01_20190205_014404_466349.xml";

            //XElement docElement = XElement.Load(file);

            //DataSet ds = new DataSet();
            // xsd.exe and schema to look at
            // 
            //ds.ReadXml(new StringReader(docElement.ToString()));

        }
    }
}
