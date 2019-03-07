<img src="https://github.com/adobe/UST-Install-Scripts/raw/master/contributing/ccelogo.png" height="150"> | <h1>Adobe User Sync Tool</h1><h2>Setup Guide</h2>
------------ | -------------

<br/>


### Installing the User Sync Tool
The UST should be installed on a VM or stable server if possible - the platforms listed below are supported.  The tool can be installed on an existing server ([AUSST](https://helpx.adobe.com/enterprise/package/help/update-server-setup-tool.html) for example), but and islolated solution is recommended for long term stability and maintainability.  The tool should be hosted within your network's firewall, and should be able to reach your Active Directory DC's, or other identity source. Follow the directions below to get started with installing the UST.


 Platform |  Installer
|------------ | :-------------|
|<img src="https://github.com/adobe/UST-Install-Scripts/raw/master/contributing/winlogo.png" height="50" width="54"> | **Windows**: <br/> Use the msi based [windows installer](https://github.com/adobe/UST-Install-Scripts/releases/latest) for a streamlined setup process|
| <img src="https://github.com/adobe/UST-Install-Scripts/raw/master/contributing/ubuntulogo.png" height="25" width="25" > <img src="https://github.com/adobe/UST-Install-Scripts/raw/master/contributing/redhatlogo.png" height="25" width="25"><br/><img src="https://github.com/adobe/UST-Install-Scripts/raw/master/contributing/fedora.png" height="25" width="25"> <img src="https://github.com/adobe/UST-Install-Scripts/raw/master/contributing/centoslogo.png" height="25" width="25"> | **Linux**: <br/>Follow the [directions below](https://github.com/adobe/UST-Install-Scripts#linux-ubuntu-1204-centos-7-fedora-redhat-susesles-debian-and-macos-os-x-10) to use the bash install scripts (cross platform)


<br/>

### Configuring the User Sync Tool
Configuration of the UST is beyond the scope of this page - please visit to links below for more information.

 Description | Location
|:------------ | :-------------|
|Overview of UST | https://spark.adobe.com/page/E3hSsLq3G1iVz/<br/>
|UST Official Repository | https://github.com/adobe-apiplatform/user-sync.py<br/>
|Setup and Success Guide | https://adobe-apiplatform.github.io/user-sync.py/en/success-guide/<br/>
|UST Setup Walkthrough | https://helpx.adobe.com/enterprise/using/user-sync.html

You can download the Adobe.IO UMAPI certgen tool (windows only) independently [here](https://s3.us-east-2.amazonaws.com/adobe-ust-installer/AdobeIOCertgen.zip) - this is also included as part of the install.


<br/>

### **Linux (Ubuntu 16.04+ CentOs 7+, Fedora, Redhat)**


The following will install User Sync and related packages on all of the above platforms.  Execute the command on bash shell:

<code>curl -L https://git.io/fhpuG | sudo python -</code>

Or, if **python** is not the correct alias on your system, please use the one you wish to run UST with.  E.g., on Ubuntu 18,

<code>curl -L https://git.io/fhpuG | sudo **python3** -</code>

### Prerequisites

Python 2.7 or 3.6 **must** be pre-installed to use the sync tool - and the install process will exit if this older versions are used!

### Generated Shell Scripts:
<b>run-user-sync.sh:</b> Runs UST in live mode with options --users mapped --process-groups<br/>
<b>run-user-sync-test.sh:</b> Runs UST in test mode with options --users mapped --process-groups<br/>
<b>sslCertGen.sh:</b> Generates a certificate-key pair for use with the UMAPI integration.  Places private.key and certificate.crt in the primary
install directory.<br/>
<b>examples</b> Directory of example configuration files for reference.

The installer will also create a **log file** (ust_install.log) in the working directory at the debug level automatically.

### Arguments

<code>-d, --debug</code>

Show debug logging 

<code>-fs, --force-sudo</code>

Overrides the sudo requirement - *Warning, if the shell asks for user input such as sudo password, the installer will hang indefinitely!*


<hr/>

