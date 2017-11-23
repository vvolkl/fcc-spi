#!/bin/bash
THIS=$(dirname ${BASH_SOURCE[0]})

#PLATFORM=`$THIS/getPlatform.py`
PLATFORM="x86_64-slc6-gcc62-opt"
LCG_version="LCG_88"
root_version="6.08.06"
root_path="/cvmfs/sft.cern.ch/lcg/releases/${LCG_version}/ROOT/${root_version}/${PLATFORM}"

weekday=`date +%a`
dev4_latest="/cvmfs/sft.cern.ch/lcg/nightlies/dev4/${weekday}/LCG_externals_x86_64-slc6-gcc62-opt.txt"

python $THIS/create_lcg_package_specs.py $dev4_latest

cp $THIS/config/packages-default.yaml $THIS/packages.yaml

# apply some changes
# Replace tbb name
sed -i 's/tbb:/intel-tbb/' $WORKSPACE/${weekday}_packages.yaml
sed -i 's/tbb%gcc/intel-tbb%gcc/' $WORKSPACE/${weekday}_packages.yaml

# Replabe java name
sed -i 's/java:/jdk/' $WORKSPACE/${weekday}_packages.yaml
sed -i 's/java%gcc/jdk%gcc/' $WORKSPACE/${weekday}_packages.yaml

sed -i "s#paths: {root@.*}#paths: {root@6.08.06%gcc@6.2.0 arch=x86_64-scientificcernslc6: `echo $root_path`}#" $WORKSPACE/${weekday}_packages.yaml

# append lcg specs to default packages.yaml
cat $WORKSPACE/${weekday}_packages.yaml | tail -n +2 >> $WORKSPACE/packages.yaml
cat $THIS/config/packages-stable.yaml >> $WORKSPACE/packages.yaml
