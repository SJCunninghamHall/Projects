using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PolyTest15
{
    class Spaniel : PolyTest15.Dog
    {
        public Spaniel(int a = 0) : base(a)
        {
            Console.WriteLine($"Spaniel constructor called with value: {a}");
        }

        public override void Bark()
        {
            Console.WriteLine($"Padstow the Cavachon goes woof!! {valueToUse}");
        }
    }
}
