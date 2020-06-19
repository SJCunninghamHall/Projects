using System;
using System.Threading;

namespace ThreadWork
{
    class Program
    {
        static void Main(string[] args)
        {

            BankAccount acct = new BankAccount(10);

            Thread[] threads = new Thread[15];

            Thread.CurrentThread.Name = "main";

            for (int i = 0; i < 15; i++)
            {
                Thread t = new Thread(new ThreadStart(acct.IssueWithdraw));

                t.Name = i.ToString();
                threads[i] = t;
                                      
            }

            for (int i = 0; i < 15; i++)
            {
                Console.WriteLine("Thread {0} alive: {1}", threads[i].Name, threads[i].IsAlive);

                threads[i].Start();

                Console.WriteLine("Thread {0} alive: {1}", threads[i].Name, threads[i].IsAlive);

            }

            Console.WriteLine("Current priority {0}", Thread.CurrentThread.Priority);

            Console.WriteLine("Thread {0} ending", Thread.CurrentThread.Name);

            Console.ReadLine();

        }

        class BankAccount
        {
            private Object acctLock = new object();
            double balance { set; get; }

            public BankAccount(double bal)
            {
                balance = bal;
            }

            public double Withdraw(double amt)
            {
                if (balance - amt < 0)
                {
                    Console.WriteLine("Sorry, balance is {0}", balance);
                    return balance;
                }

                lock (acctLock)
                {
                    if (balance >= amt)
                    {
                        Console.WriteLine("Removed {0} and balance is now {1}", amt, balance - amt);
                        balance -= amt;
                    }
                    return balance;
                }

            }

            public void IssueWithdraw()
            {
                Withdraw(1);
            }

        }

    }
}
