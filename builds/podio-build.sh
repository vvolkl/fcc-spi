#!/usr/bin/env bash

set -e
set -x

#---Create stampfile to enable our jenkins to purge old builds------------------------------
touch $WORKSPACE/controlfile

#---Set up environment----------------------------------------------------------------------
source $WORKSPACE/podio/init.sh

#---Prepare folder to store build artifacts-------------------------------------------------
mkdir $WORKSPACE/podio/build
cd build

#---Run installation------------------------------------------------------------------------
cmake -DCMAKE_INSTALL_PREFIX=../install -Dpodio_tests=ON ..
make
make install
