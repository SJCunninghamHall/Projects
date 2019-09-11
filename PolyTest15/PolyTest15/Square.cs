using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PolyTest15
{
    class Square : PolyTest15.Shape
    {
        public Square(int a = 0, int b = 0) : base(a, b)
        {

        }

        public override int Area()
        {
            Console.WriteLine($"Square class area :");
            return (width * height);
        }
    }
}
