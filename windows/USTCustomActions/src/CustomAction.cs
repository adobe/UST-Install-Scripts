using Microsoft.Deployment.WindowsInstaller;
using System.Diagnostics;
using AdobeCertGen;
using System;

namespace USTCustomActions
{

    public class CustomActions
    {
        [CustomAction]
        public static ActionResult CheckPythonVersion(Session session)
        {
            RegistryUtil.CheckPythonInstalled(session);
            return ActionResult.Success;
        }

        [CustomAction]
        public static ActionResult SslCertGen (Session session)
        {

            Subject s = new Subject(
                session["SUBJECT_COUNTRY"],
                session["SUBJECT_STATE"],
                session["SUBJECT_CITY"],
                session["SUBJECT_ORG"],
                session["SUBJECT_DEPARTMENT"],
                session["SUBJECT_NAME"],
                session["SUBJECT_EMAIL"],
                DateTime.Parse(session["SUBJECT_DATE_TEXT"])
                );

            Certificate c = new Certificate(s);

            Util.WriteCredentials(c, session["INSTALLDIR"]);

            return ActionResult.Success;
        }

        [CustomAction]
        public static ActionResult InstallPython27Offline (Session session)
        {
            FileManager.InstallPackage(session, "Python2.msi", "ADDLOCAL=ALL /passive InstallAllUsers=1");
            return ActionResult.Success;
        }

        [CustomAction]
        public static ActionResult InstallVcRedist(Session session)
        {       
            FileManager.InstallPackage(session, "vcredist_x64.exe", "/q");
            return ActionResult.Success;
        }

        [CustomAction]
        public static ActionResult OpenUSTFolder(Session session)
        {
            Process.Start(session["INSTALLDIR"]);
            return ActionResult.Success;
        }

        [CustomAction]
        public static ActionResult LaunchCalendar(Session session)
        {
            new ExpirationDatePicker(session).LaunchForm(); 
            return ActionResult.Success;
        }

        [CustomAction]
        public static ActionResult GetCalendarStart(Session session)
        {
            session["SUBJECT_DATE_TEXT"] = ExpirationDatePicker.getStartDate().ToString("MM/dd/yyyy");
            return ActionResult.Success;
        }

        [CustomAction]
        public static ActionResult SetLongPaths(Session session)
        {
            RegistryUtil.SetLongPathKey();
            return ActionResult.Success;
        }
    }
}
