#!/bin/bash
THIS=$(dirname ${BASH_SOURCE[0]})

# Check all needed variable are defined
[[ "${LCG_VERSION:?Need to set LCG_VERSION non-empty}" &&
   "${FCC_VERSION:?Need to set FCC_VERSION non-empty}" &&
   "${PLATFORM:?Need to set PLATFORM non-empty}" ]]

# Detect day if not set
if [[ -z ${weekday+x} ]]; then
 export weekday=`date +%a`
fi

if [[ $LCG_VERSION == LCG_* ]]; then
  LCG_externals="/cvmfs/sft.cern.ch/lcg/releases/$LCG_VERSION/LCG_*_${PLATFORM}.txt"
else
  LCG_externals="/cvmfs/sft.cern.ch/lcg/nightlies/$LCG_VERSION/$weekday/LCG_*_${PLATFORM}.txt"
fi

echo "Using LCG externals from: $LCG_externals"
echo "Modification date: `stat $LCG_externals | grep Modify | tr -s " " | cut -d" " -f2,3`"

python $THIS/create_lcg_package_specs.py --blacklist $THIS/config/packages-${FCC_VERSION}.yaml "$LCG_externals"

cp $THIS/config/packages-default.yaml $WORKSPACE/packages.yaml

# apply some changes
# Replace tbb name
sed -i 's/tbb:/intel-tbb:/' $WORKSPACE/${LCG_VERSION}_packages.yaml
sed -i 's/tbb@/intel-tbb@/' $WORKSPACE/${LCG_VERSION}_packages.yaml

# Replace xerces-c name
sed -i 's/xercesc:/xerces-c:/' $WORKSPACE/${LCG_VERSION}_packages.yaml
sed -i 's/xercesc@/xerces-c@/' $WORKSPACE/${LCG_VERSION}_packages.yaml

# Replace java name
sed -i 's/java:/jdk:/' $WORKSPACE/${LCG_VERSION}_packages.yaml
sed -i 's/java@/jdk@/' $WORKSPACE/${LCG_VERSION}_packages.yaml

# append lcg specs to default packages.yaml
cat $WORKSPACE/${LCG_VERSION}_packages.yaml | tail -n +2 >> $WORKSPACE/packages.yaml
cat $THIS/config/packages-${FCC_VERSION}.yaml >> $WORKSPACE/packages.yaml

# Custom packages

# Gitpython python package #TODO consider treatment for other platforms
cat << EOF >> $WORKSPACE/packages.yaml
  py-gitpython:
    buildable: false
    paths: {py-gitpython@2.1.8-0%gcc@6.2.0 arch=x86_64-scientificcernslc6: /cvmfs/fcc.cern.ch/sw/0.8.3/gitpython/lib/python2.7/site-packages}
EOF
