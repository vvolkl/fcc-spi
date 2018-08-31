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
        --pkghash )             shift
                                pkghash=$1
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

# Detect platform
# TOOLSPATH=/cvmfs/fcc.cern.ch/sw/0.8.3/tools/
# if [[ $BUILDTYPE == *Release* ]]; then
#   export PLATFORM=`python $TOOLSPATH/hsf_get_platform.py --compiler $COMPILER --buildtype opt`
# else
#   export PLATFORM=`python $TOOLSPATH/hsf_get_platform.py --compiler $COMPILER --buildtype dbg`
# fi

# Detect os
TOOLSPATH=/cvmfs/fcc.cern.ch/sw/0.8.3/tools/
OS=`python $TOOLSPATH/hsf_get_platform.py --get os`

# Clone spack repo
git clone https://github.com/JavierCVilla/spack.git -b buildcache_fix $TMPDIR/spack
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
export compilerversion=${compiler}version

# Prepare defaults/linux configuration files (compilers and external packages)
cat $THIS/config/compiler-slc6-${compiler}.yaml > $SPACK_CONFIG/linux/compilers.yaml

# Use a default patchelf installed in fcc.cern.ch
cat $THIS/config/patchelf.yaml >> $SPACK_CONFIG/linux/packages.yaml

# Use a default slc6 compiler taken from cvmfs/sft.cern.ch
source /cvmfs/sft.cern.ch/lcg/contrib/gcc/${!compilerversion}binutils/x86_64-slc6/setup.sh

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

echo "Spack compilers: "
spack compiler list

# First need to install patchelf for relocation
spack buildcache install -y patchelf

# Install binaries from buildcache
echo "Installing $package binary"
spack buildcache install -y -f /$pkghash
result=$?

# Temporal until #6266 get fixed in spack
# Avoid problems creating views
find $prefix -type f -iname "NOTICE" | xargs rm -f
find $prefix -type f -iname "LICENSE" | xargs rm -f

# Create view
if [[ "$viewpath" != "" && "$package" != "" ]]; then
  # Check if any view already exists in the target path
  if [[ -e $viewpath ]]; then
    echo "Removing previous existing view in $viewpath"
    rm -rf $viewpath
  fi

  echo "Creating view in $viewpath"
  exceptions="py-pyyaml"

  # Exclude fccsw
  if [[ "$package" == "fccstack" ]]; then
    exceptions=$exceptions"|fccsw"
  fi

  echo "Command: spack view -d true -e $exceptions symlink -i $viewpath $package/$pkghash"
  spack view -d true -e "$exceptions" symlink $viewpath $package/$pkghash
  result=$(($result + $?))
fi

# Generate setup.sh for the view
cp $THIS/config/setup.tpl $viewpath/setup.sh

# Detect day if not set
if [[ -z ${weekday+x} ]]; then
  export weekday=`date +%a`
fi

if [[ $lcgversion == LCG_* ]]; then
  # Releases
  lcg_path="/cvmfs/fcc.cern.ch/testing/lcgview/$lcgversion/$platform"
else
  # Nightlies
  lcg_path="/cvmfs/sft.cern.ch/lcg/views/$lcgversion/$weekday/$platform"
fi

sed -i "s@{{lcg_path}}@`echo $lcg_path`@" $viewpath/setup.sh
sed -i "s/{{PLATFORM}}/`echo $platform`/" $viewpath/setup.sh
sed -i "s@{{viewpath}}@`echo $viewpath`@" $viewpath/setup.sh
result=$(($result + $?))

if [ "$cleanup" = true ]; then
  rm -rf $TMPDIR
  rm -rf /tmp/cvfcc/spack-stage
fi

# Return result (0 succeeded, otherwise failed)
echo $result
