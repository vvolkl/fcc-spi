#!/bin/sh -u
# This script sets up the commonly used software for FCC software projects:
# - Linux machines at CERN:
#    The software is taken from cvmfs or afs depending on command (source init_fcc_stack.sh cvmfs/afs).
# - MacOS / Linux elsewhere: We assume the software is installed locally and their environment is set.

# Add the passed value only to path if it's not already in there.
function add_to_path {
    if [ -z "$1" ] || [[ "$1" == "/lib" ]]; then
        return
    fi
    path_name=${1}
    eval path_value=\$$path_name
    path_prefix=${2}
    case ":$path_value:" in
      *":$path_prefix:"*) :;;        # already there
      *) path_value=${path_prefix}:${path_value};; # or prepend path
    esac
    eval export ${path_name}=${path_value}
}

platform='unknown'
unamestr=`uname`

if [[ "$unamestr" == 'Linux' ]]; then
    fs=$1
    echo $fs
    if [ -z "$fs" ]; then
        fs="afs"
        echo "INFO - Defaulting to afs as file system. If you want cvmfs use:"
        echo "     source init_fcc_stack.sh cvmfs"
    fi
    platform='Linux'
    echo "Platform detected: $platform"
    if [[ -d /cvmfs/sft.cern.ch/lcg ]] || [[ -d /afs/cern.ch/sw/lcg ]] && [[ `dnsdomainname` = 'cern.ch' ]] ; then
        # Check if build type is set, if not default to release build
        if [ -z "$BUILDTYPE" ] || [ "$BUILDTYPE" == "Release" ]; then
            export BINARY_TAG=x86_64-slc6-gcc49-opt
            export CMAKE_BUILD_TYPE="Release"
        else
            export BINARY_TAG=x86_64-slc6-gcc49-dbg
            export CMAKE_BUILD_TYPE="Debug"
        fi
        # Set up Gaudi + Dependencies
        if [[ $fs = 'afs' ]]; then
            LHCBPATH=/afs/cern.ch/lhcb/software/releases
            LCGPREFIX=/afs/cern.ch/sw/lcg
            export FCCSWPATH=/afs/cern.ch/exp/fcc/sw/0.7
        else
            LHCBPATH=/cvmfs/lhcb.cern.ch/lib/lhcb
            LCGPREFIX=/cvmfs/sft.cern.ch/lcg
            export FCCSWPATH=/cvmfs/fcc.cern.ch/sw/0.7
        fi
        source $LHCBPATH/LBSCRIPTS/LBSCRIPTS_v8r5p3/InstallArea/scripts/LbLogin.sh --cmtconfig $BINARY_TAG
        export LCGPATH=$LCGPREFIX/views/LCG_83/$BINARY_TAG
        # The LbLogin sets VERBOSE to 1 which increases the compilation output. If you want details set this to 1 by hand.
        unset VERBOSE
        # Only source the lcg setup script if paths are not already set
        # (necessary because of incompatible python install in view)
        case ":$LD_LIBRARY_PATH:" in
            *":$LCGPATH/lib64:"*) :;;       # Path is present do nothing
            *) source $LCGPATH/setup.sh;;   # otherwise setup
        esac
        # This path is used below to select software versions

        echo "Software taken from $FCCSWPATH and LCG_83"
        # If podio or EDM not set locally already, take them from afs
        if [ -z "$PODIO" ]; then
            export PODIO=$FCCSWPATH/podio/0.3/$BINARY_TAG
        else
            echo "Take podio: $PODIO"
        fi
        if [ -z "$FCCEDM" ]; then
            export FCCEDM=$FCCSWPATH/fcc-edm/0.3/$BINARY_TAG
        else
            echo "Take fcc-edm: $FCCEDM"
        fi
        if [ -z "$FCCPHYSICS" ]; then
            export FCCPHYSICS=$FCCSWPATH/fcc-physics/0.1/$BINARY_TAG
        fi
        export DELPHES_DIR=$FCCSWPATH/Delphes/3.3.2/$BINARY_TAG
        export PYTHIA8_DIR=$LCGPREFIX/releases/LCG_80/MCGenerators/pythia8/212/$BINARY_TAG
        export PYTHIA8_XML=$PYTHIA8_DIR/share/Pythia8/xmldoc
        export PYTHIA8DATA=$PYTHIA8_XML
        export HEPMC_PREFIX=$LCGPATH

        # add DD4hep
        export inithere=$PWD
        cd $FCCSWPATH/DD4hep/20152311/$BINARY_TAG
        source bin/thisdd4hep.sh
        cd $inithere

        # add Geant4 data files
        if [[ $fs = 'afs' ]]; then
            source /afs/cern.ch/sw/lcg/external/geant4/10.2/setup_g4datasets.sh
        else
            source /cvmfs/geant4.cern.ch/geant4/10.2/setup_g4datasets.sh
        fi
    fi
    add_to_path LD_LIBRARY_PATH $FCCEDM/lib
    add_to_path LD_LIBRARY_PATH $PODIO/lib
    add_to_path LD_LIBRARY_PATH $PYTHIA8_DIR/lib
    add_to_path LD_LIBRARY_PATH $FCCPHYSICS/lib
elif [[ "$unamestr" == 'Darwin' ]]; then
    platform='Darwin'
    echo "Platform detected: $platform"
    add_to_path DYLD_LIBRARY_PATH $FCCEDM/lib
    add_to_path DYLD_LIBRARY_PATH $PODIO/lib
    add_to_path DYLD_LIBRARY_PATH $PYTHIA8_DIR/lib
    add_to_path DYLD_LIBRARY_PATH $FCCPHYSICS/lib
fi

# let ROOT know where the fcc-edm and -physics headers live.
add_to_path ROOT_INCLUDE_PATH $FCCEDM/include/datamodel
add_to_path ROOT_INCLUDE_PATH $FCCPHYSICS/include

add_to_path PYTHONPATH $PODIO/python

add_to_path PATH $FCCPHYSICS/bin

add_to_path CMAKE_PREFIX_PATH $FCCEDM
add_to_path CMAKE_PREFIX_PATH $PODIO
add_to_path CMAKE_PREFIX_PATH $PYTHIA8_DIR
if [ "$DELPHES_DIR" ]; then
    add_to_path CMAKE_PREFIX_PATH $DELPHES_DIR
fi
