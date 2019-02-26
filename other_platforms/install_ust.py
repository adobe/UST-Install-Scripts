import datetime
import logging
import os
import platform
import re
import shutil
import subprocess
import sys
import tarfile
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

meta = {}
meta['ubuntu'] = {

    'update_cmd': 'sudo apt-get update',
    'openssl_script': ['sudo apt-get -y install openssl',
                       'sudo apt-get -y install libssl-dev'],
    '16': {
        'python_vers': '2.7',
        'python_inst': ['sudo apt-get -y install libpython2.7',
                        'sudo apt-get -y install libatlas3-base',
                        'sudo apt-get -y install python2.7'],
    },
    '17': {
        'python_vers': '2.7',
        'python_inst': [
            'sudo sed -i -e "s/archive.ubuntu.com\|security.ubuntu.com/old-releases.ubuntu.com/g" /etc/apt/sources.list',
            'sudo apt-get update',
            'sudo apt-get -y install libpython2.7',
            'sudo apt-get -y install libatlas3-base',
            'sudo apt-get -y install python2.7'],
    },
    '18': {
        'python_vers': '3.6',
        'python_inst': ['sudo apt-get -y install python3.6'],
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


original = sys.stdout


class ssl_cert_generator:

    def __init__(self, logger):
        self.logger = logger

    def get_value(self):

        import StringIO

        self.logger.test()
        #x = lc.log_capture_string.getvalue()

        # old_stdout = sys.stdout
        # s = StringIO.StringIO()
        #sys.stdout = original
#

       #$ sys.stdout.write("2019-02-26 22:36:10 Ubuntu 16.04 xenial  [main    ]  [INFO ]  :::")
     #   raw_input("2019-02-26 22:36:10 Ubuntu 16.04 xenial  [main    ]  [INFO ]  ::: ")
        #sys.stdout = old_stdout


        print()


        # z = self.logger.info("")
        # sys.stdout.write("A")
        # sys.stdout.write("C")
        # print("BBBB")
        # raw_input("ABCD")

      #  return raw_input("Country Code [US]: ")


    def get_subject(self):

        self.get_value()
       # self.logger.info(self.get_value())

        return  x509.Name([
                x509.NameAttribute(NameOID.COUNTRY_NAME, u"US"),
                x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, u"CA"),
                x509.NameAttribute(NameOID.LOCALITY_NAME, u"San Francisco"),
                x509.NameAttribute(NameOID.ORGANIZATION_NAME, u"My Company"),
                x509.NameAttribute(NameOID.COMMON_NAME, u"mysite.com"),
        ])

    def get_certificate(self, key):
        subject = issuer = self.get_subject()
        return  x509.CertificateBuilder()\
                .subject_name(subject)\
                .issuer_name(issuer)\
                .public_key(key.public_key())\
                .serial_number(12345)\
                .not_valid_before(datetime.datetime.utcnow())\
                .not_valid_after(datetime.datetime.utcnow() + datetime.timedelta(days=10))\
                .sign(key, hashes.SHA256(), default_backend())

    def get_key(self):

        return  rsa.generate_private_key(
                public_exponent = 65537,
                key_size = 2048,
                backend = default_backend())

    def generate(self):

        self.logger.info("Begin SSL certificate generation...")

        key = self.get_key()
        cert = self.get_certificate(key)

        with open("private.key", "wb") as f:
            f.write(key.private_bytes(
                encoding = serialization.Encoding.PEM,
                format = serialization.PrivateFormat.TraditionalOpenSSL,
                encryption_algorithm=serialization.NoEncryption()
            ))

        with open("certificate_pub.crt", "wb") as f:
            f.write(cert.public_bytes(serialization.Encoding.PEM))

class web_util:

    def __init__(self, logger):
        self.logger = logger

    def download(self, url, dir):

        filename = dir + os.sep + str(url.rpartition('/')[2])
        urlretrieve(url, filename)

        if (filename.endswith(".tar.gz")):
            tarfile.open(filename).extractall(path=dir)
            os.remove(filename)

    def fetch_resources(self, config):

        config['resources']['ust_version'] = "2.4"
        config['resources']['examples_url'] = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.4/examples.tar.gz"
        config['resources']['ust_url'] = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.4/user-sync-v2.4-"

        isPy3 = config['python']['target']['python_vers'].startswith("3")

        if   config['platform']['host_key'] == "ubuntu":
             config['resources']['ust_url'] += "ubuntu1604-py367.tar.gz" if isPy3 else "ubuntu1604-py2715.tar.gz"

        elif config['platform']['host_key'] == "centos":
             config['resources']['ust_url'] += "centos7-py367.tar.gz" if isPy3 else "centos7-py275.tar.gz"


class bash_util:

    def __init__(self, logger):
        self.logger = logger


    def shell(self, cmd):
        p = Popen(cmd, shell=True, stdout=PIPE, stdin=PIPE, stderr=STDOUT)
        for line in iter(p.stdout.readline, ''):
            p.stdin.write(b'y\n')
            self.logger.debug(line.rstrip('\n'))

    def shell_out(self, cmd):
        out = subprocess.check_output(cmd + " 2>&1", shell=True)
        self.logger.debug(out.decode().rstrip('\n'))
        return out

    def get_python_version(self, major):
        try:
            return re.search("\d.*", self.shell_out("python" + str(major) + " -V")).group()
        except:
            return "[none]"

    def install_dependencies(self, config):

        self.logger.info("Update package repositories ")
        self.shell(config['update_cmd'])

        self.logger.info("Installing openSSL")
        for c in config['openssl']:
            self.shell(c)

        # self.logger.info("Installing Python")
        # for c in config['python']['target']['python_inst']:
        #     self.shell(c)

class main:

    def __init__(self):

        platform_details = platform.linux_distribution()
        self.logger = lc.init_logger(platform_details)

        self.config = {'platform':{}, 'python':{}, 'resources':{}}
        self.web = web_util(self.logger)
        self.bash = bash_util(self.logger)
        self.ssl_gen = ssl_cert_generator(self.logger)
        py2_version = self.bash.get_python_version(2)
        py3_version = self.bash.get_python_version(3)

        if (bool(re.search("(ubuntu)", platform_details[0], re.I))):
            self.config['platform']['host_key'] = "ubuntu"
        elif (bool(re.search("(cent)|(fedora)|(red)", platform_details[0], re.I))):
            self.config['platform']['host_key'] = "centos"

        self.config['platform']['host_platform'] = platform_details[0]
        self.config['platform']['host_name'] = platform_details[2]
        self.config['platform']['host_version'] = platform_details[1]
        self.config['platform']['major_version'] = platform_details[1][:2]
        self.config['ust_directory'] = "adobe-user-sync-tool"
        self.config['update_cmd'] = meta[self.config['platform']['host_key']]['update_cmd']
        self.config['openssl'] = meta[self.config['platform']['host_key']]['openssl_script']
        self.config['python'] = {
            'target': meta[self.config['platform']['host_key']][self.config['platform']['major_version']],
            'current': {
                'python2_version':py2_version,
                'python3_version':py3_version,
                'python2_status': py2_version.startswith("2.7"),
                'python3_status': py3_version.startswith("3.6")
            }
        }

        self.web.fetch_resources(self.config)

    def create_shell(self, filename, command):
        filename = os.path.abspath(filename)
        self.logger.info(filename)
        text_file = open(filename, "w")
        text_file.write(command)
        text_file.close()

    def install_ust(self):

        self.logger.info("Beginning UST installation")

        ust_dir = os.path.abspath(self.config['ust_directory'])
        conf_dir = os.path.abspath(os.path.join(ust_dir,'examples','config files - basic'))

        self.logger.info("Creating directory " + ust_dir)
        shutil.rmtree(ust_dir, ignore_errors=True)
        os.mkdir(ust_dir)

        self.logger.info("Downloading examples from " + self.config['resources']['examples_url'])
        self.web.download(self.config['resources']['examples_url'], ust_dir)

        self.logger.info("Downloading UST from " + self.config['resources']['ust_url'])
        self.web.download(self.config['resources']['ust_url'], ust_dir)

        self.logger.info("Creating configuration files... ")
        self.copy_to(os.path.join(conf_dir,"connector-ldap.yml"), ust_dir)
        self.copy_to(os.path.join(conf_dir,"connector-umapi.yml"), ust_dir)
        self.copy_to(os.path.join(conf_dir,"user-sync-config.yml"), ust_dir)

        self.logger.info("Creating shell scripts... ")
        self.create_shell(os.path.join(ust_dir,"run-user-sync-test.sh"),"#!/usr/bin/env bash\n./user-sync --users mapped --process-groups -t")
        self.create_shell(os.path.join(ust_dir,"run-user-sync-live.sh"),"#!/usr/bin/env bash\n./user-sync --users mapped --process-groups")
        self.create_shell(os.path.join(ust_dir,"sslCertGen.sh"),
                          "#!/usr/bin/env bash\nopenssl req -x509 -sha256 -nodes -days 9125 -newkey rsa:2048 -keyout private.key -out certificate_pub.crt")

        self.logger.info("Setting folder permissions to 777... ")
        self.bash.shell("sudo chmod 777 -R " + ust_dir)
        self.logger.info("UST installation finished... ")

    def copy_to(self, src, dest):
        src = os.path.abspath(src)
        dest = os.path.abspath(dest)
        self.logger.info("Copy " + src + " to " + dest)
        shutil.copy(src, dest)

    def run(self):

        self.show_intro()
        #self.install_ust()
        self.ssl_gen.generate()
        exit()
        self.bash.install_dependencies(self.config)


    def show_intro(self):
        for s in intro:
            self.logger.info(
                str.format(s,
                    self.config['platform']['host_platform'],
                    self.config['platform']['host_version'],
                    self.config['platform']['host_name'],
                    self.config['resources']['ust_version']))


class LoggingContext:

    def __init__(self):
        self.formatter = logging.Formatter()
        original_stdout = sys.stdout

    def get_log_string(self, msg=""):
        r = logging.LogRecord("main", logging.INFO, "", 1, msg, None, None)
        return self.formatter.format(r)

    def init_logger(self, platform):
        log_params = {
            'this_name': platform[0] + " " + platform[1] + " " + platform[2],
            'log_level': logging.getLevelName("DEBUG"),
            'date_fmt': '%Y-%m-%d %H:%M:%S'
        }

        f_format = "%(asctime)s " + log_params['this_name'] + "  [%(name)-8.8s]  [%(levelname)-5.5s]  :::  %(message)s"

        self.formatter = logging.Formatter(f_format, log_params['date_fmt'])
        logging.basicConfig(level=log_params['log_level'], format=f_format, datefmt=log_params['date_fmt'])
        logger = self.CustomLogger("main") #logging.getLogger("main")
        f_handler = logging.FileHandler('ust_install.log', 'w')
        f_handler.setFormatter(self.formatter)
        f_handler.setLevel(log_params['log_level'])
        logger.addHandler(f_handler)
        sys.stderr = sys.stdout = self.StreamToLogger(logger, log_params['log_level'])

        return logger

    class CustomLogger(logging.Logger):
        def __init__(self, name):
            logging.Logger.__init__(self, name)
            

        def test(self):
            print("ABCDE")

    class StreamToLogger(object):
        def __init__(self, logger, log_level):
            self.logger = logger
            self.log_level = log_level

        def write(self, message):
            for line in message.rstrip().splitlines():
                self.logger.log(self.log_level, line.rstrip())

        def flush(self): pass

lc = LoggingContext()
main().run()
