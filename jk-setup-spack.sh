#!/bin/sh

# Create controlfile
touch controlfile

# Clone spack repo
# git clone https://github.com/LLNL/spack.git
export SPACK_ROOT=$WORKSPACE/spack

# Setup new spack home
export SPACK_HOME=$WORKSPACE
export HOME=$SPACK_HOME
export SPACK_CONFIG=$HOME/.spack

# Source environment
source $SPACK_ROOT/share/spack/setup-env.sh

# Add new repo hep-spack
#git clone https://github.com/HEP-SF/hep-spack.git $SPACK_ROOT/var/spack/repos
spack repo add $SPACK_ROOT/var/spack/repos/hep-spack
export FCC_SPACK=$SPACK_ROOT/var/spack/repos/fcc-spack

# Add new repo fcc-spack
#git clone https://github.com/JavierCVilla/fcc-spack.git $SPACK_ROOT/var/spack/repos
spack repo add $SPACK_ROOT/var/spack/repos/fcc-spack
export HEP_SPACK=$SPACK_ROOT/var/spack/repos/hep-spack

# Prepare defaults/linux configuration files (compilers and external packages)
spack compiler add
cat $FCC_SPACK/config/compiler-${COMPILER}.yaml >> $SPACK_CONFIG/linux/compilers.yaml

# Create packages
source create_packages.sh

# Overwrite packages configuration
mv packages.yaml $SPACK_CONFIG/linux/packages.yaml

gcc49version=4.9.3
gcc62version=6.2.0
export COMPILERversion=${COMPILER}version
