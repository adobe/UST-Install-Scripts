using System;
using System.Collections.Generic;

namespace AdobeCertGen
{
    public class Subject
    {
        public Subject() {
               
            Randomize();
        }

        public Subject(string countryCode, string stateName, string locality, string orgName, string orgUnit, string commonName, string emailAddress, DateTime date)
        {           
            this.CountryCode = !string.IsNullOrEmpty(countryCode) ? countryCode : Util.GetRandomString();
            this.StateName = !string.IsNullOrEmpty(stateName) ? stateName : Util.GetRandomString();
            this.Locality = !string.IsNullOrEmpty(locality) ? locality : Util.GetRandomString();
            this.OrgName = !string.IsNullOrEmpty(orgName) ? orgName : Util.GetRandomString();
            this.OrgUnit = !string.IsNullOrEmpty(orgUnit) ? orgUnit : Util.GetRandomString();
            this.CommonName = !string.IsNullOrEmpty(commonName) ? commonName : Util.GetRandomString();
            this.EmailAddress = !string.IsNullOrEmpty(emailAddress) ? emailAddress : Util.GetRandomString(); 
            this.ExpirationDate = date; 
        }


        private void Randomize()
        {
            Subject s = Util.GetRandomSubject();      

            this.CountryCode = s.CountryCode;
            this.StateName = s.StateName;
            this.Locality = s.Locality;
            this.OrgName = s.OrgName;
            this.OrgUnit = s.OrgUnit;
            this.CommonName = s.CommonName;
            this.EmailAddress = s.EmailAddress;
            this.ExpirationDate = Util.GetInitialDate();

        }


        public string CountryCode { get; set; }
        public string StateName { get; set; }
        public string Locality { get; set; }
        public string OrgName { get; set; }
        public string OrgUnit { get; set; }
        public string CommonName { get; set; }
        public string EmailAddress { get; set; }
        public DateTime ExpirationDate { get; set; }

        public override string ToString()
        {
            return $"E={EmailAddress},CN={CommonName},OU={OrgUnit},O={OrgName},L={Locality},ST={StateName},C={CountryCode}";
        }

        public override bool Equals(object obj)
        {
            var subject = obj as Subject;
            return subject != null &&
                   CountryCode == subject.CountryCode &&
                   StateName == subject.StateName &&
                   Locality == subject.Locality &&
                   OrgName == subject.OrgName &&
                   OrgUnit == subject.OrgUnit &&
                   CommonName == subject.CommonName &&
                   EmailAddress == subject.EmailAddress &&
                   ExpirationDate == subject.ExpirationDate;
        }

        public override int GetHashCode()
        {
            var hashCode = 1167983894;
            hashCode = hashCode * -1521134295 + EqualityComparer<string>.Default.GetHashCode(CountryCode);
            hashCode = hashCode * -1521134295 + EqualityComparer<string>.Default.GetHashCode(StateName);
            hashCode = hashCode * -1521134295 + EqualityComparer<string>.Default.GetHashCode(Locality);
            hashCode = hashCode * -1521134295 + EqualityComparer<string>.Default.GetHashCode(OrgName);
            hashCode = hashCode * -1521134295 + EqualityComparer<string>.Default.GetHashCode(OrgUnit);
            hashCode = hashCode * -1521134295 + EqualityComparer<string>.Default.GetHashCode(CommonName);
            hashCode = hashCode * -1521134295 + EqualityComparer<string>.Default.GetHashCode(EmailAddress);
            hashCode = hashCode * -1521134295 + ExpirationDate.GetHashCode();
            return hashCode;
        }

    }

}
