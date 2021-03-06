﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Chops
{
    static class ExtensionMethods
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
            reconList.ForEach(lb => { list.Add(lb); });

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















