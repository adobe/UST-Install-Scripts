using Org.BouncyCastle.Math;
using Org.BouncyCastle.OpenSsl;
using Org.BouncyCastle.Security;
using Org.BouncyCastle.Utilities;
using System;
using System.IO;

namespace AdobeCertGen
{
    public class Util
    {
        public static void WriteCredentials(Certificate certificate, String dir)
        {

            WriteEncoded(certificate.PublicCert, dir + "\\certificate_pub.crt");
            WriteEncoded(certificate.PrivateKey, dir + "\\private.key");

        }

        private static void WriteEncoded(Object o, String path)
        {
            PemWriter pemWriter = new PemWriter(new StreamWriter(path));
            pemWriter.WriteObject(o);
            pemWriter.Writer.Flush();
            pemWriter.Writer.Close();
        }

        public static Subject GetRandomSubject()
        {

            return new Subject(
                 GetRandomString().Substring(3, 2).ToUpper(),
                 GetRandomString(),
                 GetRandomString(),
                 GetRandomString(),
                 GetRandomString(),
                 GetRandomString(),
                 GetRandomString()
                 );
        }

        public static BigInteger GetRandomInt()
        {
            return BigIntegers.CreateRandomInRange(BigInteger.One, BigInteger.ValueOf(Int64.MaxValue), new SecureRandom());
        }

        public static String GetRandomString()
        {
            byte[] toEncodeAsBytes = System.Text.ASCIIEncoding.ASCII.GetBytes(GetRandomInt().ToString());
            return System.Convert.ToBase64String(toEncodeAsBytes).Substring(0, 8);
        }


    }
}
