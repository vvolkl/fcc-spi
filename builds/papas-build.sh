#!/usr/bin/env bash

set -e
set -x

#---Create stampfile to enable our jenkins to purge old builds------------------------------
touch $WORKSPACE/controlfile

#---Set up environment----------------------------------------------------------------------
source $WORKSPACE/papas/init.sh

#---Prepare folder to store build artifacts-------------------------------------------------
mkdir $WORKSPACE/papas/build
cd $WORKSPACE/papas/build

#---Run installation------------------------------------------------------------------------
cmake -DCMAKE_INSTALL_PREFIX=../install ..
make
make install

#---Run tests-------------------------------------------------------------------------------
export CTEST_OUTPUT_ON_FAILURE=1
make test
