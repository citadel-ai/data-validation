#!/bin/bash
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script is expected to run in the docker container defined in
# Dockerfile.manylinux2010
# Assumptions:
# - CentOS environment.
# - devtoolset-8 is installed.
# - $PWD is TFDV's project root.
# - Python of different versions are installed at /opt/python/.
# - patchelf, zip, bazel is installed and is in $PATH.

WORKING_DIR=$PWD

function setup_environment() {
  PYTHON_DIR=/usr/local
  export PIP_BIN="${PYTHON_DIR}"/bin/pip
  export PYTHON_BIN_PATH="${PYTHON_DIR}"/bin/python
  echo "PYTHON_BIN_PATH=${PYTHON_BIN_PATH}"
  export WHEEL_BIN="${PYTHON_DIR}"/bin/wheel
  ${PIP_BIN} install --upgrade pip
  ${PIP_BIN} install wheel --upgrade
  ${PIP_BIN} install auditwheel==5.2.0
  ${PIP_BIN} install patchelf
}

function install_numpy() {
  ${PIP_BIN} install "numpy>=2.0" --force
}

function build_wheel() {
  rm -rf dist
  "${PYTHON_BIN_PATH}" setup.py bdist_wheel
}

function stamp_wheel() {
  WHEEL_PATH="$(ls "$PWD"/dist/*.whl)"
  WHEEL_DIR=$(dirname "${WHEEL_PATH}")
  TMP_DIR="$(mktemp -d)"
  auditwheel -v repair --plat linux_aarch64 -w "${WHEEL_DIR}" "${WHEEL_PATH}"
  rm "${WHEEL_PATH}"
}

set -x
setup_environment && \
install_numpy && \
build_wheel && \
stamp_wheel
