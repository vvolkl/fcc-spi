#!/usr/bin/env bash

set -e
set -x

#---Create stampfile to enable our jenkins to purge old builds------------------------------
touch $WORKSPACE/controlfile

#---Set up environment----------------------------------------------------------------------
cd $WORKSPACE/FCCSW
source $WORKSPACE/FCCSW/init.sh

# TODO: afs reference needs to be removed
cp /afs/cern.ch/exp/fcc/sw/0.5/testsamples/example_MyPythia.dat .

#---Run installation------------------------------------------------------------------------
make -j16
make
make install

#---Run tests-------------------------------------------------------------------------------
export CTEST_OUTPUT_ON_FAILURE=1
