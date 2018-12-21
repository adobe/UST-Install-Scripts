using Microsoft.Deployment.WindowsInstaller;
using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

namespace USTCustomActions
{
    public static class RegChecker
    {

        public static List<String> CheckKey(RegistryKey key)
        {
            List<String> versions = new List<string>();

            foreach (String k in key.GetSubKeyNames())
            {
                RegistryKey subkey = key.OpenSubKey(k);
                Match m = Regex.Match((String)subkey.GetValue("DisplayName") ?? "", @"(?i)(Python).*(\(64-bit\))");

                if (m.Success)
                {
                    String v = (String)subkey.GetValue("DisplayVersion");
                    if (!versions.Contains(v)){ versions.Add(v); }
                }
            }

            key.Close();
            return versions;        
            
        }

        public static void CheckPythonInstalled(Session session)
        {
            List<String> versions = new List<string>();

            versions.AddRange(CheckKey(Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")));
            versions.AddRange(CheckKey(Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall")));

            bool installed = false;

            String versionList = "[";

            foreach (String v in versions)
            {
                if (v.Contains("3.6."))
                {
                    installed = true;                    
                }

                versionList += v + "; ";
            }
            
            if (versions.Count > 0) { session["PYTHONTEXT"] = versionList.Trim().TrimEnd(';') + "]"; }
            if (!installed) { session["INSTALLPYTHON"] = "1"; }

        }
    }
}



