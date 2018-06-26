#!/usr/bin/env bash

set -e
set -x

#---Create stampfile to enable our jenkins to purge old builds------------------------------
touch $WORKSPACE/controlfile

#---Set up environment----------------------------------------------------------------------
source $WORKSPACE/fcc-edm/init.sh

#---Prepare folder to store build artifacts-------------------------------------------------
mkdir $WORKSPACE/fcc-edm/build
cd $WORKSPACE/fcc-edm/build

#---Run installation------------------------------------------------------------------------
cmake ..
make -j$(nproc)
export CTEST_OUTPUT_ON_FAILURE=1
make test
