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

namespace PoCW17
{


    public partial class Form1 : Form
    {
        public Form1()
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

            breakDown.Shuffle();

            txtChopped.Clear();

            txtChopped.AppendText(string.Join(" ", breakDown.GetRange(0, numberOfWords)));

            return;
        }

        //public static void Shuffle<T>(this IList<T> list)
        //{
        //    RNGCryptoServiceProvider provider = new RNGCryptoServiceProvider();

        //    int n = list.Count;

        //    while (n > 1)
        //    {
        //        byte[] box = new byte[1];
        //        do provider.GetBytes(box);
        //        while (!(box[0] < n * (Byte.MaxValue / n)));

        //        int k = (box[0] % n);

        //        n--;

        //        T value = list[k];
        //        list[k] = list[n];
        //        list[n] = value;

        //    }

        //}
    }




    public static class ThreadSafeRandom
    {
        [ThreadStatic] private static Random Local;

        public static Random ThisThreadsRandom
        {
            get { return Local ?? (Local = new Random(unchecked(Environment.TickCount * 31 + Thread.CurrentThread.ManagedThreadId))); }
        }
    }

    static class MyExtensions
    {
        public static void Shuffle<T>(this IList<T> list)
        {
            int n = list.Count;
            int fullN = n;
            int skip = 0;
            int chunkProgress = 0;
            int maxChunk;

            // Work out the maximum number of words to keep together in the event of that decision being reached
            if (fullN >= 2)
            {
                maxChunk = fullN / 2;
            }
            else
            {
                maxChunk = 1;
            }

            // Create storage for temp work lists and collection of those lists
            List<List<T>> listOfLists = new List<List<T>>();
            List<T> scratchList = new List<T>();

            // Work the master list from start to finish
            while (n > 1)
            {
                // n--;

                // Shall we bother?
                if (fullN >= 2 && chunkProgress == 0)
                {
                    skip = ThreadSafeRandom.ThisThreadsRandom.Next(0, 10); // Roll the dice - 1 in 10 chance of keeping more than one word together

                    if (skip == 5)
                    {
                        // Skip this many words
                        chunkProgress = ThreadSafeRandom.ThisThreadsRandom.Next(1, maxChunk);
                    }
                }

                if (chunkProgress == 0)
                {

                    // Either a chunk pass has ended or never existed in the first place. Either way a new list
                    // is required.

                    // Shuffle everything - works
                    //int k = ThreadSafeRandom.ThisThreadsRandom.Next(n + 1);

                    //T value = list[k];
                    //list[k] = list[n];
                    //list[n] = value;
                    // Shuffle everything - works

                    scratchList.Add(list[n]); // Add current word in the master list to its own list

                    // Add this list to the list of lists
                    listOfLists.Add(scratchList);

                    // Clear the scratch list ready for the next 
                }
                else
                {
                    chunkProgress--;
                }

                // Move to next word in the master list
                n--;
            }
        }
    }

















}
