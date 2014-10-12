#   Copyright (C) 2013-2014 Computer Sciences Corporation
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

from setuptools import setup, find_packages
app = find_packages('lib')

setup(
    name='ezca',
    version='0.1.dev',
    description='ezbake ca service',
    author='Jeff Hastings',
    author_email='jhastings@42six.com',
    url='none yet',
    packages=app,
    package_dir={
        '': 'lib',
    },
    include_package_data=True,
    scripts=['bin/ezcaservice.py'],
    dependency_links=[
        'git+ssh://git@github.com/ezbakethrift/ezbake-base-thrift.git@0.1-python#egg=ezbake-base-thrift-0.1',
        'git+ssh://git@github.com/ezbake/ezbake-configuration.git@0.1-python#egg=EzConfiguration-0.1',
        'git+ssh://git@github.com/ezbake/ezbake-discovery.git@0.1-python#egg=ezdiscovery-0.1'
    ],
    install_requires=[
        'thrift==0.9.1',
        'nose==1.3.0',
        'PyOpenSSL==0.13.1',
        'pycrypto==2.6.1',
        'kazoo',
        'ezdiscovery==0.1',
        'EzConfiguration==0.1',
        'ezbake-base-thrift==0.1',
        'EzTSSL >= 0.1',
        'EzPersist >= 0.1'
    ]
)
