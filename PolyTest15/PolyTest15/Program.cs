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
            Console.WriteLine($"Spaniel goes woof {valueToUse}");
        }
    }

    class Triangle : PolyTest15.Shape
    {
        public Triangle(int a = 0, int b = 0) : base(a, b)
        {

        }

        public override int Area()
        {

            Console.WriteLine($"Triangle area :");
            return((width * height) / 2);
        }
    }

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

    class Rectangle : PolyTest15.Shape
    {

        public Rectangle(int a = 0, int b = 0) : base(a, b)
        {

        }

        public override int Area()
        {
            Console.WriteLine($"Rectangle class area :");
            return (width * height);
        }

    }

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

    class Caller
    {
        public void CallArea(PolyTest15.Shape sh)
        {
            int a;
            a = sh.Area();
            Console.WriteLine($"Area : {a}");
        }
    }

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
