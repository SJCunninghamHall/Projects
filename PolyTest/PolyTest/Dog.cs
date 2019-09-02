using System;
using System.Collections.Generic;
using System.Text;

namespace PolyTest
{
    class Dog
    {

        protected int valueToUse;

        public Dog(int value)
        {
            Console.WriteLine($"Dog base constructor called with {value}");
            valueToUse = value;
        }

        public virtual void Bark()
        {
        }
    }
}
