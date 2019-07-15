using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Data.SqlClient;
using System.Text;
using System.Threading.Tasks;

namespace BulkCopy
{

    class Program
    {

        public static void DisplayMessage(string messageToDisplay)
        {
            string sqlFormattedDate = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");
            Console.WriteLine("{0}: {1}", sqlFormattedDate, messageToDisplay);
        }


        static void Main(string[] args)
        {

            DisplayMessage("Getting connection string...");
            string connString = GetConnectionString("SOURCE");

            //var dt = new DataTable();

            //dt.Columns.Add("ColdRoomTemperatureID");
            //dt.Columns.Add("ColdRoomSensorNumber");
            //dt.Columns.Add("RecordedWhen");
            //dt.Columns.Add("Temperature");
            //dt.Columns.Add("ValidFrom");
            //dt.Columns.Add("ValidTo");

            using (SqlConnection sqlSourceConn = new SqlConnection(connString))
            {

                DisplayMessage("Opening connection...");
                sqlSourceConn.Open();

                //SqlCommand sqlSourceCount = new SqlCommand("SELECT COUNT(*) FROM [Warehouse].[ColdRoomTemperatures_Archive]", sqlSourceConn);
                //long countStart = System.Convert.ToInt32(sqlSourceCount.ExecuteScalar());
                //Console.WriteLine("Initial count is {0}", countStart);

                SqlCommand sqlSourceData = new SqlCommand("SELECT " +
                                                                "[ColdRoomTemperatureID]" + 
                                                                ",[ColdRoomSensorNumber]" +
                                                                ",[RecordedWhen]" + 
                                                                ",[Temperature]" + 
                                                                ",[ValidFrom]" + 
                                                                ",[ValidTo] " + 
                                                                "FROM [Warehouse].[ColdRoomTemperatures_Archive]", sqlSourceConn);

                DisplayMessage("Executing reader");

                SqlDataReader sqlReader = sqlSourceData.ExecuteReader();

                DisplayMessage("Reader executed");

                //DisplayMessage("Loading data table");
                //dt.Load(sqlReader);
                //DisplayMessage("Data table loaded");

                using (SqlConnection sqlDestConn = new SqlConnection(connString))
                {
                    sqlDestConn.Open();

                    SqlCommand sqlClearDestTable = new SqlCommand("TRUNCATE TABLE [dbo].[CRT_BC_Demo]", sqlDestConn);

                    DisplayMessage("Clearing source table");

                    sqlClearDestTable.ExecuteNonQuery();

                    DisplayMessage("Source table cleared");

                    using (SqlBulkCopy bulkCopy = new SqlBulkCopy(sqlDestConn))
                    {
                        bulkCopy.DestinationTableName = "dbo.CRT_BC_Demo";
                        bulkCopy.BatchSize = 200000;
                        bulkCopy.NotifyAfter = 500000;
                        // bulkCopy.SqlRowsCopied += (sender, eventArgs) => Console.WriteLine("Transferred " + eventArgs.RowsCopied + " records.");
                        bulkCopy.SqlRowsCopied += (sender, eventArgs) => DisplayMessage("Transferred " + eventArgs.RowsCopied + " records.");

                        // bulkCopy.BulkCopyTimeout = 60;

                        DisplayMessage("Bulk copy started");

                        // bulkCopy.WriteToServer(dt);
                        bulkCopy.WriteToServer(sqlReader);

                        DisplayMessage("Bulk copy finished");
                    }

                }

                sqlReader.Close();

            }

            Console.WriteLine("Press any key...");
            Console.ReadLine();

        }

        private static void BulkCopy_SqlRowsCopied(object sender, SqlRowsCopiedEventArgs e)
        {
            throw new NotImplementedException();
        }

        private static string GetConnectionString(string location)
        {

            string retCon;

            switch (location.ToUpper())
            {
                case "SOURCE":
                    retCon = ConfigurationManager.AppSettings["ConnectionSource"];
                    break;
                case "DESTINATION":
                    retCon = ConfigurationManager.AppSettings["ConnectionDestination"];
                    break;
                default:
                    retCon = ConfigurationManager.AppSettings["ConnectionSource"];
                    break;
            }

            return retCon;
        }
    }
}
