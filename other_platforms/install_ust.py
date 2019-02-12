import logging
import sys
import platform
import subprocess
import re
import os
import tarfile
import shutil

try:
    import requests
except ImportError:
    os.system("sudo pip install requests")
    import requests

meta = {}
meta['ubuntu'] = {
    'install_cmd':'sudo apt-get --force-yes -y install',
    'update_cmd': 'sudo apt-get update',
    'openssl_reqs': ['openssl', 'libssl-dev']
}



class web_util:

    def download(self, url, dir):

        r = requests.get(url)
        filename = dir + os.sep + str(url.rpartition('/')[2])
        with open(filename, 'wb') as f: f.write(r.content)

        if (filename.endswith(".tar.gz")):
            tarfile.open(filename).extractall(path=dir)
            os.remove(filename)

    def fetch_resources(self, config):

        config['resources'] = {}
        config['resources']['examples_url'] = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.4/examples.tar.gz"

        if  config['host_key'] == "ubuntu":
            config['resources']['ust_py3_url'] = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.4/user-sync-v2.4-ubuntu1604-py367.tar.gz"
            config['resources']['ust_py2_url'] = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.4/user-sync-v2.4-ubuntu1604-py2715.tar.gz"


        elif config['host_key'] == "centos":
            config['resources']['ust_py3_url'] = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.4/user-sync-v2.4-centos7-py367.tar.gz"
            config['resources']['ust_py2_url'] = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.4/user-sync-v2.4-centos7-py275.tar.gz"


class bash_util:


    def __init__(self, host_key):
        self.meta = meta[host_key]
        self.install_cmd = self.meta['install_cmd']
        self.update_cmd = self.meta['update_cmd']


    def shell(self, cmd):
        out = subprocess.check_output(cmd + " 2>&1", shell=True)
        print(out)
        return out

    def get_python_version(self, major):
        return re.search("\d.*", self.shell("python" + str(major) + " -V")).group()

    def install_package(self, name):
        self.shell(self.install_cmd + " " + name)

    def install_preRequisites(self, config):

        for p in self.meta['openssl_reqs']:
            self.install_package(p)



        print



class main:

    def __init__(self):
        self.config = {}

    def create_shell(self, filename, command):
        text_file = open(filename, "w")
        text_file.write(command)
        text_file.close()

    def install_ust(self):

        ust_dir = self.config['ust_directory']
        conf_dir = os.path.join(ust_dir,'examples','config files - basic')

        self.web.download(self.config['resources']['examples_url'], ust_dir)
        #self.web.download(self.config['resources']['ust_py2_url'], ust_dir)

        shutil.copy(os.path.join(conf_dir,"connector-ldap.yml"), ust_dir)
        shutil.copy(os.path.join(conf_dir,"connector-umapi.yml"), ust_dir)
        shutil.copy(os.path.join(conf_dir,"user-sync-config.yml"), ust_dir)

        self.create_shell(os.path.join(ust_dir,"run-user-sync-test.sh"),"#!/usr/bin/env bash\n./user-sync --users mapped --process-groups -t")
        self.create_shell(os.path.join(ust_dir,"run-user-sync-live.sh"),"#!/usr/bin/env bash\n./user-sync --users mapped --process-groups")
        self.create_shell(os.path.join(ust_dir,"sslCertGen.sh"),
                          "#!/usr/bin/env bash\nopenssl req -x509 -sha256 -nodes -days 9125 -newkey rsa:2048 -keyout private.key -out certificate_pub.crt")

        self.bash.shell("sudo chmod 777 -R " + ust_dir)

    def initialize(self):
        platform_details = platform.linux_distribution()
        self.config['ust_directory'] = "adobe-user-sync-tool"
        self.config['host_platform'] = platform_details[0]
        self.config['host_name'] = platform_details[2]
        self.config['host_version'] = platform_details[1]

        if (bool(re.search("(ubuntu)", self.config['host_platform'], re.I))):
            self.config['host_key'] = "ubuntu"
        elif (bool(re.search("(cent)|(fedora)|(red)", self.config['host_platform'], re.I))):
            self.config['host_key'] = "centos"

        self.logger = LoggingContext().init_logger(self.config)

        self.bash = bash_util(self.config['host_key'])
        self.web = web_util()

        shutil.rmtree(self.config['ust_directory'], ignore_errors=True)
        os.mkdir(self.config['ust_directory'])

    def run(self):
        self.initialize()
        self.config['python2_version'] = self.bash.get_python_version(2)
        self.config['python3_version'] = self.bash.get_python_version(3)
        self.config['python27'] = self.config['python2_version'].startswith("2.7")
        self.config['python36'] = self.config['python3_version'].startswith("3.6")

        self.web.fetch_resources(self.config)

        self.bash.install_preRequisites(self.config)
        self.install_ust()

        print


class LoggingContext:

    def init_logger(self, config):
        log_params = {
            'this_name': config['host_platform'] + " " + config['host_version'] + " " + config['host_name'],
            'log_level': logging.getLevelName("DEBUG"),
            'date_fmt': '%Y-%m-%d %H:%M:%S'
        }

        f_format = "%(asctime)s " + log_params['this_name'] + "  [%(name)-8.8s]  [%(levelname)-5.5s]  :::  %(message)s"
        logging.basicConfig(level=log_params['log_level'], format=f_format, datefmt=log_params['date_fmt'])
        logger = logging.getLogger("main")
        f_handler = logging.FileHandler('pyinstall.log', 'w')
        f_handler.setFormatter(logging.Formatter(f_format, log_params['date_fmt']))
        f_handler.setLevel(log_params['log_level'])
        logger.addHandler(f_handler)
        sys.stderr = sys.stdout = self.StreamToLogger(logger, log_params['log_level'])
        return logger

    class StreamToLogger(object):
        def __init__(self, logger, log_level):
            self.logger = logger
            self.log_level = log_level

        def write(self, message):
            for line in message.rstrip().splitlines():
                self.logger.log(self.log_level, line.rstrip())

        def flush(self): pass


main().run()

# import gzip
# from cStringIO import StringIO
# tar = tarfile.open(mode="r:gz", fileobj=StringIO(r.content))
#
# #   tar = tarfile.open("sample.tar.gz")
# for entry in tar.getnames():  # list each entry one by one
#     fileobj = tar.extractfile(entry)
#     with open(entry, 'wb') as f:
#         f.write(fileobj.read())
#
#     print