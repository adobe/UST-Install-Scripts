


using USTCustomActions;
using AdobeCertGen;
using System;

namespace DLLTest
{
    class Program
    {

        static void Main(string[] args)
        {

            // new ExpirationDatePicker().LaunchForm();

           Subject s = new Subject();

            s.ExpirationDate = DateTime.Now.Date.AddDays(7);

            Certificate c = new Certificate(s);

            Util.WriteCredentials(c, ".");



        }
    }
}





