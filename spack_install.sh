#!/bin/sh

usage()
{
    echo "usage: spack_install.sh [[[-p, --prefix directory ] [-m, --mirror directory]] | [-h]]"
}

# Dont cleanup by default
cleanup=false

# Parsing arguments
while [ "$1" != "" ]; do
    case $1 in
        -p | --prefix )         shift
                                prefix=$1
                                ;;
        -b | --buildcache )     shift
                                buildcache=$1
                                ;;
	      -c | --compiler )	      shift
				                        compiler=$1
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
        --platform )            shift
                                platform=$1
                                ;;
        --clean )               cleanup=true
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

if [ "$TMPDIR" == "" ]; then
  TMPDIR=/tmp/fcc/spackinstall
  mkdir -p $TMPDIR
fi

# Clone spack repo
git clone https://github.com/JavierCVilla/spack.git -b builcache_fix $TMPDIR/spack
export SPACK_ROOT=$TMPDIR/spack

# Setup new spack home
export SPACK_HOME=$TMPDIR
export HOME=$SPACK_HOME
export SPACK_CONFIG=$HOME/.spack

# Source environment
echo "Preparing spack environment"
source $SPACK_ROOT/share/spack/setup-env.sh

# Add new repo hep-spack
git clone https://github.com/HEP-SF/hep-spack.git $SPACK_ROOT/var/spack/repos/hep-spack
spack repo add $SPACK_ROOT/var/spack/repos/hep-spack
export FCC_SPACK=$SPACK_ROOT/var/spack/repos/fcc-spack

# Add new repo fcc-spack
git clone https://github.com/JavierCVilla/fcc-spack.git $SPACK_ROOT/var/spack/repos/fcc-spack
spack repo add $SPACK_ROOT/var/spack/repos/fcc-spack
export HEP_SPACK=$SPACK_ROOT/var/spack/repos/hep-spack

gcc49version=4.9.3
gcc62version=6.2.0
export COMPILERversion=${compiler}version

# Prepare defaults/linux configuration files (compilers and external packages)
spack compiler add

# Ensure there is only one compiler with the same compiler spec
sed -i "s/spec: gcc@`echo ${!COMPILERversion}`/spec: gcc@${!COMPILERversion}other/" $SPACK_CONFIG/linux/compilers.yaml

cat $THIS/config/compiler-${compiler}.yaml >> $SPACK_CONFIG/linux/compilers.yaml

# Use a default patchelf installed in fcc.cern.ch
cat $THIS/config/patchelf.yaml >> $SPACK_CONFIG/linux/packages.yaml

# Use a default compiler taken from cvmfs/sft.cern.ch
source /cvmfs/sft.cern.ch/lcg/contrib/gcc/6.2.0binutils/x86_64-slc6/setup.sh

# Create mirrors.yaml to use local buildcache
if [ "$buildcache" != "" ]; then
  spack mirror add local_buildcache $buildcache
fi

echo "Mirror configuration:"
spack mirror list

# Create config.yaml to define new prefix
if [ "$prefix" != "" ]; then
  cp $THIS/config/config.tpl $SPACK_CONFIG/linux/config.yaml
  sed -i "s#{{PREFIX_PATH}}#`echo $prefix`#" $SPACK_CONFIG/linux/config.yaml
fi

echo "Spack configuration: "
spack config get config

# First need to install patchelf for relocation
spack buildcache install -y patchelf

# Install binaries from buildcache
spack buildcache install -y $package
result=$?

# Create view
if [[ "$viewpath" != "" && "$package" != "" ]]; then
  exceptions="py-pyyaml"
  spack view -d true -e $exceptions symlink $viewpath $package
  result=$(($result + $?))
fi

# Generate setup.sh for the view
cp $THIS/config/setup.tpl $viewpath/setup.sh
sed -i "s/{{lcg_version}}/`echo $lcgversion`/" $viewpath/setup.sh
sed -i "s/{{PLATFORM}}/`echo $platform`/" $viewpath/setup.sh
result=$(($result + $?))

if [ "$cleanup" = true ]; then
  rm -rf $TMPDIR
fi

# Return result (0 succeeced, otherwise failed)
echo $result
