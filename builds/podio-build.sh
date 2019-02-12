#!/usr/bin/env bash

set -e
set -x

#---Create stampfile to enable our jenkins to purge old builds------------------------------
touch $WORKSPACE/controlfile

#---Set up environment----------------------------------------------------------------------
source $WORKSPACE/podio/init.sh

#---Prepare folder to store build artifacts-------------------------------------------------
rm -r $WORKSPACE/podio/build || true
mkdir $WORKSPACE/podio/build
cd $WORKSPACE/podio/build

#---Run installation------------------------------------------------------------------------
cmake -DCMAKE_INSTALL_PREFIX=../install ..
make -j$(nproc)
make install
make test
