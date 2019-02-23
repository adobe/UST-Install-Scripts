<img src="https://github.com/adobe/UST-Install-Scripts/raw/master/contributing/ccelogo.png" height="150"> | <h1>Adobe User Sync Tool</h1><h2>Setup Guide</h2>
------------ | -------------

<br/>


### Installing the User Sync Tool
The UST should be installed on a VM or stable server if possible - the platforms listed below are supported.  The tool can be installed on an existing server ([AUSST](https://helpx.adobe.com/enterprise/package/help/update-server-setup-tool.html) for example), but and islolated solution is recommended for long term stability and maintainability.  The tool should be hosted within your network's firewall, and should be able to reach your Active Directory DC's, or other identity source. Follow the directions below to get started with installing the UST.


 Platform |  Installer
|------------ | :-------------|
|<img src="https://github.com/adobe/UST-Install-Scripts/raw/master/contributing/winlogo.png" height="50" width="54"> | **Windows (All versions)**: <br/> Use the msi based [windows installer](https://s3.us-east-2.amazonaws.com/adobe-ust-installer/AdobeUSTSetup.msi) for a streamlined setup process|
| <img src="https://github.com/adobe/UST-Install-Scripts/raw/master/contributing/ubuntulogo.png" height="25" width="25" > <img src="https://github.com/adobe/UST-Install-Scripts/raw/master/contributing/redhatlogo.png" height="25" width="25"><br/><img src="https://github.com/adobe/UST-Install-Scripts/raw/master/contributing/maclogo.gif" height="25" width="25"> <img src="https://github.com/adobe/UST-Install-Scripts/raw/master/contributing/centoslogo.png" height="25" width="25"> | **Linux and Mac OS (All versions)**: <br/>Follow the [directions below](https://github.com/adobe/UST-Install-Scripts#linux-ubuntu-1204-centos-7-fedora-redhat-susesles-debian-and-macos-os-x-10) to use the bash install scripts (cross platform)

You can also download the standalone self signed certgen for Adobe.IO [here] (https://s3.us-east-2.amazonaws.com/adobe-ust-installer/AdobeIOCertgen.zip)
<br/>

### Configuring the User Sync Tool
Configuration of the UST is beyond the scope of this page - please visit to links below for more information.

 Description | Location
|:------------ | :-------------|
|Overview of UST | https://spark.adobe.com/page/E3hSsLq3G1iVz/<br/>
|UST Official Repository | https://github.com/adobe-apiplatform/user-sync.py<br/>
|Setup and Success Guide | https://adobe-apiplatform.github.io/user-sync.py/en/success-guide/<br/>
|UST Setup Walkthrough | https://helpx.adobe.com/enterprise/using/user-sync.html



<br/>

### **Linux (Ubuntu 12.04+ CentOs 7+, Fedora, Redhat, Suse/SLES, Debian) and MacOS (OS-X 10)**
#### Important: as of April 2017, Ubuntu < 16.04 will no longer be able to communicate with the adobe endpoint!

The following will install User Sync and related packages on all of the above platforms (includes python if desired):

<code>sudo sh -c 'wget -O ins.sh https://git.io/fpxrz; chmod 777 ins.sh; ./ins.sh; rm ins.sh;'</code>

#### Prerequisites

For Cent Os/Fedora/Redhat, you may need to run the following to install wget:

<code>sudo sh -c 'yum-check update; yum install wget -y;' &> /dev/null </code>

For older versions of Ubuntu (12.04), you may need to run this line first to enable the proper security protocols:

<code>sudo sh -c 'apt-get update; apt-get install wget openssl libssl-dev -y -qq;' &> /dev/null</code>

For Mac OS, you will need ssl secure wget:

<code>sh -c 'brew update --force; brew install wget --with-libressl'</code>

### Generated Shell Scripts:
<b>run-user-sync.sh:</b> Runs UST in live mode with options --users mapped --process-groups<br/>
<b>run-user-sync-test.sh:</b> Runs UST in test mode with options --users mapped --process-groups<br/>
<b>sslCertGen.sh:</b> Generates a certificate-key pair for use with the UMAPI integration.  Places private.key and certificate.crt in the primary
install directory.<br/>
<b>examples</b> Directory of example configuration files for reference.

### Arguments

<code>--install-python</code>

By default, python is neither installed nor updated.  The script will determine which version of the user-sync tool to fetch based on which python versions are native to your
host Ubuntu version.  If you add the <b/>--install-python</b> flag, the script will determine the highest possible python version that can be installed on your host to work with
the selected UST version, and install/update that python version before downloading the tool.  This command can also be used in conjunction with the --offline flag to build
deployment archives for a target host and optimal python version.  The general behavior is: find which version of python 3 the UST version requires.  If that version is available, install it.
Otherwise, revert to python 2.7.

<code>--offline</code>

This option builds a complete UST package in .tar.gz format on your local machine. You can use this
to deploy the tool to VM's that are not able to run the script. Use this in combination with the above commands
to produce a target UST/python version package for your host.



<hr/>

