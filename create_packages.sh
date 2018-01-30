#!/bin/bash
THIS=$(dirname ${BASH_SOURCE[0]})

LCG_version=$1
weekday=`date +%a`

if [[ $LCG_version == LCG_* ]]; then
  LCG_externals="/cvmfs/sft.cern.ch/lcg/releases/$LCG_version/LCG_externals_x86_64-slc6-gcc62-opt.txt"
else
  LCG_externals="/cvmfs/sft.cern.ch/lcg/nightlies/$LCG_version/$weekday/LCG_externals_x86_64-slc6-gcc62-opt.txt"
fi

echo "Using LCG externals from: $LCG_externals"
echo "Modification date: `stat $LCG_externals | grep Modify | tr -s " " | cut -d" " -f2,3`"

python $THIS/create_lcg_package_specs.py $LCG_externals

cp $THIS/config/packages-default.yaml $WORKSPACE/packages.yaml

# apply some changes
# Replace tbb name
sed -i 's/tbb:/intel-tbb:/' $WORKSPACE/${LCG_version}_packages.yaml
sed -i 's/tbb@/intel-tbb@/' $WORKSPACE/${LCG_version}_packages.yaml

# Replace xerces-c name
sed -i 's/xercesc:/xerces-c:/' $WORKSPACE/${LCG_version}_packages.yaml
sed -i 's/xercesc@/xerces-c@/' $WORKSPACE/${LCG_version}_packages.yaml

# Replace java name
sed -i 's/java:/jdk:/' $WORKSPACE/${LCG_version}_packages.yaml
sed -i 's/java@/jdk@/' $WORKSPACE/${LCG_version}_packages.yaml

# append lcg specs to default packages.yaml
cat $WORKSPACE/${LCG_version}_packages.yaml | tail -n +2 >> $WORKSPACE/packages.yaml
cat $THIS/config/packages-${FCC_VERSION}.yaml >> $WORKSPACE/packages.yaml

# Custom packages

# Gitpython python package
cat << EOF >> $WORKSPACE/packages.yaml
  py-gitpython:
    buildable: false
    paths: {py-gitpython@2.1.8-0%gcc@6.2.0 arch=x86_64-scientificcernslc6: /cvmfs/fcc.cern.ch/sw/0.8.3/gitpython/lib/python2.7/site-packages}
EOF
