#!/bin/bash

#PLATFORM=`$THIS/getPlatform.py`
PLATFORM="x86_64-slc6-gcc62-opt"
LCG_version="LCG_88"
root_version="6.08.06"
root_path="/cvmfs/sft.cern.ch/lcg/releases/${LCG_version}/ROOT/${root_version}/${PLATFORM}"

weekday=`date +%a`
dev4_latest="/cvmfs/sft.cern.ch/lcg/nightlies/dev4/${weekday}/LCG_externals_x86_64-slc6-gcc62-opt.txt"

python create_lcg_package_specs.py $dev4_latest

cp config/packages-default.yaml packages.yaml

# apply some changes
# Replace tbb name
sed -i 's/tbb:/intel-tbb/' ${weekday}_packages_cvmfs.yaml
sed -i 's/tbb%gcc/intel-tbb%gcc/' ${weekday}_packages_cvmfs.yaml

# Replabe java name
sed -i 's/java:/jdk/' ${weekday}_packages_cvmfs.yaml
sed -i 's/java%gcc/jdk%gcc/' ${weekday}_packages_cvmfs.yaml

sed -i "s#paths: {root@.*}#paths: {root@6.08.06%gcc@6.2.0 arch=x86_64-scientificcernslc6: `echo $root_path`}#" ${weekday}_packages_cvmfs.yaml

# append lcg specs to default packages.yaml
cat ${weekday}_packages_cvmfs.yaml | tail -n +2 >> packages.yaml
cat packages-stable.yaml >> packages.yaml
