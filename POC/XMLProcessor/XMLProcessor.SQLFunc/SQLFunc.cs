using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;

namespace XMLProcessor.SQLFunc
{
    public static class Functions
    {
        #region Private Fields


        #endregion Private Fields

        #region Public Methods
        //private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        [Microsoft.SqlServer.Server.SqlProcedure]
        public static String CLR_XML_06MA01Message(string XmlContent)
        {

            String result = "";

            SqlConnection conn = null;
            SqlDataReader rdr = null;

            try
            {
               //log.Info("CLR_XML_06MA01Message Started");
                var ds = new DataSet();

                //FileStream fsSchema = new FileStream(@"C:\Projects\XMLProcessor\XMLSchemaCollections\06MA01.xsd", FileMode.Open,FileAccess.Read, FileShare.ReadWrite);
                //ds.ReadXmlSchema(fsSchema);
                //ds.ReadXml(new StringReader(XmlContent), XmlReadMode.IgnoreSchema);
                ds.ReadXml(new StringReader(XmlContent));

                if (ds != null)
                {
                    foreach (DataTable table in ds.Tables)
                    {

                        System.Diagnostics.Debug.WriteLine("-----------------------------------------------------------");
                        System.Diagnostics.Debug.WriteLine(String.Concat("Table:", table.TableName.ToString()));
                        System.Diagnostics.Debug.WriteLine("-----------------------------------------------------------");
                        foreach (DataColumn col in table.Columns)
                        {
                            System.Diagnostics.Debug.WriteLine("Ordinal:{0} Column Name:{1} DataType:{2} MaxLength:{3}",
                                                                col.Ordinal.ToString(),
                                                                col.ColumnName.ToString(),
                                                                col.DataType.ToString(),
                                                                col.MaxLength.ToString());
                        }
                        System.Diagnostics.Debug.WriteLine("-----------------------------------------------------------");
                    }
                    System.Diagnostics.Debug.WriteLine(String.Concat("Table [GrpHdr] RowCount:", ds.Tables["GrpHdr"].Rows.Count.ToString()));
                    System.Diagnostics.Debug.WriteLine(String.Concat("Table [Core] RowCount:", ds.Tables["Core"].Rows.Count.ToString()));
                    System.Diagnostics.Debug.WriteLine(String.Concat("Table [TxSet] RowCount:", ds.Tables["TxSet"].Rows.Count.ToString()));
                    System.Diagnostics.Debug.WriteLine(String.Concat("Table [DbtItm] RowCount:", ds.Tables["DbtItm"].Rows.Count.ToString()));
                    System.Diagnostics.Debug.WriteLine(String.Concat("Table [ItmImgData] RowCount:", ds.Tables["ItmImgData"].Rows.Count.ToString()));
                    System.Diagnostics.Debug.WriteLine(String.Concat("Table [CrdtItm] RowCount:", ds.Tables["CrdtItm"].Rows.Count.ToString()));
                    System.Diagnostics.Debug.WriteLine(String.Concat("Table [CdtItmFrdData] RowCount:", ds.Tables["CdtItmFrdData"].Rows.Count.ToString()));
                    System.Diagnostics.Debug.WriteLine(String.Concat("Table [DfltdItm] RowCount:", ds.Tables["DfltdItm"].Rows.Count.ToString()));
                    System.Diagnostics.Debug.WriteLine(String.Concat("Table [RprdItm] RowCount:", ds.Tables["RprdItm"].Rows.Count.ToString()));
                    System.Diagnostics.Debug.WriteLine(String.Concat("Table [Amt] RowCount:", ds.Tables["Amt"].Rows.Count.ToString()));
                    System.Diagnostics.Debug.WriteLine(String.Concat("Table [Entities] RowCount:", ds.Tables["Entities"].Rows.Count.ToString()));
                    System.Diagnostics.Debug.WriteLine(String.Concat("Table [Entity] RowCount:", ds.Tables["Entity"].Rows.Count.ToString()));

                    //System.Diagnostics.Debug.WriteLine(String.Concat("Table [SwtchdItm] RowCount:", ds.Tables["SwtchdItm"].Rows.Count.ToString()));

                }

             
                // create and open a connection object
                conn = new SqlConnection("Server=(local);DataBase=XMLProcessor;Integrated Security=SSPI");
                conn.Open();

                // 1.  create a command object identifying the stored procedure
                SqlCommand cmd = new SqlCommand("[Base].[XML_06MA01Message_v2]", conn);

                // 2. set the command object so it knows to execute a stored procedure
                cmd.CommandType = CommandType.StoredProcedure;


                //    SqlParameter P0 = new SqlParameter("@tv_Document_XML", "tv_Document_XML"); P0.SqlDbType = System.Data.SqlDbType.Structured; P0.Value = ds.Tables[0]; //cmd.Parameters.Add(P0);
                //    SqlParameter P1 = new SqlParameter("@tv_ReqToPay_XML", "tv_ReqToPay_XML"); P1.SqlDbType = System.Data.SqlDbType.Structured; P1.Value = ds.Tables[1]; //cmd.Parameters.Add(P1);
                SqlParameter pGrpHdr = new SqlParameter("@tv_GrpHdr_XML", "tv_GrpHdr_XML"); pGrpHdr.SqlDbType = System.Data.SqlDbType.Structured; pGrpHdr.Value = ds.Tables["GrpHdr"]; cmd.Parameters.Add(pGrpHdr);
                SqlParameter pCore = new SqlParameter("@tv_Core_XML", "tv_Core_XML_XML"); pCore.SqlDbType = System.Data.SqlDbType.Structured; pCore.Value = ds.Tables["Core"]; cmd.Parameters.Add(pCore);
                SqlParameter pTxSet = new SqlParameter("@tv_TxSet_XML", "tv_TxSet_XML"); pTxSet.SqlDbType = System.Data.SqlDbType.Structured; pTxSet.Value = ds.Tables["TxSet"]; cmd.Parameters.Add(pTxSet);
                SqlParameter pDbtItm = new SqlParameter("@tv_DbtItm_XML", "tv_DbtItm_XML"); pDbtItm.SqlDbType = System.Data.SqlDbType.Structured; pDbtItm.Value = ds.Tables["DbtItm"]; cmd.Parameters.Add(pDbtItm);
                SqlParameter pItmImgData = new SqlParameter("@tv_ItmImgData_XML", "tv_ItmImgData_XML"); pItmImgData.SqlDbType = System.Data.SqlDbType.Structured; pItmImgData.Value = ds.Tables["ItmImgData"]; cmd.Parameters.Add(pItmImgData);
                SqlParameter pCrdtItm = new SqlParameter("@tv_CrdItm_XML", "tv_CrdItm_XML"); pCrdtItm.SqlDbType = System.Data.SqlDbType.Structured; pCrdtItm.Value = ds.Tables["CrdtItm"]; cmd.Parameters.Add(pCrdtItm);
                SqlParameter pCdtItmFrdData = new SqlParameter("@tv_CdtItmFrdDate_XML", "tv_CdtItmFrdDate_XML"); pCdtItmFrdData.SqlDbType = System.Data.SqlDbType.Structured; pCdtItmFrdData.Value = ds.Tables["CdtItmFrdData"]; cmd.Parameters.Add(pCdtItmFrdData);

                //SqlParameter P9 = new SqlParameter("@tv_DfltdItm_XML", "tv_DfltdItm_XML"); P9.SqlDbType = System.Data.SqlDbType.Structured; P9.Value = ds.Tables["DfltdItm"]; cmd.Parameters.Add(P9);
                SqlParameter pRprdItm = new SqlParameter("@tv_RprdItm_XML", "tv_RprdItm_XML"); pRprdItm.SqlDbType = System.Data.SqlDbType.Structured; pRprdItm.Value = ds.Tables["RprdItm"]; cmd.Parameters.Add(pRprdItm);

                // There is no such item as tv_SwtchdItm_XML!!! in the xml sample
                //SqlParameter P11 = new SqlParameter("@tv_SwtchdItm_XML", "tv_SwtchdItm_XML"); P11.SqlDbType = System.Data.SqlDbType.Structured; P11.Value = ds.Tables["SwtchdItm"]; cmd.Parameters.Add(P11);
                SqlParameter pAmt = new SqlParameter("@tv_Amt_XML", "tv_Amt_XML"); pAmt.SqlDbType = System.Data.SqlDbType.Structured; pAmt.Value = ds.Tables["Amt"]; cmd.Parameters.Add(pAmt);

                SqlParameter pEntities = new SqlParameter("@tv_Entities_XML", "tv_Entities_XML"); pEntities.SqlDbType = System.Data.SqlDbType.Structured; pEntities.Value = ds.Tables["Entities"]; cmd.Parameters.Add(pEntities);
                SqlParameter pEntity = new SqlParameter("@tv_Entity_XML", "tv_Entity_XML"); pEntity.SqlDbType = System.Data.SqlDbType.Structured; pEntity.Value = ds.Tables["Entity"]; cmd.Parameters.Add(pEntity);

                //DbtItmFrdData, HghstAmt, DbtDplctItm, DbtStopdItm
                //SqlParameter pDbtItmFrdData = new SqlParameter("@tv_DfltdItm_XML", "tv_DfltdItm_XML"); pDbtItmFrdData.SqlDbType = System.Data.SqlDbType.Structured; pDbtItmFrdData.Value = ds.Tables["DbtItmFrdData"]; cmd.Parameters.Add(pDbtItmFrdData);
                //SqlParameter P13 = new SqlParameter("@tv_HghstAmt_XML", "tv_HghstAmt_XML"); P13.SqlDbType = System.Data.SqlDbType.Structured; P13.Value = ds.Tables[13]; //cmd.Parameters.Add(P13);
                //SqlParameter P14 = new SqlParameter("@tv_DbtDplctItm_XML", "tv_DbtDplctItm_XML"); P14.SqlDbType = System.Data.SqlDbType.Structured; P14.Value = ds.Tables[14]; //cmd.Parameters.Add(P14);
                //SqlParameter P15 = new SqlParameter("@tv_DbtStopdItm_XML", "tv_DbtStopdItm_XML"); P15.SqlDbType = System.Data.SqlDbType.Structured; P15.Value = ds.Tables[15]; //cmd.Parameters.Add(P15);


                //SqlParameter P5 = new SqlParameter("@tv_Amt_XML", "tv_Amt_XML"); P5.SqlDbType = System.Data.SqlDbType.Structured; P5.Value = ds.Tables[5]; //cmd.Parameters.Add(P5);
                //SqlParameter P8 = new SqlParameter("@tv_DfltdItm_XML", "tv_DfltdItm_XML"); P8.SqlDbType = System.Data.SqlDbType.Structured; P8.Value = ds.Tables[8]; //cmd.Parameters.Add(P8);
                //SqlParameter P9 = new SqlParameter("@tv_SwtchdItm_XML", "tv_SwtchdItm_XML"); P9.SqlDbType = System.Data.SqlDbType.Structured; P9.Value = ds.Tables[9]; //cmd.Parameters.Add(P9);
                //SqlParameter P10 = new SqlParameter("@tv_DbtItm_XML", "tv_DbtItm_XML"); P10.SqlDbType = System.Data.SqlDbType.Structured; P10.Value = ds.Tables[10]; //cmd.Parameters.Add(P10);
                //SqlParameter P11 = new SqlParameter("@tv_ItmImgData_XML", "tv_ItmImgData_XML"); P11.SqlDbType = System.Data.SqlDbType.Structured; P11.Value = ds.Tables[11]; //cmd.Parameters.Add(P11);
                //SqlParameter P12 = new SqlParameter("@tv_DbtItmFrdData_XML", "tv_DbtItmFrdData_XML"); P12.SqlDbType = System.Data.SqlDbType.Structured; P12.Value = ds.Tables[12]; //cmd.Parameters.Add(P12);
                //SqlParameter P13 = new SqlParameter("@tv_HghstAmt_XML", "tv_HghstAmt_XML"); P13.SqlDbType = System.Data.SqlDbType.Structured; P13.Value = ds.Tables[13]; //cmd.Parameters.Add(P13);
                //SqlParameter P14 = new SqlParameter("@tv_DbtDplctItm_XML", "tv_DbtDplctItm_XML"); P14.SqlDbType = System.Data.SqlDbType.Structured; P14.Value = ds.Tables[14]; //cmd.Parameters.Add(P14);
                //SqlParameter P15 = new SqlParameter("@tv_DbtStopdItm_XML", "tv_DbtStopdItm_XML"); P15.SqlDbType = System.Data.SqlDbType.Structured; P15.Value = ds.Tables[15]; //cmd.Parameters.Add(P15);
                //SqlParameter P16 = new SqlParameter("@tv_ICN_XML", "tv_ICN_XML"); P16.SqlDbType = System.Data.SqlDbType.Structured; P16.Value = ds.Tables[16]; //cmd.Parameters.Add(P16);

                //Execute the Query
                cmd.ExecuteNonQuery();

                //log.Info("CLR_XML_06MA01Message Completed");

            }
            catch (Exception err)
            {
                //log.Info(String.Concat("CLR_XML_06MA01Message Error:",err.ToString()));
                result = err.ToString();
            }
            finally
            {
                result = "Finished";
                if (conn != null)
                {
                    conn.Close();
                }
                if (rdr != null)
                {
                    rdr.Close();
                }
            }
            return result;
        }
     
        #endregion Public Method
    }
}