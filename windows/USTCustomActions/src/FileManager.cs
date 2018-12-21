using Microsoft.Deployment.WindowsInstaller;
using System;
using System.Diagnostics;
using System.IO;


namespace USTCustomActions
{
    class FileManager
    {


        public static void InstallPackage(Session session, String fileName, String args)
        {

            session.Log("Begin " + fileName + " Install");
            String ext = fileName.Substring(fileName.Length - 4, 4);
            String tempFile = Path.GetTempFileName().Replace(".tmp", ext);

            using (View binaryView = session.Database.OpenView("SELECT Name, Data FROM Binary WHERE Name='"+ fileName + "'"))
            {
                binaryView.Execute();
                using (Record binaryRec = binaryView.Fetch())
                {
                    binaryRec.GetStream(2, tempFile);
                }
            }

            Process.Start(tempFile, args).WaitForExit();
            File.Delete(tempFile);

           
        }


    }
}
