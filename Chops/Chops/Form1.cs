using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text.RegularExpressions;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Chops
{
    public partial class frmCUT : Form
    {
        public frmCUT()
        {
            InitializeComponent();
            this.nudMaxConsec.Minimum = 1;
            if (this.txtSource.Text.Split(null).Count() > 2)
            {
                this.nudMaxConsec.Maximum = this.txtSource.Text.Split(null).Count() / 2;
                this.nudMaxConsec.Value = 3;
            }
            else
            {
                this.nudMaxConsec.Maximum = 1;
                this.nudMaxConsec.Value = 1;
            }
            this.nudMaxConsec.Refresh();
        }

        private void btnChop_Click(object sender, EventArgs e)
        {
            string toBeChopped = txtSource.Text;

            if (toBeChopped.Trim() == string.Empty)
            {
                MessageBox.Show("Enter text to be chopped");
                return;
            }

            // List<string> breakDown = toBeChopped.Split(' ').ToList();
            // List<string> breakDown = toBeChopped.Split(new string[] { "\r", "\n", "\r\n", " " }, StringSplitOptions.RemoveEmptyEntries).ToList();
            //List<string> breakDown = toBeChopped.Split(new string[] { "\r", "\n", "\r\n", " ", "\t" }, StringSplitOptions.None).ToList();
            List<string> breakDown = toBeChopped.Split(new char[0], StringSplitOptions.RemoveEmptyEntries).ToList();

            //List<string> rt = Regex.Split(toBeChopped, "\r", "\n", "\r\n");

            int numberOfWords = breakDown.Count();

            breakDown.CutUp(nudMaxConsec.Value);

            // breakDown.Shuffle();

            txtChoppeds.Clear();

            txtChoppeds.AppendText(string.Join(" ", breakDown.GetRange(0, numberOfWords)));

            return;
        }


        private void txtSource_LostFocus(object sender, EventArgs e)
        {
            if (txtSource.Text.Split(null).Count() > 2)
            {
                nudMaxConsec.Maximum = this.txtSource.Text.Split(null).Count() / 2;
                if (txtSource.Text.Split(null).Count() / 2 >= 3)
                {
                    nudMaxConsec.Value = 3;
                }
                else
                {
                    nudMaxConsec.Value = 1;
                }
            }
            else
            {
                nudMaxConsec.Maximum = 1;
                nudMaxConsec.Value = 1;
            }
        }

    }

    public static class ThreadSafeRandom
    {
        [ThreadStatic]
        private static Random Local;

        public static Random ThisThreadsRandom
        {
            get { return Local ?? (Local = new Random(unchecked(Environment.TickCount * 31 + Thread.CurrentThread.ManagedThreadId))); }
        }
    }

}
