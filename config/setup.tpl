#!/bin/bash

LCGPREFIX=/cvmfs/sft.cern.ch/lcg
LCGPATH={{lcg_path}}

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

# if [[ $BASH == "" ]]; then
#   THIS_DIR=$(dirname $0)
# else
#   THIS_DIR=$(dirname ${BASH_SOURCE[0]})
# fi
THIS_DIR={{viewpath}}

# Setup DD4hep from FCC view if exists, otherwise from LCG view
if [[ -x $THIS_DIR/bin/thisdd4hep.sh ]]; then
    source $THIS_DIR/bin/thisdd4hep_only.sh
else
    source $LCGPATH/bin/thisdd4hep_only.sh
fi

export BINARY_TAG={{PLATFORM}}

export DELPHES_DIR=$LCGPATH
export PYTHIA8_DIR=$LCGPATH
export PYTHIA8_XML=$LCGPATH/share/Pythia8/xmldoc
export PYTHIA8DATA=$PYTHIA8_XML
export HEPMC_PREFIX=$LCGPATH

# Setup heppy
source $THIS_DIR/lib/python*/site-packages/heppy/init.sh
add_to_path PYTHONPATH /cvmfs/fcc.cern.ch/sw/0.8.3/gitpython/lib/python2.7/site-packages

# Add FCC software to the environment
# Setup PATH
add_to_path PATH $THIS_DIR/bin

# Setup LD_LIBRARY_PATH
add_to_path LD_LIBRARY_PATH $THIS_DIR/lib
add_to_path LD_LIBRARY_PATH $THIS_DIR/tests

# Setup ROOT_INCLUDE_PATH
add_to_path ROOT_INCLUDE_PATH $THIS_DIR/include
add_to_path ROOT_INCLUDE_PATH $THIS_DIR/include/datamodel

# Setup CMAKE_PREFIX_PATH (#REVIEW)
add_to_path CMAKE_PREFIX_PATH $THIS_DIR
add_to_path CMAKE_PREFIX_PATH $LCGPATH

# Setup PYTHONPATH
add_to_path PYTHONPATH $THIS_DIR/python

# Setup cmake from LCG contrib
# Temporal change to fix a bug at configuration time with FCCSW when
# using the cmake version provided by LCG release, which differs 
# from the one used to build the LCG stack itself 
# For the LCG_94 should be solved 

export PATH=$LCGPREFIX/contrib/CMake/3.8.1/Linux-x86_64/bin:${PATH}

# Export path to the FCC view
export FCCVIEW=$THIS_DIR
