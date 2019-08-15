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

            while (n > 1)
            {
                n--;
                int k = ThreadSafeRandom.ThisThreadsRandom.Next(n + 1);

                T value = list[k];
                list[k] = list[n];
                list[n] = value;
            }
        }
    }



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
}
