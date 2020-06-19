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

    static class MyExtensions
    {

        public static void CutUp<T>(this IList<T> list, decimal maxChunkIn)
        {
            // Create a master list consisting of one or more lists of sections of the original text

            // Create storage for temp work lists and collection of those lists
            List<List<T>> listOfSnippets = new List<List<T>>();
            List<T> snippetList = new List<T>();
            
            // Work out the maximum number of words to keep together in the event of that decision being reached

            int n = list.Count;
            int fullN = n;
            int maxChunk;
            int chunkProgress = 0;

            maxChunk = (Decimal.ToInt32(maxChunkIn)) + 1; // Increase by one as upper value is exclusive not inclusive

            foreach (var word in list)
            {
                // Determine how many words to add to the current list

                // Skip this many words
                if (chunkProgress == 0) // Just finished a cycle or one didn't exist in the first place
                {
                    chunkProgress = ThreadSafeRandom.ThisThreadsRandom.Next(1, maxChunk);
                }

                snippetList.Add(word);

                if (chunkProgress > 0)
                {
                    chunkProgress--;
                }
                
                // Check if we're done with this chunk of words
                if (chunkProgress == 0)
                {
                    listOfSnippets.Add(new List<T>(snippetList));
                    snippetList.Clear();
                }
            }

            // It's possible we have reached the last word in the list and dropped out of the loop
            // before adding the final scratch list to the master list. Check and add

            if (snippetList.Count != 0)
            {
                listOfSnippets.Add(new List<T>(snippetList));
                snippetList.Clear();
            }

            // Shuffle the master list

            int mln = listOfSnippets.Count;
            // int fullN = n;

            // Work the master list from start to finish
            while (mln > 1)
            {
                mln--;

                int k = ThreadSafeRandom.ThisThreadsRandom.Next(mln + 1);

                List<T> value = listOfSnippets[k];
                listOfSnippets[k] = listOfSnippets[mln];
                listOfSnippets[mln] = value;

                //mln--;
            }

            // Reconstruct into a form the same as that passed in so the the transition is seamless

            List<T> reconList = new List<T>();

            foreach (var outer in listOfSnippets)
            {
                reconList.AddRange(outer);
            }

            list.Clear();
            reconList.ForEach(lb => { list.Add(lb); } );

        }
        public static void Shuffle<T>(this IList<T> list)
        {
            int n = list.Count;
            int fullN = n;

            // Work the master list from start to finish
            while (n > 1)
            {
                // n--;

                    int k = ThreadSafeRandom.ThisThreadsRandom.Next(n + 1);

                    T value = list[k];
                    list[k] = list[n];
                    list[n] = value;

                    n--;
            }
        }
    }

}
