#!/usr/bin/env bash

set -e
set -x

#---Create stampfile to enable our jenkins to purge old builds------------------------------
touch $WORKSPACE/controlfile

#---Set up environment----------------------------------------------------------------------
cd $WORKSPACE/fccsw
source $WORKSPACE/fccsw/init.sh


#---Run installation------------------------------------------------------------------------
make -j16
make
make install

#---Run tests-------------------------------------------------------------------------------
export CTEST_OUTPUT_ON_FAILURE=1
make test ARGS="-j 2"
