#!/bin/bash
THIS=$(dirname ${BASH_SOURCE[0]})

#PLATFORM=`$THIS/getPlatform.py`
#PLATFORM="x86_64-slc6-gcc62-opt"
LCG_version=$1
#root_version="6.08.06"
#root_path="/cvmfs/sft.cern.ch/lcg/releases/${LCG_version}/ROOT/${root_version}/${PLATFORM}"

LCG_externals="/cvmfs/sft.cern.ch/lcg/releases/$LCG_version/LCG_externals_x86_64-slc6-gcc62-opt.txt"

python $THIS/create_lcg_package_specs.py $LCG_externals

cp $THIS/config/packages-default.yaml $WORKSPACE/packages.yaml

# apply some changes
# Replace tbb name
sed -i 's/tbb:/intel-tbb:/' $WORKSPACE/${LCG_version}_packages.yaml
sed -i 's/tbb@/intel-tbb@/' $WORKSPACE/${LCG_version}_packages.yaml

# Replace xerces-c name
sed -i 's/xercesc:/xerces-c:/' $WORKSPACE/${LCG_version}_packages.yaml
sed -i 's/xercesc@/xerces-c@/' $WORKSPACE/${LCG_version}_packages.yaml

# Replabe java name
sed -i 's/java:/jdk:/' $WORKSPACE/${LCG_version}_packages.yaml
sed -i 's/java@/jdk@/' $WORKSPACE/${LCG_version}_packages.yaml

if [[ "${BUILDMODE}" == "nightly" ]]; then
  sed -i "s/root@v6-10-00-patches/root@6.10.00-patches/" $WORKSPACE/${LCG_version}_packages.yaml
fi

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
