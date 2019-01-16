#!/usr/bin/env bash

set -e
set -x

#---Create stampfile to enable our jenkins to purge old builds------------------------------
touch $WORKSPACE/controlfile

#---Set up environment----------------------------------------------------------------------
cd $WORKSPACE/papas
source $WORKSPACE/papas/init.sh

#---Prepare folder to store build artifacts-------------------------------------------------
rm -rf $WORKSPACE/papas/build
mkdir $WORKSPACE/papas/build
cd $WORKSPACE/papas/build

#---Run installation------------------------------------------------------------------------
cmake -DCMAKE_INSTALL_PREFIX=../install ..
make -j$(nproc)
make install

#---Run tests-------------------------------------------------------------------------------
export CTEST_OUTPUT_ON_FAILURE=1
make test
