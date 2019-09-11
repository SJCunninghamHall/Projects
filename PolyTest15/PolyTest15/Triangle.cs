using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PolyTest15
{
    class Triangle : PolyTest15.Shape
    {
        public Triangle(int a = 0, int b = 0) : base(a, b)
        {

        }

        public override int Area()
        {

            Console.WriteLine($"Triangle area :");
            return ((width * height) / 2);
        }
    }
}
