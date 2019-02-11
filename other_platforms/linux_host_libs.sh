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
# Danimae Janssen 08/2018

# This script is cross-platform compatible, and has should work on the following platforms:
# Ubuntu (12.04+), Fedora (27+), Redhat (7+), CentOS (7+), SLES (12+), OpenSUSE (42+), Mac OSX (10+), Debian (9+), Raspbian (9+)
# User Sync is NOT available on all of the above, but this script aims to provide an
# installation environment for them regardles to simplify the build/implementation.

# The officially supported platforms are Ubuntu, CentOS, and MacOS.  User sync builds
# for CentOS will also run on Fedora/Redhat, but are not officially supported.

# This is the host libraries script which is run alongside the primary install script automaticaly.
# Platform-specific logic is contained within this script, so that the main script can remain effectively
# cross-platform.  The main script can be run without this script completely, and will simple skip the
# download/extraction of the user-sync.pex, along with package installation.  The resulting environment
# will be ready to go, and it is left to the user in that case to get the correct versions of user-sync.pex
# and python.

# The best way to view this script is a collection of implentations of hostInterfaceDefinition, which is a pseudo-interface.
# It is not a true interface, since bash shell does not support such high level structuring, but it is described as such
# here for the purpose of clarity and because it is effectively used as such anyways.

# All off the methods in hostInterfaceDefinition must be implemented for each supported platform verison.  Currently, this
# includes Ubuntu, CentOS, Fedora, SLES, OpenSUSE, Debian, Raspbian, and MacOS. Each implementation is named something like load[Hostname]Resources, and the
# correct implementation is called from the main sript depending on which platform is detected.  For example, if the getHost method
# in the primary script determines that the host platform is Ubuntu, then the loadUbuntuResources implementation will be called.

# The need for such complexity arises from the wide variation in python support across multiple platforms and versions, as well as
# the corresponding requirements for python version for each User-Sync build on each supported platform. The goal of these implementations
# is to design methods that can successfully install the required versions of python if asked (see --install-python), but which will also
# identify and set the versioning to be used in the default case, which is to avoid installing any version of python.

# Thus, the fundamental requirements for the interface to be implemented include methods for installing python 2.7, 3.6, and 3.5 (conditional,
# since only Ubunutu has a UST build with python 3.5).  An installPython3 method is included so that the decision of whether to install
# 3.5 or 3.6 can be made here, instead of in the main script.

# The other requirement is the choosePythonVersion method.  This method contains the logic which defnines which version of python will be used,
# and correspondingly which version of User-Sync must be downloaded to match.  The basic logical assertion is the following:

# Find the highst version of python which is already installed, and see if a User-Sync build exists for that version for the current platform.
# If not, drop to the compatible version of 2.7 and use the 2.7 build of User-Sync instead.   The end-all goal is simply to get the most
# up to date version of python/User-Sync in place without installing additional python packages.

# That said, we do want to allow for the automatic installation of python if the user chooses the --install-python flag.  The reason for
# this extra bit of complication is to ensure that the script can deliver the most up to date possible versions of User-Sync available
# while also upgrading to python 3 for future release compatability.  These issues mostly come to ligth in the Ubuntu platform, across
# which available python versions and user-sync.pex versions are somewhat inconsistent.  Thus, there is a very larget decision making
# process for Ubuntu, whereas the remaining implementations are a bit more straightforward.

# IMPORTANT NOTE #
# every method for installing python (i.e., installPython36) should include a variable called pyCommand.  This is an important string
# because it will be used to test the success of the python installation in the main sript.  This corresponds to the name of the
# the name of the python string command in bash, i.e., python3.6.

function hostInterfaceDefinition(){

    # The interface should deliver the correct links corresponding to builds of User-Sync for python 2 and 3 on the current platform.
    # For good measure, the examples URL are redefined here as well to avoid any possible mixup with the defaults specified in the
    # main script. There should be one entry for every version of UST available with --ust-version.  Currently, there are only two:
    # 2.2.2 and 2.3.  When 2.3 releases, the logic default UST version will be 2.3.

    if [[ $ustVer == "2.3" ]]; then
        void
        # UST Version 2.3 Links
        # USTExamplesURL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/example-configurations.tar.gz"
        # USTPython2URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/user-sync-2.3-centos7-py275.tar.gz"
        # USTPython3URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/user-sync-2.3-centos7-py364.tar.gz"
    else
        void
        # UST Version 2.2.2 Links
        # USTExamplesURL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.1/example-configurations.tar.gz"
        # USTPython2URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-centos7-py275.tar.gz"
        # USTPython3URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-centos7-py362.tar.gz"
    fi

    # Install python 2.7.  On most systems, this simply applies any updates from the repostiory since python 2.7 is generally pre-installed.
    # However, there are some versions (for example: Ubuntu 18) which do not include 2.7 by default.
    function installPython27(){
        pyCommand="2.7"
    }

    # Python 3.5/3.6 is the tricky one.  Support is extremely inconsistent across platforms and host version levels.  For example, on Ubuntu below
    # version 14 it is not possible to install 3.6, but 3.5 is available.  UST releases on 2.7 and 3.6 for version 2.3, so Ubuntu 12 must fall
    # back to 2.7 since 3.6 is not available.
    function installPython36(){
        pyCommand="3.6"
    }

    # Essentially chooses whether 3.5 or 3.6 needs to be installed.  This is determined based on python support for the host and the
    # requested UST version.
    function installPython3(){
        void
    }

    # The effective brains of the operation.  This method should decide which version of python/UST are needed for the most compatible and up to
    # date install.  The Ubunutu implementation of this method is significantly larger than for the other platforms as a result of its widely
    # ranging support and python version changes in UST releases between 2.2.2 and 2.3.
    function choosePythonVersion(){
        void
    }

    # Returns a 0 to indicate to the primary script that the implementation has run succesuffly.
    return 0
}



# Determines whether python should be installed.  Python will NEVER be installed if the --offline flag is set, since the goal
# is an archive for another machine. offlinePyUpdate is simply a copy of the original value of installPython, since installPython
# must be switched off but the original data is needed for versioning.  The main reason for this is because one may wish to specify
# --install-python to force a more updated version of UST for another system on which they plan to deploy the arhive, but do not
# want to actually install python on the current host.

# This effectively lets us pass versioning decisions on to another host without affecting our current machine. Bearing in mind, of course,
# that the target host must then have a python version to match your target UST version.  This allows us to retain our ability to specify
# precisely our desired outcome even with a packaged deployment.

if $offlineMode ; then
    offlinePyUpdate=$installPython;
    installPython=false ;
else offlinePyUpdate=false
fi

# Checks whether a requested python version is installed by comparing command line output from python -V to our desired result.  This lets
# us know if we can safely download UST fro the requested version without needing to isntall anyhing.
function isPyVersionInstalled(){

    desiredVersion=$1
    testPyVersion=($(python$desiredVersion -V 2>&1))

    effVersion=$(echo ${testPyVersion[1]} | cut -c1-3)
    [[ $effVersion == $desiredVersion ]] && echo true || echo false

}

# The first real implementation of the interface above is for Ubuntu, and the only one which warrants any extra discussion.

function loadUbuntuResources(){

    # Note that version 2.3 releases on python 3.6, but 2.2.2 releases on 3.5.  This simple difference adds another level olsf
    # dimensionality and complexity to the decision space.
    if [[ $ustVer == "2.3" ]]; then
        # UST Version 2.3 Links
        USTPython2URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/user-sync-v2.3-ubuntu1604-py2712.tar.gz"
        USTPython3URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/user-sync-v2.3-ubuntu1604-py365.tar.gz"
    else
        # UST Version 2.2.2 Links
        USTPython2URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-ubuntu1604-py2712.tar.gz"
        USTPython3URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-ubuntu1604-py352.tar.gz"
    fi

    # Unique to this implementation (NOT part of the required interface). This allows a target version of Ubuntu to be selected for offline mode.
    # This is important, since the version specific variation in Ubuntu is extreme, along with some conditional behavior that has been determined
    # by inspection of different version installs by the author.
    function verifyHostVersion(){



        # if $offlineMode; then

        #     log_info " --- OFFLINE MODE --- " 
        #     echo ""
        #     echo " Please choose your target Ubunutu Version: "
        #     echo ""
        #     echo " 1. 16.04 - Xenial Xerus"
        #     echo " 2. 17.04 - Zesty Zapus"
        #     echo " 3. 18.04 - Bionic Beaver"
        #     echo ""

        #     while [[ 1 -eq 1 ]]; do
        #         read -p "$ " choice
        #         case $choice in
        #             1) numericalVersion="16.04"; break;;
        #             2) numericalVersion="17.04"; break;;
        #             3) numericalVersion="18.04"; break;;
        #             *) ;;
        #         esac
        #     done

        #     # Get the MAJOR version only
        #     hostVersion=$(echo $numericalVersion | cut -c1-2)

        # fi

        # Warn the user that non LTS versions (odd numbers) are not supported due to unreliable repository dependencies.
        # The script will run anyway, and in most cases can finish successfully.
        if (( $hostVersion%2 != 0 )); then
            echo ""
            log_info "Only LTS versions are officially supported.  Extra configuration may be required... " 
        fi

        # Defines versions where python 2.7 does NOT come with but MUST be installed to use the selected UST versions.
        # This only applies to 17 and 18+, since 2.7 comes by default on previous versions.
        py27Needed=false
        case $hostVersion in
            17) if [[ $ustVer == "2.3" ]]; then py27Needed=true; fi ;;
            18) if [[ $ustVer == "2.2.2" ]]; then py27Needed=true; fi ;;
             *) ;;
        esac

        [[ $(isPyVersionInstalled "2.7") == true ]] && py27Needed=false;

        # Ask the user for permission to install python 2.7, since there is no way to satisfy the specified requirements without
        # installing python 2.7.
        if $py27Needed && ! $installPython; then
            log_info "Warning: The selected version of UST cannot run your version of Ubuntu unless python 2.7 is installed. " 
            log_info "Would you like to install python 2.7?\n" 
            while [[ 1 -eq 1 ]]; do
                read -p "- (y/n)$ " choice
                case $choice in
                    "y") installPython=true; break;;
                    "n") break;;
                    *) ;;
                esac
            done
        fi

        echo ""

    }

    # Extra repos needed for python 3 install on some Ubuntu versions
    function py3prereqs(){
        $installString software-properties-common &> /dev/null
        $installString python-software-properties &> /dev/null
        $installString python3-software-properties &> /dev/null
    }

    # Special case repository swap for Ubuntu 17
    function switchMissingRepos(){
        sudo sed -i -e 's/archive.ubuntu.com\|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list
        $updateCmd  &> /dev/null
    }

    function installPython27(){
        if [[ $hostVersion == "17" ]]; then switchMissingRepos; fi
        log_info "Installing Python 2.7..."
        $installString python2.7&> /dev/null
        pyCommand="python2.7"
    }


    # Adding python 3.5 to Ubuntu - requires deadsnakes external repository in some cases
    # (this is a catch-all)
    function installPython35(){

        py3prereqs
        log_info "Adding ppa:fkrull/deadsnakes..."
        add-apt-repository ppa:fkrull/deadsnakes -y &> /dev/null

        log_info "Updating repositories..."
        $updateCmd &> /dev/null

        log_info "Installing Python 3.5..."
        $installString python3.5&> /dev/null
        add-apt-repository -remove ppa:fkrull/deadsnakes -y  &> /dev/null
        pyCommand="python3.5"
    }

    # Python 3.6 requires external repostories for Ubuntu < 18.
    function installPython36(){

        py3prereqs
        if [[ $hostVersion -lt 18 ]]; then
            log_info "Adding ppa:jonathonf/python-3.6..."
            add-apt-repository ppa:jonathonf/python-3.6 -y  &> /dev/null
            log_info "Updating repositories..."
            $updateCmd  &> /dev/null
        fi

        log_info "Installing Python 3.6..."
        $installString python3.6 &> /dev/null
        add-apt-repository -remove ppa:jonathonf/python-3.6 -y  &> /dev/null;

        pyCommand="python3.6"

    }

    # Chooses whether to use 3.5 or 3.6 based on UST version choice
    function installPython3(){
        [[ $ustVer == "2.3" ]] && installPython36 || installPython35
    }

    # At long last, the decision making chunk.  The explanation above describes the purpose
    # of choosePythonVersion, but some of the logic is explained here.

    function choosePythonVersion(){

        # Since user-sync is comiled with python 3.6 for 2.3, and 2.2.2 for 3.5, this
        # distinction is necessary to grab the correct version.
        [[ $ustVer == "2.3" ]] && py3V="3.6" || py3V="3.5"

        # If the above version of python 3 is installed already, set pyversion=3, otherwise
        # use compatability setting take the python 2 version.
        $(isPyVersionInstalled $py3V) && pyversion=3 || pyversion=2

        # Default python versions for Ubuntu.  These are determined by inspection of default
        # Ubuntu configurations on every platform from 12-18 by the author.  These server as
        # a guide for offlineMode, since it must know the default version of a target host
        # if it is to select the correct user-sync.pex.

        if $offlineMode && ! $installPython; then
            if [[ $ustVer == "2.3" ]]; then
                # Must support python 3.6 & or version 2.7
                case $hostVersion in
                    "18")pyversion=3;;
                       *)pyversion=2;;
                esac
            else
                # Must support python 3.5 or 2.7.  For example, 16 & 17 come with 3.5 by default, but
                # all other versions must fall back to 2.7 since UST 2.2.2 is not available with 3.6.
                case $hostVersion in
                    "16")pyversion=3;;
                    "17")pyversion=3;;
                       *)pyversion=2;;
                esac
            fi
        fi


        # If we are installing python on the current host, or plan to install it on the target host, then
        # this block wil run to set the correct versions depending on whether 2.3 or 2.2.2 was selected for
        # UST version.  This table was carefully constructed by thorough testing on each platform version.
        # In a nutshell, the pyversion assigned here is the highest possible version to support the selected
        # UST version on any platform number.

        if $installPython || $offlinePyUpdate; then
            if [[ $ustVer == "2.3" ]]; then
                # Must support python 3.6
                case $hostVersion in
                    "16")pyversion=3;;
                    "17")pyversion=2;;
                    "18")pyversion=3;;
                       *)pyversion=2;;
                esac
            else
                # Must support python 3.5
                case $hostVersion in
                    "16")pyversion=3;;
                    "17")pyversion=3;;
                    "18")pyversion=2;;
                       *)pyversion=2;;
                esac
            fi
        fi
    }

    # Just calls the above method, which can override the results of the above conditionals for the specific cases
    # as described above.
    verifyHostVersion

    # Return 0 for a successful call!
    return 0

}


function loadCentosResources(){

    if [[ $ustVer == "2.3" ]]; then
        # UST Version 2.3 Links
        USTPython2URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/user-sync-v2.3-centos7-py275.tar.gz"
        USTPython3URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/user-sync-v2.3-centos7-py365.tar.gz"
    else
        # UST Version 2.2.2 Links
        USTPython2URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-centos7-py275.tar.gz"
        USTPython3URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-centos7-py362.tar.gz"
    fi

    function installPython27(){
        log_info "Installing Python 2.7..."
        $installString python &> /dev/null
        pyCommand="python2.7"
    }

    function installPython36(){
        log_info "Adding https://centos7.iuscommunity.org/ius-release.rpm..."
        $installString https://centos7.iuscommunity.org/ius-release.rpm &> /dev/null

        log_info "Updating repositories..."
        $updateCmd &> /dev/null

        log_info "Installing Python 3.6..."
        $installString python36u &> /dev/null
        pyCommand="python3.6"
    }

    function installPython3(){
        installPython36
    }

    function choosePythonVersion(){
        py3V="3.6"
        $(isPyVersionInstalled $py3V) && pyversion=3 || pyversion=2
        if $installPython || $offlinePyUpdate ; then pyversion=3; fi
        if ! $offlinePyUpdate && $offlineMode ; then pyversion=2; fi
    }

    return 0
}

function loadFedoraRedhatResources(){

    if [[ $ustVer == "2.3" ]]; then
        # UST Version 2.3 Links
        USTPython2URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/user-sync-v2.3-centos7-py275.tar.gz"
        USTPython3URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/user-sync-v2.3-centos7-py365.tar.gz"
    else
        # UST Version 2.2.2 Links
        USTPython2URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-centos7-py275.tar.gz"
        USTPython3URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-centos7-py362.tar.gz"
    fi

    function installPython27(){
        log_info "Installing Python 2.7..."
        $installString python27 &> /dev/null
        pyCommand="python2.7"
    }

    function installPython36(){
        log_info "Installing Python 3.6..."
        $installString python36 &> /dev/null
        pyCommand="python3.6"
    }

    function installPython3(){
        installPython36
    }

    function choosePythonVersion(){
        py3V="3.6"
        $(isPyVersionInstalled $py3V) && pyversion=3 || pyversion=2
        if $installPython || $offlinePyUpdate ; then pyversion=3; fi
        if ! $offlinePyUpdate && $offlineMode ; then pyversion=2; fi
    }

    return 0
}

function loadRaspbianResources(){

    if [[ $ustVer == "2.3" ]]; then
        # UST Version 2.3 Links
        USTPython2URL="https://github.com/janssenda-adobe/ust-unofficial/raw/master/user-sync-v2.3-rasp-9-py2713.tar.gz"
        USTPython3URL="https://github.com/janssenda-adobe/ust-unofficial/raw/master/user-sync-v2.3-rasp-9-py353.tar.gz"
    else
        # UST Version 2.2.2 Links
        USTPython2URL="https://github.com/janssenda-adobe/ust-unofficial/raw/master/user-sync-v2.2.2-rasp-9-py2713.tar.gz"
        USTPython3URL="https://github.com/janssenda-adobe/ust-unofficial/raw/master/user-sync-v2.2.2-rasp-9-py353.tar.gz"
    fi

    function installPython27(){
        log_info "Installing Python 2.7..."
        $installString python2.7 &> /dev/null
        pyCommand="python2.7"
    }

    function installPython35(){
        log_info "Installing Python 3.5..."
        $installString python3.5 &> /dev/null
        pyCommand="python3.5"
    }

    function installPython3(){
        installPython35
    }

    function choosePythonVersion(){
        py3V="3.5"
        $(isPyVersionInstalled $py3V) && pyversion=3 || pyversion=2
        if $installPython || $offlinePyUpdate ; then pyversion=3; fi
        if ! $offlinePyUpdate && $offlineMode ; then pyversion=2; fi
    }

    return 0
}