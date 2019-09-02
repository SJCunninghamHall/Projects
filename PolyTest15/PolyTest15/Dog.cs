using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PolyTest15
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
