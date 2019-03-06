# Copyright (c) 2019 Adobe Inc.  All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import importlib
import subprocess
import os
import sys

checked_modules = ["binascii", "six", "cryptography", "pip"]
needed_modules = []

print("\nUser Sync Tool Installation")
print("(C) Adobe Systems Inc, 2009")
print("https://github.com/adobe-apiplatform/user-sync.py")
print("\nRunning pre-install checks...")

if sys.version_info.major + sys.version_info.minor != 9:
    print("Unsupported Python version - please re-run with 2.7 or 3.6")
    exit()

if os.geteuid() != 0:
    print("You must run this script as root: sudo python install_ust.py...")
  #  exit()

for m in checked_modules:
    try:
        importlib.import_module(m)
    except ImportError:
        needed_modules.append(m)

if "pip" in needed_modules and len(needed_modules) > 1:
    print("Installing dependencies: pip")
    subprocess.check_output('curl https://bootstrap.pypa.io/get-pip.py | sudo python -', shell=True)
    needed_modules.remove("pip")

for m in needed_modules:
    print("Installing required module: " + m)
    subprocess.check_output('sudo pip install ' + m, shell=True)

for m in needed_modules:
    try:
        importlib.import_module(m)
    except ImportError:
        print("Setup failed to install module: " + m + " and must stop.  "
                        "Please re-run setup after installing the missing dependencies")


import datetime
import logging
import platform
import re
import shutil
import tarfile
import binascii
import six
from argparse import ArgumentParser
from subprocess import Popen, PIPE, STDOUT
from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID
from six.moves.urllib.request import urlretrieve

parser = ArgumentParser()
parser.add_argument('-d', '--debug', action='store_true')
args = parser.parse_args()
console_level = logging.DEBUG if args.debug else logging.INFO

# Platform specific scripts to be run during install
scripts = {
    'ubuntu': ['sudo apt-get update',
               'sudo apt-get -y install openssl',
               'sudo apt-get -y install libssl-dev'],

    'centos': ['yum check-update',
               'sudo yum -y install openssl'],
}

# Intro banner!
intro = [
    "",
    "Adobe Systems, Inc - 2019",
    "=========================================================",
    "{0} {1} - {2}",
    "",
    "         _   _                 ___",
    "        | | | |___ ___ _ _    / __|_  _ _ _  __",
    "        | |_| (_-</ -_) '_|   \__ \ || | ' \/ _|",
    "         \___//__/\___|_|     |___/\_, |_||_\__|",
    "                                   |__/",
    "",
    "Linux Quick Install for UST {3} ",
    "https://github.com/adobe/UST-Install-Scripts",
    "https://github.com/adobe-apiplatform/user-sync.py",
    "=========================================================",
    ""
]



print("Finished pre-install tasks, beginning process... \n")


class main:
    """
    Main class.  Gathers installation information, and then executes the run() method to kick off process.
    """

    def __init__(self):

        installPath = "adobe-user-sync-tool"
        host = platform.linux_distribution()

        self.loggingContext = \
            LoggingContext(console_level=console_level, descriptor=("{0} {1}").format(host[0], host[1]))

        # DI
        self.web = web_util(self.loggingContext)
        self.bash = bash_util(self.loggingContext)
        self.ssl_gen = ssl_cert_generator(self.loggingContext, os.path.abspath(installPath))

        # Prep
        self.logger = self.loggingContext.getLogger("main")
        self.config = {'platform': {}, 'resources': {}}
        self.config['platform']['host_platform'] = host[0]
        self.config['platform']['host_name'] = host[2]
        self.config['platform']['host_version'] = host[1]
        self.config['platform']['major_version'] = host[1][:2]
        self.config['platform']['host_key'] = self.get_current_host(host[0])

        self.config['ust_directory'] = os.path.abspath(installPath)
        self.config['python_version'] = ("{0}.{1}").format(sys.version_info.major, sys.version_info.minor)
        self.config['custom_script'] = scripts[self.config['platform']['host_key']]

        # Finish building resources by fetching the API information from GitHub
        self.web.fetch_resources(self.config)

    # Determine which platform the script is running on
    def get_current_host(self, host):
        if (bool(re.search("(ubuntu)", host, re.I))):
            return "ubuntu"
        elif (bool(re.search("(cent)|(fedora)|(red)", host, re.I))):
            return "centos"
        else:
            self.logger.critical("Unknown or unsupported platform. Windows, Ubuntu or CentOS/RedHat/Fedora "
                                 "and Python 2.7 or 3.6 are required to use the User Sync Tool.  For more information,"
                                 "visit https://github.com/adobe-apiplatform/user-sync.py")

    def run(self):
        """Top level entry point.
        Install process begins here
        Version check -> UST download -> dependency installation -> SSL creation
        """
        self.show_intro()
        self.install_ust()
        self.bash.custom_script(self.config['custom_script'])
        self.ssl_gen.generate()

        self.logger.info("")
        self.logger.info("Installation complete!  Files are located in: " + self.config['ust_directory'])
        self.logger.info("Please follow the next steps for configuring the sync tool.")
        self.logger.info("For setup details, see: https://helpx.adobe.com/enterprise/using/user-sync.html")
        self.logger.info("Documentation: https://adobe-apiplatform.github.io/user-sync.py/en/success-guide/")
        self.logger.info("")
        self.logger.info("")

    # Creates a shell script to execute specified command.  For run_ust and ssl scripts.
    def create_shell(self, filename, command):
        filename = os.path.abspath(filename)
        self.logger.info("Create: " + filename)
        text_file = open(filename, "w")
        text_file.write(command)
        text_file.close()

    def install_ust(self):
        """
        Process for installing UST.  This amounts to downloading UST itself, the examples file, and
        extracting them all into the installation directory.  The execution shell scripts are also generated
        here along with the SSL regeneration script.
        :return:
        """

        self.logger.info("Beginning UST installation")

        ust_dir = self.config['ust_directory']
        conf_dir = os.path.abspath(os.path.join(ust_dir, 'examples', 'config files - basic'))

        self.logger.info("Creating directory " + ust_dir)
        shutil.rmtree(ust_dir, ignore_errors=True)
        os.mkdir(ust_dir)

        # Download UST and examples
        self.web.download(self.config['resources']['examples_url'], ust_dir)
        self.web.download(self.config['resources']['ust_url'], ust_dir)

        self.logger.info("Creating configuration files... ")
        self.copy_to(os.path.join(conf_dir, "connector-ldap.yml"), ust_dir)
        self.copy_to(os.path.join(conf_dir, "connector-umapi.yml"), ust_dir)
        self.copy_to(os.path.join(conf_dir, "user-sync-config.yml"), ust_dir)

        self.logger.info("Creating shell scripts... ")
        self.create_shell(os.path.join(ust_dir, "run-user-sync-test.sh"),
                          "#!/usr/bin/env bash\n./user-sync --users mapped --process-groups -t")
        self.create_shell(os.path.join(ust_dir, "run-user-sync-live.sh"),
                          "#!/usr/bin/env bash\n./user-sync --users mapped --process-groups")
        self.create_shell(os.path.join(ust_dir, "sslCertGen.sh"),
                          "#!/usr/bin/env bash\nopenssl req -x509 -sha256 -nodes -days 9125 "
                          "-newkey rsa:2048 -keyout private.key -out certificate_pub.crt")

        # Set folder permissions to allow editing of .yml files
        self.logger.info("Setting folder permissions to 777... ")
        self.bash.shell("sudo chmod 777 -R " + ust_dir)
        self.logger.info("UST installation finished... ")

    # Logged file copier
    def copy_to(self, src, dest):
        src = os.path.abspath(src)
        dest = os.path.abspath(dest)
        self.logger.info("Copy " + src + " to " + dest)
        shutil.copy(src, dest)

    # Prints a pretty UST banner!
    def show_intro(self):
        for s in intro:
            self.logger.info(
                str.format(s,
                           self.config['platform']['host_platform'],
                           self.config['platform']['host_version'],
                           self.config['platform']['host_name'],
                           self.config['resources']['ust_version']))

class ssl_cert_generator:
    """
    SSL Certificate / Keypair generator

    Generates a certificate and keypair to use with the Adobe UMAPI:  https://console.adobe.io
    The type is X509 with RSA 2048 private key.  Creates certificate_pub.crt and private.key
    in the installation folder
    """

    def __init__(self, loggingContext, outputPath):
        """
        :param loggingContext:
        :param config: inherit top level configuration for directories
        """
        self.logger = loggingContext.getLogger("sslGen")
        self.outputPath= outputPath

        # Key reference for subject field names
        self.keys = {
            'cc': 'Country Code',
            'st': 'State',
            'ct': 'City',
            'or': 'Organization',
            'cn': 'Common Name'}

    # Return a random hex value of specified length
    def rnd(self, size=6):
        return str.upper(str(binascii.b2a_hex(os.urandom(size)).decode()))

    # Get user input for all fields in subject
    # User default value if empty string is input
    def collect_fields(self, sub):
        tsub = {}
        self.logger.info("")
        for k in self.keys:
            tsub[k] = self.logger.input(self.logger.pad(self.keys[k] + " [" + sub[k] + "]", 30) + ": ")
            if str.strip(tsub[k]) != "": sub[k] = tsub[k]

        sub['cc'] = str.upper(sub['cc'])
        return sub

    def validate_fields(self, subject):
        """
        Validates subject fields - only letters for country code, limited ASCII set for other fields
        :param subject: certificate subject dictionary (ref self.keys)
        :return: boolean - valid or not
        """

        valid = True
        if len(subject['cc']) != 2:
            valid = False
            self.logger.info("Country code must be exactly 2 characters long...")
        if re.search('[^A-Za-z]', subject['cc']):
            valid = False
            self.logger.info("Only letters allowed in country code " + subject['cc'] + ", press re-enter...")
        for k in subject:
            if re.search('[^A-Za-z0-9@._]', subject[k]):
                valid = False
                self.logger.info("Illegal character in " + self.keys[k] + ": " + subject[k] + ", press re-enter...")
        return valid

    def get_subject(self):
        """
        Call field collection and validate input
        :return: X509 subject
        """

        # Randomize initial subject
        subject = {}
        for k in self.keys:
            subject[k] = self.rnd(1) if k == "cc" else self.rnd()
        subject["cc"] = "US"

        # Wait for user-approved valid input
        while True:
            subject = self.collect_fields(subject)
            self.logger.info("")
            for k in subject:
                self.logger.info(self.logger.pad(str(self.keys[k])) + ": " + subject[k])
            self.logger.info("")

            if self.validate_fields(subject):
                if self.logger.question("Is this information correct (y/n) [y]?  "): break

        # Build X509 - note: six.ucode formatting is required
        return x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, six.u(subject['cc'])),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, six.u(subject['st'])),
            x509.NameAttribute(NameOID.LOCALITY_NAME, six.u(subject['ct'])),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, six.u(subject['or'])),
            x509.NameAttribute(NameOID.COMMON_NAME, six.u(subject['cn'])),
        ])

    # Return a certificate based on private key and subject
    def get_certificate(self, key):
        subject = issuer = self.get_subject()
        return x509.CertificateBuilder() \
            .subject_name(subject) \
            .issuer_name(issuer) \
            .public_key(key.public_key()) \
            .serial_number(12345) \
            .not_valid_before(datetime.datetime.utcnow()) \
            .not_valid_after(datetime.datetime.utcnow() + datetime.timedelta(days=10)) \
            .sign(key, hashes.SHA256(), default_backend())

    # Generate a random RSA 2048 key
    def get_key(self):
        self.logger.info("Generating private key (2048)")
        return rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
            backend=default_backend())

    def generate(self):
        """
        Certificate generation entry point.  Creates a key, certificate, and then writes files to
        certificate_pub.crt and private.key in the installation path
        :return:
        """
        self.logger.info("")
        self.logger.info("Begin SSL certificate generation...")
        self.logger.info("Enter your information to create a self-signed certificate/key pair.")
        self.logger.info("This will be used for authentication with the UMAPI at https://console.adobe.io.")
        self.logger.info("You can also press enter to use the randomly generated default values.")

        key = self.get_key()
        cert = self.get_certificate(key)

        certfile = self.outputPath + os.sep + "certificate_pub.crt"
        keyfile = self.outputPath + os.sep + "private.key"

        # Write private key
        self.logger.info("Writing private key to file: " + keyfile)
        with open(keyfile, "wb") as f:
            f.write(key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.TraditionalOpenSSL,
                encryption_algorithm=serialization.NoEncryption()
            ))

        # Write public cert
        self.logger.info("Writing public cert to file: " + certfile)
        with open(certfile, "wb") as f:
            f.write(cert.public_bytes(serialization.Encoding.PEM))

        self.logger.info("SSL certificate generation complete!")


class web_util:
    """
    Handles web and web-related requests using urrlib from the standard lib.  Includes file downloads
    and dynamic resource fetching from the GitHub API in order to maintain the latest verison of UST.
    Uses a generic GitHub token for stable API access
    """

    def __init__(self, loggingContext):
        self.logger = loggingContext.getLogger("webUtil")

    def download(self, url, dir):
        """
        Downloads the specfied URL, and puts it in dir.  If the file is a tar.gz, it is extracted
        and the original file is removed
        :param url: URL for target resource
        :param dir: Target directory for file
        :return:
        """

        filename = str(url.rpartition('/')[2])
        filepath = dir + os.sep + filename
        self.logger.info("Downloading " + filename + " from " + url)

        # Download
        urlretrieve(url, filepath)

        # Extract if needed
        if (filepath.endswith(".tar.gz")):
            tarfile.open(filepath).extractall(path=dir)
            os.remove(filepath)

    def fetch_resources(self, config):
        """
        Fetches the current configuration from the UST repository using the GitHub API, and parses the JSON for
        the appropriate URL's.  Sets the corresponding keys in config for later download.
        :param config: configuration from main class
        :return:
        """

        # Hardcoded - temporarily until API integration
        config['resources']['ust_version'] = "2.4"
        config['resources'][
            'examples_url'] = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.4/examples.tar.gz"
        config['resources'][
            'ust_url'] = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.4/user-sync-v2.4-"

        isPy3 = config['python_version'] == "3.6"

        if config['platform']['host_key'] == "ubuntu":
            config['resources']['ust_url'] += "ubuntu1604-py367.tar.gz" if isPy3 else "ubuntu1604-py2715.tar.gz"

        elif config['platform']['host_key'] == "centos":
            config['resources']['ust_url'] += "centos7-py367.tar.gz" if isPy3 else "centos7-py275.tar.gz"


class bash_util:
    """
    Methods for working with the command line.  Includes shell execution, shellscript creation and
    dependency management
    """
    def __init__(self, loggingContext):
        self.logger = loggingContext.getLogger("bash")

    # Starts a shell process.  Inserts "y" key after command  to avoid hangups for shell prompts
    def shell(self, cmd):
        p = Popen(cmd.split(" "),  stdout=PIPE, stdin=PIPE, stderr=STDOUT)
        for line in iter(p.stdout.readline, b''):
           #$ p.stdin.write(b'y\n')
            self.logger.debug(line.decode().rstrip('\n'))

    # Runs a shell command, but captures the output
    def shell_out(self, cmd):
        out = subprocess.check_output(cmd + " 2>&1", shell=True)
        self.logger.debug(out.decode().rstrip('\n'))
        return out

    # Checks for presence of python - try-catch is necessare, since shell command will throw an error if not present
    def is_pyver_installed(self, major):
        try:
            var = re.search(major, self.shell_out("python" + str(major) + " -V").decode()).group()
            return True
        except:
            return False

    # Determines installed python version and terminates if neither 2.7 nor 3.6 are found
    def get_python_version(self):
        vers = str(sys.version_info.major) + "." + str(sys.version_info.minor)
        if self.is_pyver_installed("3.6"):
            return "3.6"
        elif self.is_pyver_installed("2.7"):
            return "2.7"

        self.logger.critical("Your system does not meet the minimum requirements for UST.  Please install"
                             " Python 2.7 or 3.6 and re-run the setup (3.7 will NOT work).")
        exit()

    # Uses the install command after updating (apt-get update, apt-get install) to enable openSSL for future cert
    # generation if needed.
    def custom_script(self, scripts):
        self.logger.info("Executing custom scripts... ")
        for c in scripts:
            self.logger.info(c)
            self.shell(c)

class LoggingContext:
    """
    Specialized logging class meant to capture log output as well as output from STDOUT - this is needed
    to log bash output.  Includes a streamhandler for bash output, and logs to console and file with
    different log levels.  The commandline flag -d enables debug mode for console.
    """

    def __init__(self, console_level=logging.DEBUG, descriptor=""):
        """
        Set log level and descriptor
        :param console_level: debug if not specified
        :param descriptor: description for the log output - platform name and version by default
        """

        format_string = "%(asctime)s " + descriptor + "  [%(name)-7.7s]  [%(levelname)-6.6s]  :::  %(message)s"
        self.formatter = logging.Formatter(format_string, "%Y-%m-%d %H:%M:%S")
        self.original_stdout = sys.stdout

        # Assign extended logging class to provide additional log functionality
        logging.setLoggerClass(self.InputLogger)

        # Root logger - set to debug to capture all output
        logger = logging.getLogger('')
        logger.setLevel(logging.DEBUG)

        # File handler
        f_handler = logging.FileHandler('ust_install.log', 'w')
        f_handler.setFormatter(self.formatter)
        f_handler.setLevel(logging.DEBUG)

        # Console handler
        ch = logging.StreamHandler()
        ch.setLevel(console_level)
        ch.setFormatter(self.formatter)

        logger.addHandler(ch)
        logger.addHandler(f_handler)

        # Redirect STDOUT and STDERR to the log stream
        sys.stderr = sys.stdout = self.StreamLogger(logging.getLogger("main"), logging.INFO)

    # Return new logger with properties set for extension
    def getLogger(self, name):
        logger = logging.getLogger(name)
        logger.formatter = self.formatter
        logger.original_stdout = self.original_stdout
        return logger

    class InputLogger(logging.Logger):
        """
        Custom logging class.  Since install script requires user interaction, the default logger
        is extended to include supporting functionality while maintaining the look and feel of the
        logger.  This includes getting user input in the form of a value as well as prompting
        for a y/n question.
        """

        def __init__(self, name):
            logging.Logger.__init__(self, name)
            self.logger = super(LoggingContext.InputLogger, self)
            self.original_stdout = sys.stdout
            self.formatter = None
            self.name = name

        # Ask a question, restricting response to "y", "n" or enter (default to "y")
        def question(self, message):
            while True:
                ans = str(self.input(message)).lower()
                if (ans != "y" and ans != "n" and ans != ""):
                    self.logger.info("Please enter (y/n)...")
                else:
                    return False if ans == "n" else True

        # Get user input.  This requires special steps in order to preserve lines.  To accomplish this,
        # STDOUT is set to normal, and a log string is captured as the message.  Used with STDIN, the appearance
        # is maintained and a value can be captured.
        def input(self, message):
            current_stdout = sys.stdout
            sys.stdout = self.original_stdout
            sys.stdout.write(self.getLogString(message + " ")),
            sys.stdout.flush()
            r = sys.stdin.readline().rstrip()
            sys.stdout = current_stdout
            return r

        # Creates a log string of the form log formatter, which can be printed alongside an input prompt.
        def getLogString(self, msg):
            r = logging.LogRecord(self.name, logging.INFO, "", 1, msg, None, None)
            return self.formatter.format(r)

        # Padding function for improving visual appearance of certificate subject fields
        def pad(self, string, padlen=15):
            size = (padlen - len(string))
            return string + " " * max(size, 0)

    # Streamhandler for STDOUT and STDERR output
    class StreamLogger(object):
        def __init__(self, logger, log_level):
            self.logger = logger
            self.log_level = log_level

        def write(self, message):
            for line in message.rstrip().splitlines():
                self.logger.log(self.log_level, line.rstrip())

        def flush(self):
            pass


main().run()
