git clone https://github.com/HEP-FCC/albers-core.git -b tutorial
cd albers-core
source init.sh
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=../install ..
make -j 4 install
cd ..
./install/bin/albers-write
./install/bin/albers-read

cd ..
git clone https://github.com/HEP-FCC/fcc-edm.git -b tutorial
cd fcc-edm
source init.sh
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=../install ..
make -j 4 install
cd ..
./install/bin/fccedm-write
./install/bin/fccedm-read

cd ..
git clone https://github.com/HEP-FCC/analysis-cpp.git -b tutorial
cd analysis-cpp
source init.sh
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=../install ..
make -j 4 install
cd ..
${FCCEDM}/bin/fccedm-write
./install/bin/analysiscpp-read    
${FCCEDM}/bin/fccedm-write
root example-lib/test_macro.C
