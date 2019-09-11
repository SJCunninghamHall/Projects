using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PolyTest15
{
    class Caller
    {
        public void CallArea(PolyTest15.Shape sh)
        {
            int a;
            a = sh.Area();
            Console.WriteLine($"Area : {a}");
        }
    }
}
