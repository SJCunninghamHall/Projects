using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PolyTest15
{

    class Program
    {
        static void Main(string[] args)
        {

            double circleArea = 0;

            Rectangle r = new Rectangle(6, 6);
            Square sq = new Square(11, 11);
            Triangle t = new Triangle(5, 5);
            Circle ci = new Circle(6);

            Caller c = new Caller();

            c.CallArea(r);
            c.CallArea(sq);
            c.CallArea(t);

            circleArea = ci.Area();
            Console.WriteLine($"Circle area is :{circleArea}");

            Spaniel s = new Spaniel(15);
            s.Bark();

            Console.ReadKey();

        }
    }
}
