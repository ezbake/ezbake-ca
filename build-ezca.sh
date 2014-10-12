#!/bin/bash

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


REPO_ROOT="$(pwd)"
BUILDROOT="${REPO_ROOT}/BUILD"
PACKAGEROOT="${BUILDROOT}/EzCA_Pkg"
mkdir -p "${BUILDROOT}" && cd "${BUILDROOT}"

PYENV=2.7.6
BRANCH=master

function copy_to_build() {
    local src="$1"
    local dest="${2}/$(basename "${src}")"

    echo "Copying ${src}/ to ${dest}"
	rsync -r "${src}"/ "${dest}"
}

function install_package() {
    local name="$1"
    local dir="$2"

    #version=$(pip list | grep "${name}")
    #if [ $? -eq 1 ]; then
    echo "${name} not installed. Installing now"
    (cd "${dir}" && python setup.py clean -a && python setup.py install && pyenv rehash) || (echo "failed"; exit 1)
    #else
        #echo "${name} installed - ${version}"
    #fi
}

function install_maven() {
    local dir="$1"
    echo "Running maven package of ${dir}"
    (cd "${dir}" && mvn clean package) || (echo "failed to package ${dir}"; exit 1)
}

echo "cloning the repos from git"
for x in ${REPOS[@]}; do
    x=(${x[0]//;/ })
    repo="${x[0]}"
    dir="${x[1]}"
    branch="${x[2]}"

    if [ -d "${dir}" ]; then
        echo "${dir} already checked out"
        #(cd "${dir}" && git pull) 
    else
        echo "cloning ${repo} into ${dir}"
        git clone "${repo}" "${dir}"
    fi

    echo "cheking out ${branch}"
    (cd "${dir}" && git checkout "${branch}")
done

# Copy local resources to the build directory
copy_to_build "${REPO_ROOT}/eztssl" "${BUILDROOT}"
copy_to_build "${REPO_ROOT}/ezpz" "${BUILDROOT}"
copy_to_build "${REPO_ROOT}/ezthriftpool" "${BUILDROOT}"
copy_to_build "${REPO_ROOT}/ezpersist" "${BUILDROOT}"
copy_to_build "${REPO_ROOT}/service" "${BUILDROOT}"
copy_to_build "${REPO_ROOT}/ezca-bootstrap" "${BUILDROOT}"

echo "switching to pyenv virtualenv ${PYENV}"
eval "$(pyenv init -)"
pyenv shell "${PYENV}" || env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install "${PYENV}" && pyenv shell "${PYENV}"

pip list | grep 'setuptools' || curl -L https://bootstrap.pypa.io/get-pip.py | python
pip list | grep 'pyinstaller' || pip install pyinstaller
pip list | grep 'zope.interface' || pip install zope.interface
touch ~/.pyenv/versions/2.7.6/lib/python2.7/site-packages/zope/__init__.py

# Install main ezbake libs
# install_package EzConfiguration "${ezconfig_arr[1]}/api/python"
# install_package ezdiscovery "${ezdiscovery_arr[1]}/servicediscovery/python"

# Install EzCA packages
install_package EzTSSL "eztssl"
install_package "ezpz" "ezpz"
install_package "ezthriftpool" "ezthriftpool"
install_package "ezpersist" "ezpersist"
install_package ezca "service"

install_maven "ezca-bootstrap"

echo "Building with pyinstaller"
LD_LIBRARY_PATH=/home/vagrant/.pyenv/versions/2.7.6/lib pyinstaller -y "service/bin/ezcaservice.py" --hidden-import=pkg_resources

echo "Packaging"
rm -rf "${PACKAGEROOT}"
mkdir -p "${PACKAGEROOT}"/{bin,config,app}
cp -r "dist/ezcaservice" "${PACKAGEROOT}/app/"
cp "ezca-bootstrap/target/ezca-bootstrap-"*-shaded.jar "${PACKAGEROOT}/bin/ezca-bootstrap"
cp "${REPO_ROOT}"/scripts/* "${PACKAGEROOT}/bin/"
cat > "${PACKAGEROOT}/config/ezca.properties" <<'EOF'
ezbake.shared.secret.environment.variable=EZBAKE_ENCRYPTION_SECRET
EOF

chmod -R o-rwx "${PACKAGEROOT}"
chmod +x "${PACKAGEROOT}/bin/init"
chmod +x "${PACKAGEROOT}/bin/start"
chmod +x "${PACKAGEROOT}/bin/stop"
tar --transform s/EzCA_Pkg/ezca/ -czf $(basename "${PACKAGEROOT}").tar.gz -C "${BUILDROOT}" $(basename "${PACKAGEROOT}")

fpm -f -s tar -t rpm \
    -n EzCA -v 2.0 --iteration $(date +"%Y%m%d%H%M") \
    --rpm-user ezca --rpm-group ezca \
    --rpm-defattrfile 0640 --rpm-defattrdir 0750 \
    --rpm-auto-add-directories \
    --rpm-use-file-permissions \
    --prefix=/opt \
    "${PACKAGEROOT}.tar.gz"
