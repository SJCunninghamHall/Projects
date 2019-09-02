using System;

namespace PolymorphismApplication
{
    class Spaniel : PolyTest.Dog
    {
        public Spaniel(int a = 0) : base(a)
        {
            Console.WriteLine($"Spaniel constructor called with value: {a}");
        }

        public override void Bark()
        {
            Console.WriteLine($"Spainel goes woof {valueToUse}!");
        }
    }

    class Parrot : PolyTest.Bird
    {
        public Parrot(int value) : base(value)
        {
            Console.WriteLine($"Parrot called with {value}");
        }
    }


    class Rectangle : PolyTest.Shape
    {
        public Rectangle(int a = 0, int b = 0) : base(a, b)
        {

        }
        public override int area()
        {
            Console.WriteLine("Rectangle class area :");
            return (width * height);
        }
    }

    class Square : PolyTest.Shape
    {
        public Square(int a = 0, int b = 0) : base(a, b)
        {
        }

        public override int area()
        {
            Console.WriteLine("Square class area :");
            return (width * height);
        }
    }

    class Parallelagram : PolyTest.Shape
    {
        public Parallelagram(int a = 0, int b = 0) : base(a, b)
        {
            Console.WriteLine("Width inherited from base class: {0}", width);
            Console.WriteLine("Height inherited from base class: {0}", height);
        }

        public override int area()
        {
            Console.WriteLine("Parallelagram class area :");
            return (width * height);
        }
    }

    class Triangle : PolyTest.Shape
    {
        public Triangle(int a = 0, int b = 0) : base(a, b)
        {
        }
        public override int area()
        {
            Console.WriteLine("Triangle class area :");
            return (width * height / 2);
        }
    }

    class Caller
    {
        public void CallArea(PolyTest.Shape sh)
        {
            int a;
            a = sh.area();
            Console.WriteLine("Area: {0}", a);
        }
    }

    class CallerSS
    {
        public void CallAreaSS(Parallelagram pss)
        {
            int pa;
            pa = pss.area();
            Console.WriteLine("Parallelagram area: {0}", pa);
        }
    }

    class Tester
    {
        static void Main(string[] args)
        {
            Caller c = new Caller();
            CallerSS css = new CallerSS();
            Rectangle r = new Rectangle(10, 7);
            Triangle t = new Triangle(10, 5);
            Square s = new Square(6, 6);
            Parallelagram p = new Parallelagram(31415, 66261);

            Parrot parrot = new Parrot(450);

            Spaniel spaniel = new Spaniel(662);
            spaniel.Bark();

            c.CallArea(r);
            c.CallArea(t);
            c.CallArea(s);
            c.CallArea(p);

            css.CallAreaSS(p);

            Console.ReadKey();
        }
    }
}