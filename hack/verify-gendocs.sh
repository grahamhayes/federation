#!/bin/bash

# Copyright 2014 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

KUBE_ROOT=$(dirname "${BASH_SOURCE}")/..
source "${KUBE_ROOT}/hack/lib/init.sh"

kube::golang::setup_env

# Find binary
gendocs=$(kube::util::find-binary "gendocs")
genman=$(kube::util::find-binary "genman")
genbashcomp=$(kube::util::find-binary "genbashcomp")
mungedocs=$(kube::util::find-binary "mungedocs")

if [[ ! -x "$gendocs" || ! -x "$genman" || ! -x "$genbashcomp" || ! -x "$mungedocs" ]]; then
  {
    echo "It looks as if you don't have a compiled gendocs, genman, genbashcomp or mungedocs binary"
    echo
    echo "If you are running from a clone of the git repo, please run"
    echo "'./hack/build-go.sh cmd/gendocs cmd/genman cmd/genbashcomp cmd/mungedocs'."
  } >&2
  exit 1
fi

DOCROOT="${KUBE_ROOT}/docs/"
TMP_DOCROOT="${KUBE_ROOT}/_tmp/docs/"
_tmp="${KUBE_ROOT}/_tmp"

mkdir -p "${_tmp}"
cp -a "${DOCROOT}" "${TMP_DOCROOT}"

# mungedocs --verify can (and should) be run on the real docs, otherwise their
# links will be distorted. --verify means that it will not make changes.
"${mungedocs}" "--verify=true" "--root-dir=${DOCROOT}"
ret=$?
if [[ $ret -eq 1 ]]; then
  echo "${DOCROOT} is out of date. Please run hack/run-gendocs.sh"
  exit 1
fi
if [[ $ret -eq 2 ]]; then
  echo "Error running mungedocs"
  exit 1
fi

kube::util::gen-doc "${genman}" "${_tmp}" "docs/man/man1/"
kube::util::gen-doc "${gendocs}" "${_tmp}" "docs/user-guide/kubectl/" '###### Auto generated by spf13/cobra'

echo "diffing ${DOCROOT} against freshly generated docs"
ret=0
diff -Naupr "${DOCROOT}" "${TMP_DOCROOT}" || ret=$?
rm -rf "${_tmp}"
needsanalytics=($(kube::util::gen-analytics "${KUBE_ROOT}" 1))
if [[ ${#needsanalytics[@]} -ne 0 ]]; then
  echo -e "Some md files are missing ga-beacon analytics link:"
  printf '%s\n' "${needsanalytics[@]}"
  ret=1
fi
if [[ $ret -eq 0 ]]
then
  echo "${DOCROOT} up to date."
else
  echo "${DOCROOT} is out of date. Please run hack/run-gendocs.sh"
  exit 1
fi

COMPROOT="${KUBE_ROOT}/contrib/completions"
TMP_COMPROOT="${KUBE_ROOT}/contrib/completions_tmp"
cp -a "${COMPROOT}" "${TMP_COMPROOT}"
kube::util::gen-doc "${genbashcomp}" "${TMP_COMPROOT}" "bash/"
ret=0
diff -Naupr "${COMPROOT}" "${TMP_COMPROOT}" || ret=$?
rm -rf ${TMP_COMPROOT}
if [ $ret -eq 0 ]
then
	echo "${COMPROOT} up to date."
else
	echo "${COMPROOT} is out of date. Please run hack/run-gendocs.sh"
	echo "If you did not make a change to kubectl or its dependencies,"
	echo "run 'make clean' and retry this command."
	exit 1
fi

# ex: ts=2 sw=2 et filetype=sh
