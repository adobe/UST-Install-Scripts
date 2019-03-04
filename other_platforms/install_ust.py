import datetime
import logging
import os
import platform
import re
import shutil
import subprocess
import sys
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

try:
    from urllib.request import urlretrieve
except ImportError:
    from urllib import urlretrieve

parser = ArgumentParser()
parser.add_argument('-d','--debug', action='store_true')
args = parser.parse_args()
console_level = logging.DEBUG if args.debug else logging.INFO

meta = {
    'ubuntu': {
        'update_cmd': 'sudo apt-get update',
        'python_req': {'16': '2.7', '17': '2.7','18': '3.6' },
        'openssl_script': ['sudo apt-get -y install openssl',
                           'sudo apt-get -y install libssl-dev'],
    },
    'centos': {
        'update_cmd': 'sudo apt-get update',
        'python_req': {'16': '2.7', '17': '2.7','18': '3.6' },
        'openssl_script': ['sudo apt-get -y install openssl',
                           'sudo apt-get -y install libssl-dev'],
    }
}

intro = [
    "",
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
    "=========================================================",
    ""
]


class ssl_cert_generator:

    def __init__(self, loggingContext):
        self.logger = loggingContext.getLogger("ssl")
        self.keys = {
            'cc': 'Country Code',
            'st': 'State',
            'ct': 'City',
            'or': 'Organization',
            'cn': 'Common Name'}

    def rnd(self, size=6):
        return binascii.b2a_hex(os.urandom(size))

    def collect_fields(self, sub):

        tsub = {}
        self.logger.info("")

        for k in self.keys:
            tsub[k] = self.logger.input(self.logger.pad(self.keys[k] + " [" + sub[k] + "]", 30) + ": ")
            if str.strip(tsub[k]) != "": sub[k] = tsub[k]

        sub["cc"] = sub["cc"][0:2]
        return sub

    def get_subject(self):

        subject = {}
        for k in self.keys:
            subject[k] = self.rnd(1) if k == "cc" else self.rnd()

        while True:
            subject = self.collect_fields(subject)
            self.logger.info("")
            for k in subject:
                self.logger.info(self.logger.pad(str(self.keys[k])) + ": " + subject[k])

            self.logger.info("")
            if self.logger.question("Is this information correct (y/n) [y]?  "): break

        return x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, six.u(subject['cc'])),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, six.u(subject['st'])),
            x509.NameAttribute(NameOID.LOCALITY_NAME, six.u(subject['ct'])),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, six.u(subject['or'])),
            x509.NameAttribute(NameOID.COMMON_NAME, six.u(subject['cn'])),
        ])

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

    def get_key(self):
        return rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
            backend=default_backend())

    def generate(self):
        self.logger.info("Begin SSL certificate generation...")

        key = self.get_key()
        cert = self.get_certificate(key)

        with open("private.key", "wb") as f:
            f.write(key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.TraditionalOpenSSL,
                encryption_algorithm=serialization.NoEncryption()
            ))

        with open("certificate_pub.crt", "wb") as f:
            f.write(cert.public_bytes(serialization.Encoding.PEM))


class web_util:

    def __init__(self, loggingContext):
        self.logger = loggingContext.getLogger("web")

    def download(self, url, dir):

        filename = dir + os.sep + str(url.rpartition('/')[2])
        urlretrieve(url, filename)

        if (filename.endswith(".tar.gz")):
            tarfile.open(filename).extractall(path=dir)
            os.remove(filename)

    def fetch_resources(self, config):

        config['resources']['ust_version'] = "2.4"
        config['resources'][
            'examples_url'] = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.4/examples.tar.gz"
        config['resources'][
            'ust_url'] = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.4/user-sync-v2.4-"

        isPy3 = config['python_version'].startswith("3")

        if config['platform']['host_key'] == "ubuntu":
            config['resources']['ust_url'] += "ubuntu1604-py367.tar.gz" if isPy3 else "ubuntu1604-py2715.tar.gz"

        elif config['platform']['host_key'] == "centos":
            config['resources']['ust_url'] += "centos7-py367.tar.gz" if isPy3 else "centos7-py275.tar.gz"


class bash_util:

    def __init__(self, loggingContext):
        self.logger = loggingContext.getLogger("bash")

    def shell(self, cmd):
        p = Popen(cmd, shell=True, stdout=PIPE, stdin=PIPE, stderr=STDOUT)
        for line in iter(p.stdout.readline, ''):
            p.stdin.write(b'y\n')
            self.logger.debug(line.rstrip('\n'))

    def shell_out(self, cmd):
        out = subprocess.check_output(cmd + " 2>&1", shell=True)
        self.logger.debug(out.decode().rstrip('\n'))
        return out

    def check_python_version(self, major):
        try:
            var = re.search("\d.*", self.shell_out("python" + str(major) + " -V")).group()
        except:
            self.logger.critical("Your system does not meet the minimum requirements for UST.  Please install"
                                 " python " + str(major) + ".* and re-run the setup.")
            exit()

    def install_dependencies(self, config):

        self.logger.info("Update package repositories ")
        self.shell(config['update_cmd'])

        self.logger.info("Installing openSSL")
        for c in config['openssl']:
            self.shell(c)


class main:

    def __init__(self):

        platform_details = platform.linux_distribution()
        self.loggingContext = LoggingContext(console_level=console_level, descriptor=("{0} {1} {2}")
                                             .format(platform_details[0], platform_details[1], platform_details[2]))

        self.logger = self.loggingContext.getLogger("main")
        self.config = {'platform': {},'resources':{}}
        self.web = web_util(self.loggingContext)
        self.bash = bash_util(self.loggingContext)
        self.ssl_gen = ssl_cert_generator(self.loggingContext)

        if (bool(re.search("(ubuntu)", platform_details[0], re.I))):
            self.config['platform']['host_key'] = "ubuntu"
        elif (bool(re.search("(cent)|(fedora)|(red)", platform_details[0], re.I))):
            self.config['platform']['host_key'] = "centos"

        hostkey = meta[self.config['platform']['host_key']]
        self.config['platform']['host_platform'] = platform_details[0]
        self.config['platform']['host_name'] = platform_details[2]
        self.config['platform']['host_version'] = platform_details[1]
        self.config['platform']['major_version'] = platform_details[1][:2]
        self.config['ust_directory'] = "adobe-user-sync-tool"
        self.config['update_cmd'] = hostkey['update_cmd']
        self.config['openssl'] = hostkey['openssl_script']
        self.config['python_version'] = hostkey['python_req'][platform_details[1][:2]]
        self.web.fetch_resources(self.config)

    def run(self):
        self.show_intro()
        self.bash.check_python_version(self.config['python_version'])
        self.install_ust()
        self.bash.install_dependencies(self.config)
        self.ssl_gen.generate()

    def create_shell(self, filename, command):
        filename = os.path.abspath(filename)
        self.logger.info(filename)
        text_file = open(filename, "w")
        text_file.write(command)
        text_file.close()

    def install_ust(self):

        self.logger.info("Beginning UST installation")

        ust_dir = os.path.abspath(self.config['ust_directory'])
        conf_dir = os.path.abspath(os.path.join(ust_dir, 'examples', 'config files - basic'))

        self.logger.info("Creating directory " + ust_dir)
        shutil.rmtree(ust_dir, ignore_errors=True)
        os.mkdir(ust_dir)

        self.logger.info("Downloading examples from " + self.config['resources']['examples_url'])
        self.web.download(self.config['resources']['examples_url'], ust_dir)

        self.logger.info("Downloading UST from " + self.config['resources']['ust_url'])
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

        self.logger.info("Setting folder permissions to 777... ")
        self.bash.shell("sudo chmod 777 -R " + ust_dir)
        self.logger.info("UST installation finished... ")

    def copy_to(self, src, dest):
        src = os.path.abspath(src)
        dest = os.path.abspath(dest)
        self.logger.info("Copy " + src + " to " + dest)
        shutil.copy(src, dest)

    def show_intro(self):
        for s in intro:
            self.logger.info(
                str.format(s,
                           self.config['platform']['host_platform'],
                           self.config['platform']['host_version'],
                           self.config['platform']['host_name'],
                           self.config['resources']['ust_version']))


class LoggingContext:

    def __init__(self, console_level=logging.DEBUG, descriptor=""):

        format_string = "%(asctime)s " + descriptor + "  [%(name)-8.8s]  [%(levelname)-8.8s]  :::  %(message)s"
        self.formatter = logging.Formatter(format_string, "%Y-%m-%d %H:%M:%S")

        self.original_stdout = sys.stdout
        logging.setLoggerClass(self.InputLogger)

        logger = logging.getLogger('')
        logger.setLevel(logging.DEBUG)

        f_handler = logging.FileHandler('ust_install.log', 'w')
        f_handler.setFormatter(self.formatter)
        f_handler.setLevel(logging.DEBUG)

        ch = logging.StreamHandler()
        ch.setLevel(console_level)
        ch.setFormatter(self.formatter)

        logger.addHandler(ch)
        logger.addHandler(f_handler)

        sys.stderr = sys.stdout = self.StreamLogger(logging.getLogger("main"), logging.INFO)

    def getLogger(self, name):

        logger = logging.getLogger(name)
        logger.formatter = self.formatter
        logger.original_stdout = self.original_stdout
        return logger

    class InputLogger(logging.Logger):
        def __init__(self, name):
            logging.Logger.__init__(self, name)
            self.logger = super(LoggingContext.InputLogger, self)
            self.original_stdout = sys.stdout
            self.formatter = None
            self.name = name

        def question(self, message):
            while True:
                ans = str(self.input(message)).lower()
                if (ans != "y" and ans != "n" and ans != ""):
                    self.logger.info("Please enter (y/n)...")
                else:
                    return False if ans == "n" else True

        def input(self, message):
            current_stdout = sys.stdout
            sys.stdout = self.original_stdout
            sys.stdout.write(self.getLogString(message + " ")),
            r = sys.stdin.readline().rstrip()
            sys.stdout = current_stdout
            self.logger.debug(message + " " + r)
            return r

        def getLogString(self, msg):
            r = logging.LogRecord(self.name, logging.INFO, "", 1, msg, None, None)
            return self.formatter.format(r)

        def pad(self, string, padlen=15):
            size = (padlen - len(string))
            return string + " " * max(size, 0)

    class StreamLogger(object):
        def __init__(self, logger, log_level):
            self.logger = logger
            self.log_level = log_level

        def write(self, message):
            for line in message.rstrip().splitlines():
                self.logger.log(self.log_level, line.rstrip())


main().run()
