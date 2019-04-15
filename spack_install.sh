#!/bin/sh

usage()
{
    if [[ -n "$1" ]]; then
       echo "unexpected parameter: $1"
    fi
    echo "usage: spack_install.sh [options] [-h]"
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
        -c | --compiler )       shift
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
        --branch )              shift
                                branch=$1
                                ;;
        --clean )               cleanup=true
                                ;;
        --weekday )              shift
                                weekday=$1
                                ;;
        --spack-tag )           spacktag=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage $1
                                exit 1
    esac
    shift
done

update_latest(){
  package=$1
  lcgversion=$2

  if [[ "$package" == "fccstack" ]]; then
    installation="fccsw"
  else
    installation="externals"
  fi

  if [[ $prefix == *releases* ]]; then
    # Releases
    buildtype="releases"
  else
    buildtype="nightlies"
  fi

  FROM=/cvmfs/fcc.cern.ch/sw/views/$buildtype/$installation/latest
  TO=$viewpath

  ln -sf $TO $FROM
}

check_error()
{
    local last_exit_code=$1
    local last_cmd=$2
    if [[ ${last_exit_code} -ne 0 ]]; then
        echo "${last_cmd} exited with code ${last_exit_code}"
        echo "TERMINATING JOB"
        exit 1
    else
        echo "${last_cmd} completed successfully"
    fi
}


# Create controlfile
touch controlfile
THIS=$(dirname ${BASH_SOURCE[0]})

if [ "$TMPDIR" == "" ]; then
  TMPDIR=$HOME/spackinstall
  mkdir -p $TMPDIR
fi
echo "Temporary directory: $TMPDIR"

# Clean previous .spack configuration if exists
rm -rf $TMPDIR/.spack

# split original platform string into array using '-' as a separator
# example: x86_64-slc6-gcc62-opt
TARGET_PLATFORM="$platform"

IFS=- read -ra PART <<< "$platform"
TARGET_ARCH="${PART[0]}"
TARGET_OS="${PART[1]}"
TARGET_COMPILER="${PART[2]}"
TARGET_MODE="${PART[3]}"

echo "Target Platform information"
echo "Architecture: $TARGET_ARCH"
echo "Operating System: $TARGET_OS"
echo "Compiler: $TARGET_COMPILER"
echo "Mode: $TARGET_MODE"

# Detect host platform
# Need to use a compiler compatible with the Operating system where the job is
# running, even if the set of packages to be installed were built on a different
# platform.
TOOLSPATH=/cvmfs/fcc.cern.ch/sw/0.8.3/tools/
if [[ $TARGET_MODE == *opt* ]]; then
  export PLATFORM=`python $TOOLSPATH/hsf_get_platform.py --compiler $TARGET_COMPILER --buildtype opt`
else
  export PLATFORM=`python $TOOLSPATH/hsf_get_platform.py --compiler $TARGET_COMPILER --buildtype dbg`
fi

if [[ $PLATFORM != $platform ]]; then
  echo "Replacing platform, from: $platform, to: $PLATFORM"
  platform=$PLATFORM
fi

# assign new platform values
IFS=- read -ra PART <<< "$platform"
ARCH="${PART[0]}"
OS="${PART[1]}"
PLATFORMCOMPILER="${PART[2]}"
MODE="${PART[3]}"

echo "Host Platform information (where this job is running)"
echo "Architecture: $ARCH"
echo "Operating System: $OS"
echo "Compiler: $PLATFORMCOMPILER"
echo "Mode: $MODE"

# Clone spack repo

# Use develop if there is no tags specified (use tags to reproduce releases)
if [[ "$spacktag" == "" ]]; then
   spacktag="develop"
fi

echo "Cloning spack repo"
echo "git clone https://github.com/HEP-FCC/spack.git -b $spacktag $TMPDIR/spack"
git clone https://github.com/HEP-FCC/spack.git -b $spacktag $TMPDIR/spack
check_error $? "cloning spack repo from branch/tag: $spacktag"
export SPACK_ROOT=$TMPDIR/spack

# Setup new spack home
export SPACK_HOME=$TMPDIR
export HOME=$SPACK_HOME
export SPACK_CONFIG=$HOME/.spack

# Source environment
echo "Preparing spack environment"
source $SPACK_ROOT/share/spack/setup-env.sh

# Add new repo hep-spack
echo "Cloning hep-spack repo"
echo "git clone https://github.com/HEP-SF/hep-spack.git $SPACK_ROOT/var/spack/repos/hep-spack"
git clone https://github.com/HEP-SF/hep-spack.git $SPACK_ROOT/var/spack/repos/hep-spack
spack repo add $SPACK_ROOT/var/spack/repos/hep-spack
export FCC_SPACK=$SPACK_ROOT/var/spack/repos/fcc-spack

# Add new repo fcc-spack
echo "Cloning fcc-spack repo"
echo "git clone --branch $branch https://github.com/HEP-FCC/fcc-spack.git $SPACK_ROOT/var/spack/repos/    fcc-spack"
git clone --branch $branch https://github.com/HEP-FCC/fcc-spack.git $SPACK_ROOT/var/spack/repos/fcc-spack
spack repo add $SPACK_ROOT/var/spack/repos/fcc-spack
export HEP_SPACK=$SPACK_ROOT/var/spack/repos/hep-spack

gcc49version=4.9.3
gcc62version=6.2.0
gcc73version=7.3.0
gcc8version=8.2.0

if [[ "$PLATFORMCOMPILER" != "$compiler"  ]]; then
   echo "ERROR: Platform compiler (${PLATFORMCOMPILER}) and selected compiler (${compiler}) do not match"
   exit 1
fi

export compilerversion=${compiler}version

# Prepare defaults/linux configuration files (compilers and external packages)
# Add compiler compatible with the host platform
cat $THIS/config/compiler-${OS}-${PLATFORMCOMPILER}.yaml > $SPACK_CONFIG/linux/compilers.yaml

# Add compiler compatible with the target platform (without head line)
if [[ "$OS-$PLATFORMCOMPILER" != "$TARGET_OS-$TARGET_COMPILER" ]]; then
  cat $THIS/config/compiler-${TARGET_OS}-${TARGET_COMPILER}.yaml | tail -n +2 >> $SPACK_CONFIG/linux/compilers.yaml
fi

cat $THIS/config/config.yaml > $SPACK_CONFIG/config.yaml

# Use a default patchelf installed in fcc.cern.ch
# spack buildcache tries to install it if it is not found
cat $THIS/config/patchelf.yaml >> $SPACK_CONFIG/linux/packages.yaml

# Use a default compiler taken from cvmfs/sft.cern.ch
source /cvmfs/sft.cern.ch/lcg/contrib/gcc/${!compilerversion}binutils/x86_64-${OS}/setup.sh

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

# General configuration
echo "Spack Configuration: "
spack config get config

# List of known compilers
echo "Compiler Configurations:"
spack config get compilers

# First need to install patchelf for relocation
# spack buildcache install -u patchelf
# check_error $? "spack buildcache install patchelf"

# Install binaries from buildcache
echo "Installing $package binary"
spack buildcache install -u -f -a /$pkghash
check_error $? "spack buildcache install ($pkgname)/$pkghash"

# Detect day if not set
if [[ -z ${weekday+x} ]]; then
  export weekday=`date +%a`
fi

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

  echo "Command: spack view -d true -e $exceptions symlink -i $viewpath /$pkghash"
  spack view -d true -e "$exceptions" symlink $viewpath /$pkghash
  viewcreated=$?
  check_error $(($result + $viewcreated)) "create view"
  if [ $viewcreated -eq 0 ];then
    # Update latest link
    update_latest $package $lcgversion
    check_error $? "update latest link"
  fi
fi

# Generate setup.sh for the view
cp $THIS/config/setup.tpl $viewpath/setup.sh

# Patch to link againts custom LCG Views
if [[ $lcgversion == LCG_* ]]; then
  # Releases
  #lcg_path="/cvmfs/fcc.cern.ch/testing/lcgview/$lcgversion/$platform"
  lcg_path=/cvmfs/sft.cern.ch/lcg/views/$lcgversion/$TARGET_PLATFORM
else
  # Nightlies
  lcg_path="/cvmfs/sft.cern.ch/lcg/views/$lcgversion/$weekday/$TARGET_PLATFORM"
fi

sed -i "s@{{lcg_path}}@`echo $lcg_path`@" $viewpath/setup.sh
sed -i "s/{{PLATFORM}}/`echo $TARGET_PLATFORM`/" $viewpath/setup.sh
sed -i "s@{{viewpath}}@`echo $viewpath`@" $viewpath/setup.sh
check_error $? "generate setup.sh"

if [ "$cleanup" = true ]; then
  echo "Cleanup"
  rm -rf $TMPDIR
  echo "Removed $TMPDIR"
  rm -rf /tmp/$USER/spack-stage
  echo "Removed /tmp/$USER/spack-stage"
fi

echo "End of build"
