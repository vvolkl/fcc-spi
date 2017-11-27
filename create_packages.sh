#!/bin/bash
THIS=$(dirname ${BASH_SOURCE[0]})

#PLATFORM=`$THIS/getPlatform.py`
#PLATFORM="x86_64-slc6-gcc62-opt"
LCG_version="LCG_91"
#root_version="6.08.06"
#root_path="/cvmfs/sft.cern.ch/lcg/releases/${LCG_version}/ROOT/${root_version}/${PLATFORM}"

#weekday=`date +%a`
#dev4_latest="/cvmfs/sft.cern.ch/lcg/nightlies/dev4/${weekday}/LCG_externals_x86_64-slc6-gcc62-opt.txt"

LCG_externals="/cvmfs/sft.cern.ch/lcg/releases/LCG_91/LCG_externals_x86_64-slc6-gcc62-opt.txt"

python $THIS/create_lcg_package_specs.py $LCG_externals

cp $THIS/config/packages-default.yaml $WORKSPACE/packages.yaml

# apply some changes
# Replace tbb name
sed -i 's/tbb:/intel-tbb:/' $WORKSPACE/${LCG_version}_packages.yaml
sed -i 's/tbb@/intel-tbb@/' $WORKSPACE/${LCG_version}_packages.yaml

# Replabe java name
sed -i 's/java:/jdk:/' $WORKSPACE/${LCG_version}_packages.yaml
sed -i 's/java@/jdk@/' $WORKSPACE/${LCG_version}_packages.yaml

if [[ "${BUILDMODE}" == "nightly" ]]; then
  sed -i "s/root@v6-10-00-patches/root@6.10.00-patches/" $WORKSPACE/${LCG_version}_packages.yaml
fi

# append lcg specs to default packages.yaml
cat $WORKSPACE/${LCG_version}_packages.yaml | tail -n +2 >> $WORKSPACE/packages.yaml
cat $THIS/config/packages-stable.yaml >> $WORKSPACE/packages.yaml
