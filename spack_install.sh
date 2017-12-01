#!/bin/sh

usage()
{
    echo "usage: spack_install.sh [[[-p, --prefix directory ] [-m, --mirror directory]] | [-h]]"
}

# Parsing arguments
while [ "$1" != "" ]; do
    case $1 in
        -p | --prefix )         shift
                                prefix=$1
                                ;;
        -b | --buildcache )     shift
                                buildcache=$1
                                ;;
        --package )             shift
                                package=$1
                                ;;
        -v | --viewpath )       shift
                                viewpath=$1
                                ;;
        -l | --lcgversion )     shift
                                lcgversion=$1
                                ;;
        --platform )       shift
                                platform=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

# Create controlfile
touch controlfile
THIS=$(dirname ${BASH_SOURCE[0]})

if [ "$WORKSPACE" == "" ]; DO
  WORKSPACE=/tmp/fcc/spackinstall
  mkdir -p $WORKSPACE
fi

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
git clone https://github.com/HEP-SF/hep-spack.git $SPACK_ROOT/var/spack/repos
spack repo add $SPACK_ROOT/var/spack/repos/hep-spack
export FCC_SPACK=$SPACK_ROOT/var/spack/repos/fcc-spack

# Add new repo fcc-spack
git clone https://github.com/JavierCVilla/fcc-spack.git $SPACK_ROOT/var/spack/repos
spack repo add $SPACK_ROOT/var/spack/repos/fcc-spack
export HEP_SPACK=$SPACK_ROOT/var/spack/repos/hep-spack

gcc49version=4.9.3
gcc62version=6.2.0
export COMPILERversion=${COMPILER}version

# Prepare defaults/linux configuration files (compilers and external packages)
spack compiler add

# Ensure there is only one compiler with the same compiler spec
sed -i "s/spec: gcc@`echo ${!COMPILERversion}`/spec: gcc@${!COMPILERversion}other/" $SPACK_CONFIG/linux/compilers.yaml

cat $THIS/config/compiler-${COMPILER}.yaml >> $SPACK_CONFIG/linux/compilers.yaml

# Create mirrors.yaml to use local buildcache
cp $THIS/config/mirrors.tpl $SPACK_CONFIG/linux/mirrors.yaml
sed -i "s/{{CACHE_PATH}}/`echo $cachepath`/" $SPACK_CONFIG/linux/mirrors.yaml

# Create config.yaml to define new prefix
cp $THIS/config/config.tpl $SPACK_CONFIG/linux/config.yaml
sed -i "s/{{PREFIX_PATH}}/`echo $prefix`/" $SPACK_CONFIG/linux/config.yaml

# Install binaries from buildcache
spack buildcache -y install $package

# Create view
excepcions="py-pyyaml"
spack view -d true -e $exceptions symlink $viewpath $package

# Generate setup.sh for the view
cp $THIS/config/setup.tpl $viewpath/setup.sh
sed -i "s/{{lcg_version}}/`echo $lcgversion`/" $viewpath/setup.sh
sed -i "s/{{PLATFORM}}/`echo $platform`/" $viewpath/setup.sh
