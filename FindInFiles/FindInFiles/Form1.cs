using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Security.Permissions;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows.Forms;

namespace FindInFiles
{
    public partial class frmFiF : Form
    {
        public frmFiF()
        {
            InitializeComponent();

            string regExLoad = @"C:\Users\cunnings\Documents\RegExList.txt";

            if (File.Exists(regExLoad))
            {
                // Load any combo values
                string[] regExList = File.ReadAllLines(regExLoad);

                foreach (var line in regExList)
                {
                    this.cmbRegEx.Items.Add(line);
                }

                this.cmbRegEx.SelectedIndex = 0;

                // Add a delegate to handle form closure

            }

            Application.ApplicationExit += new EventHandler(Application_ApplicationExit);

        }

        void Application_ApplicationExit(object sender, EventArgs e)
        {
            string regExSave = @"C:\Temp\RegExList.txt";

            List<string> cbList = this.cmbRegEx.Items
                                    .Cast<Object>()
                                    .Select(item => item.ToString())
                                    .ToList();

            if (File.Exists(regExSave))
            {
                File.Delete(regExSave);
                File.WriteAllLines(regExSave, cbList);
            }

        }

        private void btnDirSel_Click(object sender, EventArgs e)
        {
            using (var fbd = new FolderBrowserDialog())
            {

                fbd.SelectedPath = txtDirectoryPattern.Text;

                DialogResult result = fbd.ShowDialog();

                if (result == DialogResult.OK && !string.IsNullOrWhiteSpace(fbd.SelectedPath))
                {

                    txtDirectoryPattern.Text = fbd.SelectedPath;

                }
            }
        }

        public struct ProductCountSt
        {
            public string product;
            public int count;
        }

        private void dgvHits_RowPrePaint(object sender, DataGridViewRowPrePaintEventArgs e)
        {
            try
            {

                string prodTest = "";
                int byteVal = 0;
                Color col = Color.DeepSkyBlue;

                if (dgvHits.Rows[e.RowIndex].Cells[0].Value != null)
                {

                    prodTest = dgvHits.Rows[e.RowIndex].Cells["Product"].Value.ToString();

                    byte[] ascBytes = Encoding.ASCII.GetBytes(prodTest);

                    for (int i=0; i < ascBytes.Length; i++)
                    {
                        byteVal = byteVal + ascBytes[i];
                    }

                    if (byteVal < 0 && byteVal > 255)
                    {
                        byteVal = 200;
                    }

                    col = Color.FromArgb(255, 240, byteVal, 255);

                    if (byteVal >= 0 && byteVal <= 50)
                    {
                        col = Color.AliceBlue;
                    }
                    if (byteVal >= 51 && byteVal <= 100)
                    {
                        col = Color.Red;
                    }
                    if (byteVal >= 101 && byteVal <= 150)
                    {
                        col = Color.Yellow;
                    }
                    if (byteVal >= 151 && byteVal <= 200)
                    {
                        col = Color.Green;
                    }
                    if (byteVal >= 201 && byteVal <= 254)
                    {
                        col = Color.HotPink;
                    }

                    dgvHits.Rows[e.RowIndex].DefaultCellStyle.BackColor = col;

                }
            }
            catch(Exception ex)
            {
                string em = ex.Message;
            }
        }

        private void btnFind_Click(object sender, EventArgs e)
        {

            txtSearched.Clear();
            lblProgess.Text = "Searching...";
            lblProgess.Refresh();

            bool firstTime = true;

            int itemsFoundProduct = 0;
            int itemsFoundTotal = 0;

            string dirPattern = txtDirPattern.Text;

            //string[] allDirs = Directory.GetDirectories(txtDirectoryPattern.Text, dirPattern, SearchOption.AllDirectories);
            string[] allSubDirs;
            string fileName = string.Format("{0}.csv", string.Format("{0}{1}", "SearchResults_", DateTime.Now.ToString("yyyyMMddHHmmss")));
            //string filePattern = txtFilePattern.Text;
            string itemPath;
            string itemFilename;
            //string[] listForNow;
            string prod = string.Empty;
            string prodNew = string.Empty;
            string regEx = "";

            if (cmbRegEx.Text != null)
            {
                regEx = cmbRegEx.Text;
            }
            else
            {
                MessageBox.Show("Please select a reg ex to work with.");
                return;
            }

            DataTable dtHits = new DataTable("Hits");
            dtHits.Columns.Add("Product");
            dtHits.Columns.Add("File");
            dtHits.Columns.Add("Offset");
            dtHits.Columns.Add("Text");

            DataView dvHits = new DataView(dtHits);
            dgvHits.DataSource = dvHits;

            dgvHits.Columns["Product"].AutoSizeMode = DataGridViewAutoSizeColumnMode.DisplayedCells;
            dgvHits.Columns["File"].AutoSizeMode = DataGridViewAutoSizeColumnMode.DisplayedCells;
            dgvHits.Columns["Offset"].AutoSizeMode = DataGridViewAutoSizeColumnMode.DisplayedCells;
            dgvHits.Columns["Text"].AutoSizeMode = DataGridViewAutoSizeColumnMode.DisplayedCells;

            dgvHits.ReadOnly = true;
            dgvResults.ReadOnly = true;

            var prodCountListSt = new List<ProductCountSt>();

            // =================================================================================================================
            // Get the header list of directores - this will allow us to filter out any undesirable folders, such as Git folders
            // =================================================================================================================

            List<string> headerDirList = new List<string>();
            List<string> cleanHeaderDirList = new List<string>();

            int index = 0;

            headerDirList = Directory.GetDirectories(string.Format("{0}\\{1}", txtDirectoryPattern.Text, txtDirPattern.Text), "*", SearchOption.TopDirectoryOnly).ToList();

            foreach (string dir in headerDirList)
            {
                DirectoryInfo di = new DirectoryInfo(dir);

                if ((di.Attributes & FileAttributes.Hidden) != 0)
                {
                    index++;
                    continue;
                }
                else
                {
                    cleanHeaderDirList.Add(headerDirList.ElementAt(index));
                }

                index++;

            }

            string[] dirElements;

            foreach (string dir in cleanHeaderDirList)
            {

                // Look in all subs

                allSubDirs = Directory.GetDirectories(dir, "*", SearchOption.AllDirectories);

                dirElements = dir.Split('\\');
                prod = dirElements[6]; // Hard coded for expedience, could change, needs more flex

                if (prodNew != prod)
                {
                    prodNew = prod;
                }

                // Get all files for the specified mask - we may be able to just traverse that
                List<string> allFilesInTheSub = new List<string>();

                allFilesInTheSub = Directory.GetFiles(dir, txtFilePattern.Text, SearchOption.AllDirectories).ToList();

                foreach (string file in allFilesInTheSub)
                {

                    txtSearched.AppendText(string.Format("{0}{1}", file, ""));
                    txtSearched.AppendText(Environment.NewLine);

                    // Look for the search term in the file

                    Regex re = new Regex(regEx);

                    string wholeFile = File.ReadAllText(file);

                    Match m = re.Match(wholeFile);

                    if (m.Success)
                    {

                        // Write to log if required
                        if (chkWrite.Checked)
                        {
                            using (StreamWriter swLog = File.AppendText(string.Format(@"{0}\{1}", txtWriteTo.Text, fileName)))
                            {
                                if (firstTime)
                                {
                                    swLog.WriteLine(@"Full,Path,Filename,Product,Count");
                                    firstTime = false;
                                }

                                itemPath = Path.GetDirectoryName(file);
                                itemFilename = Path.GetFileName(file);

                                swLog.WriteLine(string.Format("{0},{1},{2},{3},{4}", file, itemPath, itemFilename, prod, Regex.Matches(wholeFile, regEx).Count));
                            }
                        }

                        var hitRow = dtHits.NewRow();

                        hitRow["Product"] = string.Format("{0}", prod);
                        hitRow["File"] = string.Format("{0}", file);
                        hitRow["Offset"] = string.Format("{0}", m.Index);
                        hitRow["Text"] = string.Format("Found '{0}' at position {1}", m.Value, m.Index);

                        dtHits.Rows.Add(hitRow);

                        dgvHits.Refresh();

                        itemsFoundProduct = itemsFoundProduct + Regex.Matches(wholeFile, regEx).Count;
                        itemsFoundTotal = itemsFoundTotal + itemsFoundProduct;

                        lblCTECount.Text = itemsFoundProduct.ToString();
                        lblCTECount.Refresh();
                        lblItemCountTotal.Text = itemsFoundTotal.ToString();
                        lblItemCountTotal.Refresh();
                    }

                }

                prodCountListSt.Add(new ProductCountSt
                {
                    product = prod,
                    count = itemsFoundProduct
                }
                    );

                itemsFoundTotal += itemsFoundProduct;
                itemsFoundProduct = 0;
            }

            // Reassign the last item count in case this was a single-pass only
            // and the switch of product assignment was not hit.
            // A list count of zero should indicate this - all sorts of checks can be added though

            if (prodCountListSt.Count == 0)
            {
                prodCountListSt.Add(new ProductCountSt
                {
                    product = prod,
                    count = itemsFoundProduct
                }
                    );
            }

            // Create the data table
            DataTable dtRes = new DataTable("Results");

            // Add two columns
            dtRes.Columns.Add("Product");
            dtRes.Columns.Add("Count");

            // Add each list row to the data table

            foreach (var item in prodCountListSt)
            {
                var row = dtRes.NewRow();

                row["Product"] = item.product;
                row["Count"] = item.count;

                dtRes.Rows.Add(row);
            }

            // Create a new data view to act as the bridge between the data table and the 
            // data grid view
            DataView dvBridge = new DataView(dtRes);

            // Set the data grid view data source
            dgvResults.DataSource = dvBridge;

            dgvResults.Columns["Product"].AutoSizeMode = DataGridViewAutoSizeColumnMode.DisplayedCells;
            dgvResults.Columns["Count"].AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;

            lblProgess.Text = "Ready";
            lblProgess.Refresh();
        }

        private void DgvHits_RowPrePaint(object sender, DataGridViewRowPrePaintEventArgs e)
        {
            throw new NotImplementedException();
        }

        private void btnClear_Click(object sender, EventArgs e)
        {

            txtSearched.Clear();

            dgvResults.DataSource = null;
            dgvResults.Rows.Clear();
            dgvResults.Refresh();

            dgvHits.DataSource = null;
            dgvHits.Rows.Clear();
            dgvResults.Refresh();

        }

        private void btnWriteTo_Click(object sender, EventArgs e)
        {
            using (var fbd = new FolderBrowserDialog())
            {

                fbd.SelectedPath = txtWriteTo.Text;

                DialogResult result = fbd.ShowDialog();

                if (result == DialogResult.OK && !string.IsNullOrWhiteSpace(fbd.SelectedPath))
                {

                    txtWriteTo.Text = fbd.SelectedPath;

                }
            }
        }

        private void dgvHits_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
        {

            string fileToOpen = string.Empty;

            try
            {

                fileToOpen = dgvHits.Rows[e.RowIndex].Cells[1].Value.ToString();

                using (Process np = new Process())
                {
                    np.StartInfo.FileName = "C:\\Program Files\\Notepad++\\notepad++.exe";
                    np.StartInfo.Arguments = "\"" + fileToOpen + "\"";
                    np.Start();
                }
            }
            catch
            {

            }
        }

        private void dgvResults_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            string filter = "";

            try
            {

                filter = dgvResults.Rows[e.RowIndex].Cells[0].Value.ToString();

                if (filter != "")
                {
                    (dgvHits.DataSource as DataView).RowFilter = string.Format("Product = '{0}'", filter);
                }
                else
                {
                    (dgvHits.DataSource as DataView).RowFilter = null;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }
    }
}
