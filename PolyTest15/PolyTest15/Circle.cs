using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PolyTest15
{
    class Circle
    {

        double radius;
        double pi = Math.PI;

        public Circle(int r = 0)
        {
            radius = r;
        }

        public double Area()
        {
            Console.WriteLine($"Circle area :");
            return pi * (radius * radius);
        }

    }
}
