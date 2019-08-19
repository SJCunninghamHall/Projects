using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
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
        }

        private void btnChop_Click(object sender, EventArgs e)
        {
            string toBeChopped = txtOrig.Text;

            if (toBeChopped.Trim() == string.Empty)
            {
                MessageBox.Show("Enter text to be chopped");
                return;
            }

            List<string> breakDown = toBeChopped.Split(' ').ToList();

            int numberOfWords = breakDown.Count();

            breakDown.CutUp();

            // breakDown.Shuffle();

            txtChopped.Clear();

            txtChopped.AppendText(string.Join(" ", breakDown.GetRange(0, numberOfWords)));

            return;
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

        public static void CutUp<T>(this IList<T> list)
        {
            // Create a master list consisting of one or more lists of sections of the original text

            // Create storage for temp work lists and collection of those lists
            List<List<T>> listOfLists = new List<List<T>>();
            List<T> scratchList = new List<T>();
            
            // Work out the maximum number of words to keep together in the event of that decision being reached

            int n = list.Count;
            int scanCounter = 0;
            int fullN = n;
            int maxChunk;
            int chunkProgress = 0;

            if (fullN >= 2)
            {
                maxChunk = fullN / 2;
            }
            else
            {
                maxChunk = 1;
            }

            foreach (var word in list)
            {
                // Determine how many words to add to the current list

                // Skip this many words
                if (chunkProgress == 0) // Just finished a cycle or one didn't exist in the first place
                {
                    chunkProgress = ThreadSafeRandom.ThisThreadsRandom.Next(1, maxChunk);
                }

                scratchList.Add(word);

                if (chunkProgress > 0)
                {
                    chunkProgress--;
                }
                
                // Check if we're done with this chunk of words
                if (chunkProgress == 0)
                {
                    listOfLists.Add(new List<T>(scratchList));
                    scratchList.Clear();
                }
            }

            // It's possible we have reached the last word in the list and dropped out of the loop
            // before adding the final scratch list to the master list. Check and add

            if (scratchList.Count != 0)
            {
                listOfLists.Add(new List<T>(scratchList));
                scratchList.Clear();
            }

            // Shuffle the master list

            int mln = listOfLists.Count;
            // int fullN = n;

            // Work the master list from start to finish
            while (mln > 1)
            {
                mln--;

                int k = ThreadSafeRandom.ThisThreadsRandom.Next(mln + 1);

                List<T> value = listOfLists[k];
                listOfLists[k] = listOfLists[mln];
                listOfLists[mln] = value;

                //mln--;
            }

            // Reconstruct into a form the same as that passed in so the the transition is seamless

            List<T> reconList = new List<T>();

            foreach (var outer in listOfLists)
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
