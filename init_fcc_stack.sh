#!/bin/sh -u
# This script sets up the commonly used software for FCC software projects:
# - Linux machines at CERN:
#    The software is taken from cvmfs
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
    # FCCSW in cvmfs
    export FCCSWPATH=/cvmfs/fcc.cern.ch/sw
    
    platform='Linux'
    echo "Platform detected: $platform"
    if [[ -d "$FCCSWPATH" ]] ; then
        # Check if build type is set, if not default to release build
        if [ -z "$BUILDTYPE" ] || [[ "$BUILDTYPE" == "Release" ]]; then
            export CMAKE_BUILD_TYPE="Release"
        else
            export CMAKE_BUILD_TYPE="Debug"
        fi

        # Set up FCC Software stack from the view script
        source /cvmfs/fcc.cern.ch/sw/views/releases/0.9.0/x86_64-slc6-gcc62-opt/setup.sh
    else
        # cannot find cvmfs: so get rid of this to avoid confusion
        unset FCCSWPATH

        add_to_path LD_LIBRARY_PATH $FCCEDM/lib
        add_to_path LD_LIBRARY_PATH $PODIO/lib
        add_to_path LD_LIBRARY_PATH $PYTHIA8_DIR/lib
        add_to_path LD_LIBRARY_PATH $FCCPHYSICS/lib
    fi
elif [[ "$unamestr" == 'Darwin' ]]; then
    platform='Darwin'
    echo "Platform detected: $platform"
    add_to_path DYLD_LIBRARY_PATH $FCCEDM/lib
    add_to_path DYLD_LIBRARY_PATH $PODIO/lib
    add_to_path DYLD_LIBRARY_PATH $PYTHIA8_DIR/lib
    add_to_path DYLD_LIBRARY_PATH $FCCPHYSICS/lib
fi

# Rely on the user environment when cvmfs is not accesible
if [[ -d "$FCCSWPATH" ]] ; then 
    # let ROOT know where the fcc-edm and -physics headers live.
    add_to_path ROOT_INCLUDE_PATH $PODIO/include
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
fi

