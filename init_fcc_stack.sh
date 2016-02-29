#!/bin/sh -u
# This script sets up the commonly used software for FCC software projects:
# - Linux machines at CERN:  The software is taken from afs.
# - MacOS / Linux elsewhere: We assume the software is installed locally and their environment is set.

# Add the passed value only to path if it's not already in there.
function add_to_path {
    if [ -z "$1" ] || [[ "$1" == "/lib" ]]; then
        return
    fi
    case ":$path:" in
      *":$1:"*) :;;        # already there
      *) path="$1:$path";; # or prepend path
    esac
}

platform='unknown'
unamestr=`uname`

if [[ "$unamestr" == 'Linux' ]]; then
    platform='Linux'
    echo "Platform detected: $platform"
    if [[ -d /afs/cern.ch/sw/lcg ]] && [[ `dnsdomainname` = 'cern.ch' ]] ; then
        # Set up Gaudi + Dependencies
        source /afs/cern.ch/lhcb/software/releases/LBSCRIPTS/LBSCRIPTS_v8r4p3/InstallArea/scripts/LbLogin.sh --cmtconfig x86_64-slc6-gcc49-opt
        # The LbLogin sets VERBOSE to 1 which increases the compilation output. If you want details set this to 1 by hand.
        export VERBOSE=
        # Set up gcc 4.9
        source /afs/cern.ch/sw/lcg/contrib/gcc/4.9.3/x86_64-slc6/setup.sh
        # This path is used below to select software versions
        export CMTPROJECTPATH=/afs/cern.ch/exp/fcc/sw/0.6
        echo "Software taken from $CMTPROJECTPATH"
        # set up python and friends
        source $CMTPROJECTPATH/LCG_80/Python/2.7.9.p1/x86_64-slc6-gcc49-opt/Python-env.sh
        source $CMTPROJECTPATH/LCG_80/pyanalysis/1.5_python2.7/x86_64-slc6-gcc49-opt/pyanalysis-env.sh
        # If podio or EDM not set locally already, take them from afs
        if [ -z "$PODIO" ]; then
            export PODIO=$CMTPROJECTPATH/podio/0.2/x86_64-slc6-gcc49-opt
        else
            echo "Take podio: $PODIO"
        fi
        if [ -z "$FCCEDM" ]; then
            export FCCEDM=$CMTPROJECTPATH/fcc-edm/0.2/x86_64-slc6-gcc49-opt
        else
            echo "Take fcc-edm: $FCCEDM"
        fi
        export DELPHES_DIR=$CMTPROJECTPATH/Delphes-3.3.2/x86_64-slc6-gcc49-opt
        export PYTHIA8_DIR=$CMTPROJECTPATH/LCG_80/MCGenerators/pythia8/212/x86_64-slc6-gcc49-opt
        export PYTHIA8_XML=$CMTPROJECTPATH/LCG_80/MCGenerators/pythia8/212/x86_64-slc6-gcc49-opt/share/Pythia8/xmldoc
        # add Geant4 data files
        source /afs/cern.ch/sw/lcg/external/geant4/10.1/setup_g4datasets.sh
        # add DD4hep
        export inithere=$PWD
        cd $CMTPROJECTPATH/DD4hep/20152311/x86_64-slc6-gcc49-opt
        source bin/thisdd4hep.sh
        cd $inithere
    fi
    path=$LD_LIBRARY_PATH
    add_to_path $FCCEDM/lib
    add_to_path $PODIO/lib
    add_to_path $PYTHIA8_DIR/lib
    export LD_LIBRARY_PATH=$path
    path=$PYTHONPATH
    add_to_path $PODIO/python
    export PYTHONPATH=$path
elif [[ "$unamestr" == 'Darwin' ]]; then
    platform='Darwin'
    echo "Platform detected: $platform"
    path=$DYLD_LIBRARY_PATH
    add_to_path $FCCEDM/lib
    add_to_path $PODIO/lib
    add_to_path $PYTHIA8_DIR/lib
    export DYLD_LIBRARY_PATH=$path
    path=$PYTHONPATH
    add_to_path $PODIO/python
    export PYTHONPATH=$path
fi

path=$CMAKE_PREFIX_PATH
add_to_path $FCCEDM
add_to_path $PODIO
add_to_path $PYTHIA8_DIR
if [ "$DELPHES_DIR" ]; then
    add_to_path $DELPHES_DIR
fi
export CMAKE_PREFIX_PATH=$path

