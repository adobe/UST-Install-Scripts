#!/usr/bin/env bash


# Copyright 2018 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.


# User Sync Tool installation script
# Danimae Janssen 06/2018

# This script is cross-platform compatible, and has should work on the following platforms:
# Ubuntu (12.04+), Fedora (27+), Redhat (7+), CentOS (7+), SLES (12+), OpenSUSE (42+), Mac OSX (10+), Debian (9+), Raspbian (9+)
# User Sync is NOT available on all of the above, but this script aims to provide an
# installation environment for them regardles to simplify the build/implementation.

# The officially supported platforms are Ubuntu, CentOS, and MacOS.  User sync builds
# for CentOS will also run on Fedora/Redhat, but are not officially supported.

########################################################################################################################

# Global default/initialization parameters - these do not reflect default configurations for installation, but
# serve as defaults for use in the script.  These should not be changed.

offlineMode=false
installPython=false
installWarnings=false
installParams=()

instURL="https://raw.githubusercontent.com/adobe/UST-Install-Scripts/master/other_platforms/UST_quick_install_linux.sh"
libURL="https://raw.githubusercontent.com/adobe/UST-Install-Scripts/master/other_platforms/linux_host_libs.sh"

# Default version of UST to be installed.  This can be overridden by the command line argument --ust-version
# The previous release (2.2.2) is available as a backup

ustVer="2.3"

# Default Python level. This should be left as is, since python versioning is built into the script

pyversion="2"

########################################################################################################################

# Gets the command line parameters, and adds them to a parameter array. The array is required
# in the case that the script must re-run itself with reduced privilege but with the
# same runtime arguments (happens on MacOS only)

while [[ $# -gt 0 ]]
do
key=$1
case $key in
    --install-python)
        installPython=true
        installParams+=("--install-python")
        shift ;;
    --offline)
        offlineMode=true
        installParams+=("--offline")
        shift ;;
    --ust-version)
        if [[ $2 == "2.2.2" || $2 == "2.3" ]]; then
            ustVer=$2
            installParams+=("--ust-version $2")
        else
            echo "Version '$2' - Invalid version (2.2.2 or 2.3 only)"
            exit
        fi
        shift # past argument
        shift # past value
        ;;
    *)
        echo "Parameter '$1' not recognized"
        exit
        shift # past argument
        shift # past value
esac
done

# Sets the default values for the example configurations.  These are specified here since they are platform independent, and
# provide context for setting up the User Sync installation environment in the case that user sync is not yet available
# on the current platform. These values are superceded by those in the linux host libs script for supported hosts.

case $ustVer in
    "2.2.2") USTExamplesURL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/example-configurations.tar.gz";;
      "2.3") USTExamplesURL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/example-configurations.tar.gz";;
          *) echo "Version '$ustVer' - Invalid version (2.2.2 or 2.3 only)"; exit;;
esac
########################################################################################################################

# Simple functions for making bash beautiful :)

# Color printing - supported on all modern bash shells
function printColor(){

    case $2 in
        "black") col=0;;
          "red") col=1;;
        "green") col=2;;
       "yellow") col=3;;
         "blue") col=4;;
      "magenta") col=5;;
         "cyan") col=6;;
        "white") col=7;;
              *) col=7;;
    esac

    printf "$(tput setaf $col)$1$(tput sgr 0)\n"
}

function printColorOS(){
    printColor "- $1" $2
}

# Custom colored banner.  $fullname $numericalVersion are determined prior to printing this.  $fullname and $numericalVersion
# represent the name of the host platform and its version.  These values are detailed more below in the getHost method.

function printUSTBanner(){
 cat << EOM
$(tput setaf 6)
=========================================================
$(tput setaf 5)$fullName $numericalVersion$(tput setaf 6)

         _   _                 ___
        | | | |___ ___ _ _    / __|_  _ _ _  __
        | |_| (_-</ -_) '_|   \__ \ || | ' \/ _|
         \___//__/\___|_|     |___/\_, |_||_\__|
                                   |__/


$(tput setaf 2)Linux Quick Install 2.5 for UST v2.2.2 - 2.3
https://github.com/adobe/UST-Install-Scripts    $(tput setaf 6)
=========================================================$(tput sgr 0)
EOM

}


# Prints a simple banner with message - useful for keeping portions of output better organized
# Available types are info, warning, and error.  These correspond to colors of green, yellow
# and red respectively.  Color can be overridden with the -c argument.

function banner(){

    type="Info"
    color="green"

    while [[ $# -gt 0 ]]
    do
    key=$1
    case $key in
        -m|--message)
        message=$2
        shift # past argument
        shift # past value
        ;;
        -t|--type)
        type=$2
        shift # past argument
        shift # past value
        ;;
        -c|--color)
        color=$2
        shift # past argument
        shift # past value
        ;;
    esac
    done

    if ! [[ $message = *[!\ ]* ]]; then message=${type}; fi

    sep="$(printf -- '=%.0s' {1..20})"

    if [[ $color == "green" ]]; then
        case $type in
            "Warning") color="yellow";;
            "Error") color="red";;
        esac
    fi

    printColor "\n$sep $message $sep" $color

}


########################################################################################################################

# Utility methods

# Validates that a download was successful by testing the size of the file.  In this case, the download
# is assumed to be valid provided its size exceeds 10kb.  This is helpful in identifying cases where a
# download is started but terminates immediately, leaving behind a near-zero size file.

# Usage: validateDownload filename

function validateDownload(){
    if [[ $(wc -c <$1) -le 10000 ]]; then
        printColorOS "Download error!" red
        installWarnings=true
        return 2
    fi
}


# Downloads and creates a file with name determined by the URL string. For example,
# a url of foo.com/bar.tar.gz results in a local archive named bar.tar.gz

# Usage: download URL

function download(){
    url=$1
    output=${url##*/}
    wget -O $output $url &> /dev/null
    echo $output
}


# Method used to install packages in a cross platform way.  Each platform has a specific install string
# which is set in the getHost method (i.e., apt-get install). If the download command returns a 0 exit status,
# the install is successful.  Otherwise, an error is printed and the installWarnings flag is triggered, which
# notifies the user at the end of the script that further attention may be required.  For MacOS, an initial failure
# results in a retry using the upgrade string instead before declaring an error.  This is added because in MacOS,
# the install returns a failure status if the package is already present but not up to date (unlike Linux, which
# will automatically update and return a success.

# Usage: installPackage nano

function installPackage(){

    if ! $installString $1 &> /dev/null; then

        if $isMacOs; then
            if  ! brew upgrade $1 &> /dev/null; then
                printColorOS "Install error - $1 may be up to date..."
            fi
        else
            printColorOS "Error installing $1... install will continue..." yellow
        fi

        installWarnings=true
    fi

}

# Self explanatory.  Extracts a tar-gz archive given by the input parameter, and extracts it to the specified
# folder.  If the process results in an error, the installWarnings flag is triggered, and a red warning occurs.

# Usage: extractArchive source destination

function extractArchive(){

    sourceDir=$1
    destination=$2
    printColorOS "Extracting $sourceDir to  $(tput setaf 3)$destination$(tput sgr 0)..."

    if ! tar -zxvf $sourceDir -C "$destination" &> /dev/null; then
        printColorOS "Extraction error!" red
        installWarnings=true
        return 2
    fi

}


# Packaging function.  This is executed when the --offline flag is used to generate a packaged tar.gz archive ready for deployment on a target server.
# This function simply gathers the entire install directory into an archive, and then removes the parent folder.  For more information on the
# offline packaging feature, see the documentation.

function package(){

    filename="UST_${ustVer}_py${fullPyVersion}.tar.gz"
    test -e $filename && rm $filename
    printColorOS "Packaging $PWD/$filename..." green
    tar -czf $filename -C "$USTFolder" .
    rm -rf "$USTFolder"
    printColorOS "Package complete! You can now distribute $(tput setaf 5)$filename$(tput setaf 2) to your remote server!\n" green

}

########################################################################################################################

# Procedural methods

# Sets up the install directory.  By default, this is a combination of "User-Sync" followed by the specified
# version number (i.e., User-Sync-2.3).  This method checks before creating the directory, and removes it if it
# exists prior to creation.  This helps to keep things clean.

function configureInstallDirectory(){
    USTInstallDir="${PWD}/User-Sync-${ustVer}"
    if [[ -d "${USTInstallDir}" ]]; then
        rm -rf "${USTInstallDir}"
    fi
    mkdir "${USTInstallDir}"
    echo "${USTInstallDir}"
}

# While this method appears simple, it draws a great deal of logic from the host libs script.  Python versioning is determined automatically,
# and this script simply executes the results of a much greater platform-specific process, but does so in a cross-platform way.  This
# method is only ever called if the --install-python argument is invoked on the main process.  The user is notified if python fails to install.

function installPy(){
    banner -m "Installing Python $fullPyVersion"

    [[ $pyversion -eq 2 ]] && installPython27 || installPython3

    if [[ -x "$(command -v $pyCommand)" ]]; then
        printColorOS "Python installed succesfully!" green
    else
        printColorOS "Python installation failed...\n- Consider using automatic versioning or install manually!" red
        installWarnings=true
    fi
}

# This method runs the appropriate platform-specific repository update (i.e., apt-get update), and proceeds to install all of the specified
# packages.  The packages are specified explicitly for each platform in the getHost method via an array.  Most of the time, these packages are
# not strictly required, but can be helpful in some cases.  Install failures here can be safely ignored if the environment is set up properly anyway.
# the installPy method is called here if the user included the --install-python flag.

function getPackages(){
    banner -m "Installing Packages"
    printColorOS "Updating repositories..."
    $updateCmd &> /dev/null

    for i in ${packageList[@]}; do
        printColorOS "Installing $i..."
        installPackage $i
    done
    printColorOS "Prerequisites installed succesfully!" green
    if $installPython; then installPy; fi
}

# Most of the useful functionality occurs in the getUSTFiles method.  This method fetches the examples and user-sync archives, and uses them
# to construct a coherent file structure that constitutes the user sync environment.  This includes copying and renaming the configuration
# .yml files from the examples sub-directory to primary install directory, as well as extracting user-sync.pex itself to that directory.

# In addition, shell scripts are generated that facilitate easy running of the tool in test and regular mode with standard parameters, and
# an openSSL script to create the public/private key pair that User Sync needs to communicate securely with the UMAPI.

# If this function fails to run successfully, the install is effectively a failure.  The python URLs defined herein are specified in the
# host libs script per platform, and must point to the correct version of User Sync for the tool to run at the end.  Although this method
# looks straightforward, it should be noted that its success depends on the positive outcome of the decision making routines in host libs
# and the getHosts method below.  The culmination of that logic determines both the python version and the correct URL to pull from!

function getUSTFiles(){
    USTFolder=$1

    # If $getUST is set to true by the getHost method, it means that the platform has been successfully identified as a supported
    # version, and the resources have been fetched.  This means we know which version of user-sync.pex to get, so we can go ahead and do it.

    if $getUST; then

        # Set URL according to python version
        [[ $pyversion -eq 2 ]] && USTUrl=$USTPython2URL || USTUrl=$USTPython3URL

        # Check UST version
        [[ $USTUrl =~ "v".+"/" ]]
        IFS='/' read -r -a array <<< "$BASH_REMATCH"
        USTVersion=${array[0]}

        banner -m "Configuring UST"

        printColorOS "Using directory $(tput setaf 3)$USTFolder$(tput sgr 0)..."
        printColorOS "Downloading UST $USTVersion...$(tput setaf 5)($USTUrl)$(tput sgr 0)"
        USTArch=$(download $USTUrl)
        validateDownload $USTArch
        extractArchive $USTArch "$USTFolder"

    else
        printColor "\n- UST will not be downloaded - host version could not be determined.  Please download manually...\n" yellow
    fi

    # Regardless of whether we have user-sync.pex, we can still proceed to construct the remainder of the environment.  Here we get the
    # examples archive and use it to build the install directory.

    printColorOS "Downloading UST Examples...$(tput setaf 5)($USTExamplesURL)$(tput sgr 0)"
    EXArch=$(download $USTExamplesURL)
    validateDownload $EXArch

    printColorOS "Creating directory $(tput setaf 3)$USTFolder/examples$(tput sgr 0)..."
    mkdir "$USTFolder/examples" &> /dev/null

    # Create the usable versions of the config files by copying them to the install directory
    if extractArchive $EXArch "$USTFolder"; then
        printColorOS "Copying configuration files..."
        cp "$USTFolder/examples/config files - basic/1 user-sync-config.yml" "$USTFolder/user-sync-config.yml"
        cp "$USTFolder/examples/config files - basic/2 connector-umapi.yml" "$USTFolder/connector-umapi.yml"
        cp "$USTFolder/examples/config files - basic/3 connector-ldap.yml" "$USTFolder/connector-ldap.yml"
    fi

    # Clean up the downloaded .tar.gz files
    printColorOS "Removing temporary files..."
    rm $USTArch $EXArch

    # Here we create some simple shell scripts for running UST in test and live mode with the commonly used flags of --users mapped and
    # --process-groups.  Refer to the User Sync documentation for more information.

    printColorOS "Creating shell scripts for running UST..."
    printf "#!/usr/bin/env bash\n./user-sync --users mapped --process-groups -t" > "$USTFolder/run-user-sync-test.sh"
    printf "#!/usr/bin/env bash\n./user-sync --users mapped --process-groups" > "$USTFolder/run-user-sync.sh"

    # It is also helpful to generate a shell script which can be used to create the public/private key pair needed by User Sync to talk
    # to the UMAPI. The default lifetime is set here for 9125 days (25 years) for convenience.  The shell script will prompt the users
    # for specific information, and the deposit certificate_pub.crt and private.key into the install directory.

    printColorOS "Generating shell script for certificate generation..."
    SSLString="openssl req -x509 -sha256 -nodes -days 9125 -newkey rsa:2048 -keyout private.key -out certificate_pub.crt"
    printf "#!/usr/bin/env bash\n$SSLString" > "$USTFolder/sslCertGen.sh"

    printColorOS "UST installed succesfully!" green

}

# getHost is the beginning of the decision making process implemented throughout the script.  It aims to identify both the platform executing
# the script, as well as it's full version stamping.  This information is used to automate the selection of python/user-sync combinations
# so as to cause the least possible impact to the host system while optimizing the version choices.

# If getHost can correctly determine the platform and version, the appropriate update/install strings can be defined and the version can
# be used to execute the correct platform-specific libraries (host_libs).  Furthermore, a minVersion variable is defined so that any attempt
# to run the script on an incompatible version (eg, Ubuntu < 12.04, or CentOS 6) will result in an immediate error message and termination
# instead of a botched install process.

# Some helper methods are nested withing getHost to help it evaluate the host and version info across a variety of platforms that all
# report such information with slight differences.  The approach is a catch-all attempt, with some smart error correction if no proper
# results are found.

# IF THE HOST AND VERSION CANNOT BE DETERMINED, THE SCRIPT WILL NOT INSTALL USER-SYNC.PEX OR EXECUTE ANY PACKAGE INSTALLATION
# EVEN IF THE PLATFORM IS ACTUALLY SUPPORTED

# The remainder of the installation (example/install directory setup) will complete normally, and the user will be responsible for finding
# and downloading the appropriate version of user-sync.pex.  This is a forewarning, but it *should not* fail to identify supported platforms,
# since this has been tested extensively.  A giveaway will be the lack of text declaring such information at the top of the initial banner.

# We air on the side of safety and compatibility, and try to avoid making assumptions about the host platform if they cannot be determined.

function getHost(){

    # Simply put, converts the input string to lower case.  Useful for comparing names of host platforms.
    function toLower(){
         echo "$1" | awk '{print tolower($0)}'
    }

    # Filters duplicates out of a string.  Useful because some hosts over-report on name and version info, or report in such a way that
    # unneccessary duplicate information ends up being included in the final variables. This method helps to cut down the noise.
    function filterString(){
        echo $1 | awk '{for (i=1;i<=NF;i++) if (!a[$i]++) printf("%s%s",$i,FS)}{printf("\n")}'
    }


    # getParam is the primary search method for getting information out of the host system.  The idea is simple: probe the release information,
    # which is normally stored in /etc/, for keywords pertaining to name and version.  Since all platforms report release with different files and
    # formats, we use cat /etc/*release to grab any and ALL of them (hence the occasional duplication of data).  The regex expressions and subsequent
    # piping defined a search pattern which has been pre-determined by inspection of files by the author to match as many platforms as possible.

    # The general idea is: strip out everything following the keyword of interest in step one, and pipe it through another regex to strip out all the
    # surrounding special characters and spaces on both sides using the second regex.  Finally, filter the remainder for duplication, which will
    # hopefully yield a concise, accurate string in response to the request for said parameter.

    # Here is example raw output from running cat /etc/*release on Ubuntu 16.04.  The keywords of interest are NAME and VERSION, so the getParams method
    # is called as: getParam "NAME" and getParam "VERSION".  If the algorithm works correctly, the output should be:

    # getParam "NAME" -> Ubuntu
    # getParam "VERSION" -> 16.04.3 LTS (Xenial Xerus)

    # DISTRIB_ID=UbuntuSUSE Linux Enterprise Server 11 (x86_64)
    # DISTRIB_RELEASE=16.04VERSION = 11
    # DISTRIB_CODENAME=xenialPATCHLEVEL = 3
    # DISTRIB_DESCRIPTION="Ubuntu 16.04.3 LTS"
    # NAME="Ubuntu"
    # VERSION="16.04.3 LTS (Xenial Xerus)"
    # ID=ubuntu
    # ID_LIKE=debian
    # PRETTY_NAME="Ubuntu 16.04.3 LTS"
    # VERSION_ID="16.04"
    # HOME_URL="http://www.ubuntu.com/"
    # SUPPORT_URL="http://help.ubuntu.com/"
    # BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
    # VERSION_CODENAME=xenial
    # UBUNTU_CODENAME=xenial

    function getParam(){

        params="[@$+&,:;=?#<>\-%!^*_|\`\\\/~\[\]{}\"\']"
        regexA="(?<=\b$1)(\s=|=).*?(?=$)"
        regexB="((?<=($params)|\b))+.*?(?=($params)|$)"

        res=$(cat /etc/*release | grep -Po $regexA | grep -Po $regexB)
        filterString "$res"
    }

    # Before executing any searches, we must determine whether the host is MacOS. This is because MacOS reports host and version
    # information differently from Linux.  To do so, we use sw_vers, which is a MacOS only command that gets a neat output of
    # the requested information.  If the command returns success (exit code 0), we know the host is MacOS!
    [[ -x "$(command -v sw_vers)" ]] && isMacOs=true || isMacOs=false

    # Targeted MacOS specific version of the above getParam algorightms, keyed to match output from sw_vers.
    # Much more concise and straightforward!
    if $isMacOs; then
        fullName=$(sw_vers | grep -Eo '(Mac).*')
        numericalVersion=$(sw_vers | grep -Eo '\d{1,2}(\.).*')
        hostVersion=$(echo $numericalVersion | grep -Eo '^\d{1,2}')

    # If NOT MacOS, use the Linx algorithms as described above.
    else
        fullName=$(getParam "NAME")
        numericalVersion=$(getParam "VERSION")

        # See if $fullName was correctly deduced (assumes byte count less than 3 contains no or incorrect data).
        # If $fullName is wrong, we make a sweeping attempt to get something for it by blindly grabbing the first
        # line of cat /etc/*release.  At least then we can get SOME useful output instead of nothing.
        if [[ $(echo $fullName | wc -c) -lt 3 ]]; then
            fullName=$(getParam "DISTRIB_ID")
        fi

        if [[ $(echo $fullName | wc -c) -lt 3 ]]; then
            fullName=$(cat /etc/*release | grep -Po '\A.*')
            fullName=$(filterString "$fullName")
        fi

        # Same as above: check if $numericalVersion contains information.  If not, we make a blind guess that
        # the $fullName contains the version number within it.  If not, we are out of luck!! :(
        if [[ $(echo $numericalVersion | wc -c) -lt 3 ]]; then
            numericalVersion=$(getParam "DISTRIB_RELEASE")
        fi

        if [[ $(echo $numericalVersion | wc -c) -lt 1 ]]; then
            numericalVersion=$(echo $fullName | grep -Po '\d.+?(?=\s)')
            numericalVersion=$(filterString "$numericalVersion")
        fi


        # The hostVersion is the MAJOR version number only (so for Ubuntu 16.04, hostVersion = 16).  This is helpful
        # in narrowing down platform choices in the host libs without worrying about comparing minor versions, which may
        # or may not be compared easily mathematically (for example, you cannot ask: 13.5.16 > 12.2 because it does not
        # make any mathematical sense, but it's very plain to say that 13 > 12).

        # For the most part, the major version is the significant factor with regards to whether packages or User-Sync will
        # run, whereas minor versions tend not to impact those bigger picture items.

        # NOTE: THIS IS THE HOSTVERSION WHICH WILL BE COMPARED TO minVersion AS SHOWN BELOW! In the case that the hostVersion
        # was note correctly determined but the host name WAS (very unlikely scenario), then the script will assume the minVersion
        # requirements for that platform were not met and will not run. Again, this should probably not happen for any supported
        # platform version.

        hostVersion=$(echo $numericalVersion | grep -Po '(?<!.)\d+(?=(\.|$|\s))')

    fi


    # Here we determine which platform-specific data to used based on the above results.  If the $fullName was not obtained or was
    # incorrect, the default behavior *) is to skip all package installation, don't try to load any resources, and set the hostVersion
    # higher than minVersion so that the script can continue to build the install directory without user-sync.pex

    case $(toLower $fullName) in
        *untu*)
            installString="apt-get --force-yes -y install"
            minVersion="16"
            updateCmd="apt-get update"
            loadResources=loadUbuntuResources
            packageList=(openssl libssl-dev)
        ;;
        *cent*)
            installString="yum -y install"
            minVersion="7"
            updateCmd="yum check-update"
            loadResources=loadCentosResources
            packageList=(openssl)
        ;;
        *fedora*)
            installString="yum -y install"
            minVersion="27"
            updateCmd="yum check-update"
            loadResources=loadFedoraRedhatResources
            packageList=(openssl)
        ;;
        *red*)
            installString="yum -y install"
            minVersion="7"
            updateCmd="yum check-update"
            loadResources=loadFedoraRedhatResources
            packageList=(openssl)
        ;;
        *opensuse*)
            installString="zypper -n install"
            minVersion="42"
            updateCmd="zypper refresh"
            loadResources=loadSuseResources
            packageList=(openssl)
        ;;
        *sles*|*suse*)
            installString="zypper -n install"
            minVersion="12"
            updateCmd="zypper refresh"
            loadResources=loadSuseResources
            packageList=(openssl)
        ;;
        *mac*)
            installString="brew install"
            minVersion="10"
            updateCmd="brew update -n --force"
            loadResources=loadMacOsResources
            packageList=(openssl)
        ;;
        *deb*)
            installString="apt-get --force-yes -y install"
            minVersion="9"
            updateCmd="apt-get update"
            loadResources=loadDebianResources
            packageList=(openssl)
        ;;
        *rasp*)
            installString="apt-get --force-yes -y install"
            minVersion="9"
            updateCmd="apt-get update"
            loadResources=loadRaspbianResources
            packageList=(openssl)
        ;;
        *)
            installString="skip"
            minVersion="0"
            hostVersion="1"
            loadResources=false
        ;;
    esac


   # Here, the external script linux_host_libs is obtained from the git source, run, and removed.  This process loads the correct parameters
   # into the current memory scope for the remainder of the primary script, without introducing the bulk of the libraries as additional
   # inline code.

   wget -q $libURL -O temp.sh
   source temp.sh
   rm temp.sh

#   Used for locally testing the libraries.  Only useful for testing
#     source linux_host_libs_v2.5.sh

}

########################################################################################################################

# All of the above are executed by this psuedo Main method in a proper structered programmatic way, as would be the case were we
# using a programming language.  HOWEVER, a fundamental difference between shell script and standard languages is the notion of
# scoping and memory management.  In bash, we work at a very low level - so while you can observe "Main" as conceptual main class,
# bear in mind that all variables and functions share global scope and there is no sense of encapsulation.  As such, the variables
# in this script are used in a traditionally "blind" sense, where we rely on code executed before they are used to set them.  There
# is no TRUE concept of structure and local scope.

function main(){


    # Determine the host platform and version as described above
    getHost

    # If the platform is MacOS, we must run as a normal user.  Since the default run string for the script on the home page is sudo
    # preceeded, we must intentionally restart the script here using regular user privileges.
    if [[ "$EUID" -eq 0 && $isMacOs == true ]]; then
        printColorOS "Restarting as non root... " yellow
        insStr=$(echo "sh -c 'wget -O ins.sh $instURL &> /dev/null; chmod 777 ins.sh; ./ins.sh  ${installParams[@]};'")
        sudo -u $SUDO_USER bash -c "$insStr"
        exit
    fi

    printUSTBanner

    # If for some reason the script was not run as sudo and the host is not MacOS, we inform the user to re-run as root.
    if [[ "$EUID" -ne 0 && $isMacOs == false ]]; then
        printColorOS "Please re-run with sudo... \n" yellow
        exit
    fi

    # Terminate execution if the host version does not meet the minimum version outlined in getHost
    if [[ $hostVersion -lt $minVersion ]]; then
        printColor "- $fullName $numericalVersion" red
        echo "- Your host version is not supported... "
        exit
    fi

    # Attempt to load the external libraries for the current platform.  If libraries fail to run, or if the host platform is unsupported,
    # we skip all package installation and User-Sync/python versioning.  Otherwise, getUST is set to true, and the logical method
    # choosePythonVersion can be run (which resides in the libraries).  If loadResources returns false, the user is notified but the
    # installer continues as normal anyways.

    if $loadResources; then
        getUST=true
        choosePythonVersion
    else
        printColorOS "Warning! Failed to read platform library, defaulting to generic install..." yellow
        printColorOS "Python will not be installed..." yellow
        installPython=false
        getUST=false
    fi

    # $py3V is defined in host libs, and is set to the appropriate version depending on host and User-Sync versions.  Either 3.5 or 3.6.
    [[ $pyversion == "3" ]] && fullPyVersion=$py3V || fullPyVersion="2.7"

    printf " *** Parameters *** \n\n"
    printf -- "- Python:       "; printColor $fullPyVersion green
    printf -- "- Get Python:   "; printColor $installPython green
    printf -- "- UST Version:  "; printColor $ustVer green
    printf -- "- Offline Mode: "; printColor $offlineMode green


    # Install packages if a package manager has been specified
    [[ $installString != "skip" && $getUST == "true" ]] && getPackages

    # Create the install directory, and then download and extract the UST files into the install directory
    getUSTFiles "$(configureInstallDirectory)"


    # We chmod the install directory, since otherwise one must manually chmod all of the files individually before being permitted to use them.
    # 777 is used as a catch-all approach, and it is recommended that the user reset permissions to 555 once the tool is set up.  This is printed
    # as a suggestion below.

    sudo chmod -R 777 "$USTFolder"
    banner -m "Install Finish" -c cyan
    echo ""

    # If the installWarnings flag was tripped somewhere above, we prompt the user to check for possible errors
    if $installWarnings; then
        printColorOS "Install completed with some warnings (see above)... " yellow
        echo ""
    fi

    # If the --offline mode was called at runtime, the packager is run at this point.  The packager gathers up the install directory and builds
    # a package archive (see the package function above).  The archive can be easily deployed on a target machine that may not have the rights
    # or network access to run this script.
    if $offlineMode; then
        package
    else
        printColorOS "Completed - You can begin to edit configuration files in:"
        printColor "  $USTFolder" green
        echo ""
        printColorOS "Folder permissions set to 777 for configuration file editing..." yellow
        printColorOS "When you are finished, please run chmod -R 555 on the folder to reset permissions!" yellow
        echo ""
    fi

}

# EXECUTE IT ALL !!!!

main


