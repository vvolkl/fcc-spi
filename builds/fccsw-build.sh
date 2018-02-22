#!/usr/bin/env bash

set -e
set -x

#---Create stampfile to enable our jenkins to purge old builds------------------------------
touch $WORKSPACE/controlfile

#---Set up environment----------------------------------------------------------------------
cd $WORKSPACE/fccsw
source $WORKSPACE/fccsw/init.sh
#source /cvmfs/fcc.cern.ch/sw/views/releases/0.9.0/x86_64-slc6-gcc62-opt/setup.sh

#---Clean build folder----------------------------------------------------------------------
make purge


#---Run installation------------------------------------------------------------------------
make -j16
make install

#---Run tests-------------------------------------------------------------------------------
export CTEST_OUTPUT_ON_FAILURE=1
make test ARGS="-j 1"
