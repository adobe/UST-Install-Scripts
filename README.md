<img src="resources/images/adobe-2020-red.png" height="150"> | <h1>Adobe User Sync Tool</h1><h2>Setup Guide</h2>
------------ | -------------

<br/>


### Installing the User Sync Tool
The UST should be installed on a VM or stable server if possible - the platforms listed below are supported.  The tool can be installed on an existing server ([AUSST](https://helpx.adobe.com/enterprise/package/help/update-server-setup-tool.html) for example), but and islolated solution is recommended for long term stability and maintainability.  The tool should be hosted within your network's firewall, and should be able to reach your Active Directory DC's, or other identity source. Follow the directions below to get started with installing the UST.


 Platform |  Installer
|------------ | :-------------|
|<img src="resources/images/winlogo.png" height="50" width="54"> | **Windows**: <br/> Use the msi based [windows installer](https://github.com/adobe/UST-Install-Scripts/releases/download/v2.6.1-installer/AdobeUSTSetup-2.6.1.exe) for a streamlined setup process|
| <img src="resources/images/ubuntulogo.png" height="25" width="25" > <img src="resources/images/redhatlogo.png" height="25" width="25"><br/><img src="resources/images/fedora.png" height="25" width="25"> <img src="resources/images/centoslogo.png" height="25" width="25"> | **Linux**: <br/>Follow the [directions below](https://github.com/adobe/UST-Install-Scripts#linux-ubuntu-1604-centos-7-fedora-redhat) to install on any supported platform.


<br/>

### Configuring the User Sync Tool
Configuration of the UST is beyond the scope of this page - please visit the links below for more information.

 Description | Location
|:------------ | :-------------|
|Overview of UST | https://spark.adobe.com/page/E3hSsLq3G1iVz/<br/>
|UST Official Repository | https://github.com/adobe-apiplatform/user-sync.py<br/>
|Setup and Success Guide | https://adobe-apiplatform.github.io/user-sync.py/en/success-guide/<br/>
|UST Setup Walkthrough | https://helpx.adobe.com/enterprise/using/user-sync.html

You can also download the Adobe.IO UMAPI certgen tool (windows only) independently [here](https://github.com/adobe/UST-Install-Scripts/releases/download/v2.6.1-installer/AdobeIOCertgen.zip) if you only need to update your cert/keypair.  This is included as a part of the full installation as well.

<br/>

### **Linux (Ubuntu 16.04+ CentOs 7+, Fedora, Redhat)**

Self install function coming soon.  For now, download the executable from https://github.com/adobe-apiplatform/user-sync.py/releases, and run:

`./user-sync example-config`

This will create the basic configuration files.  You can generate the umapi cert/keypair by running:

`./user-sync certgen`

User sync can then be run simply on the command line or a shell script.  For example:

`./user-sync --users mapped --process-groups -t`
<hr/>

