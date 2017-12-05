#!/bin/bash

THIS=$(dirname ${BASH_SOURCE[0]})
LCGPREFIX=/cvmfs/sft.cern.ch/lcg
LCGPATH=$LCGPREFIX/views/{{lcg_version}}/{{PLATFORM}}

function add_to_path {
    # Add the passed value only to path if it's not already in there.
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

# Setup LCG externals
source $LCGPATH/setup.sh

# Setup DD4hep
source $LCGPATH/bin/thisdd4hep.sh

# Add FCC software to the environment
# Setup PATH
add_to_path PATH $THIS/bin

# Setup LD_LIBRARY_PATH
add_to_path LD_LIBRARY_PATH $THIS/lib
add_to_path LD_LIBRARY_PATH $THIS/tests

# Setup ROOT_INCLUDE_PATH
add_to_path ROOT_INCLUDE_PATH $THIS/include
add_to_path ROOT_INCLUDE_PATH $THIS/include/datamodel

# Setup CMAKE_PREFIX_PATH (#REVIEW)
add_to_path CMAKE_PREFIX_PATH $THIS
add_to_path CMAKE_PREFIX_PATH $LCGPATH

# Setup PYTHONPATH
add_to_path PYTHONPATH $THIS/python

# Export path to the FCC view
export FCCVIEW=$THIS
