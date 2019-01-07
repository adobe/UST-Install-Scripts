using System;
using System.Collections.Generic;
using Org.BouncyCastle.Security;
using Org.BouncyCastle.X509;
using Org.BouncyCastle.Asn1.X509;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Generators;
using Org.BouncyCastle.Crypto.Operators;

namespace AdobeCertGen
{
    public class Certificate
    {

        public Certificate()
        {
            this.Subject = new Subject();
            Generate();
        }

        public Certificate(Subject subject)
        {
            this.Subject = subject;
            Generate();
        }


        public void Generate()
        {
                   
            var certificateGenerator = new X509V3CertificateGenerator();
            var keyGenerationParameters = new KeyGenerationParameters(new SecureRandom(), 2048);
            var keyPairGenerator = new RsaKeyPairGenerator();
            keyPairGenerator.Init(keyGenerationParameters);
            var subjectKeyPair = keyPairGenerator.GenerateKeyPair();
            var signatureFactory = new Asn1SignatureFactory("SHA256WithRSA", subjectKeyPair.Private);

            certificateGenerator.SetSerialNumber(Util.GetRandomInt());
            certificateGenerator.SetIssuerDN(new X509Name(this.Subject.ToString()));
            certificateGenerator.SetSubjectDN(new X509Name(this.Subject.ToString()));
            certificateGenerator.SetNotBefore(DateTime.Now.Date.AddDays(1));
            certificateGenerator.SetNotAfter(Subject.ExpirationDate.Date.AddDays(1));
            certificateGenerator.SetPublicKey(subjectKeyPair.Public);

            this.PublicCert = certificateGenerator.Generate(signatureFactory);
            this.PrivateKey = subjectKeyPair.Private;

        }

        public X509Certificate PublicCert { get; set; }
        public AsymmetricKeyParameter PrivateKey { get; set; }
        public Subject Subject { get; set; }

        public override bool Equals(object obj)
        {
            var certificate = obj as Certificate;
            return certificate != null &&
                   EqualityComparer<X509Certificate>.Default.Equals(PublicCert, certificate.PublicCert) &&
                   EqualityComparer<AsymmetricKeyParameter>.Default.Equals(PrivateKey, certificate.PrivateKey) &&
                   EqualityComparer<Subject>.Default.Equals(Subject, certificate.Subject);
        }

        public override int GetHashCode()
        {
            var hashCode = -1655976428;
            hashCode = hashCode * -1521134295 + EqualityComparer<X509Certificate>.Default.GetHashCode(PublicCert);
            hashCode = hashCode * -1521134295 + EqualityComparer<AsymmetricKeyParameter>.Default.GetHashCode(PrivateKey);
            hashCode = hashCode * -1521134295 + EqualityComparer<Subject>.Default.GetHashCode(Subject);
            return hashCode;
        }
    }
}
