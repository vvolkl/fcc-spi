#!/bin/sh
function build {
    cd ${1}
    mkdir build;cd build
    out="$(cmake -DCMAKE_INSTALL_PREFIX=../install ..)"
    rc=$?
    if [[ $rc != 0 ]]; then
      echo "${out}"
      exit $rc
    fi
    out="$(make -j4 install)"
    rc=$?
    if [[ $rc != 0 ]]; then
      echo "${out}"
      exit $rc
    fi
    cd ../../
    echo "- ${1} done"
}

export user="HEP-FCC"
export branch="master"
export workdir="test"
mkdir $workdir
cd $workdir

######################################################################
echo "Get all repos"
######################################################################
git clone https://github.com/$user/podio.git -b $branch
git clone https://github.com/$user/fcc-edm.git -b $branch
git clone https://github.com/$user/fcc-physics.git -b $branch
git clone https://github.com/$user/heppy.git -b $branch
git clone https://github.com/$user/FCCSW.git -b $branch

######################################################################
echo "Setup environment"
######################################################################
# make sure we take the local installs of podio and fcc-edm
export PODIO=$PWD/podio/install
export FCCEDM=$PWD/fcc-edm/install
export FCCPHYSICS=$PWD/fcc-physics/install
source ../init_fcc_stack.sh
cd heppy
source ./init.sh
cd ..

######################################################################
echo "Build all repos"
######################################################################
build "podio"
build "fcc-edm"
build "fcc-physics"
cd FCCSW
out="$(make -j12)"
rc=$?
if [[ $rc != 0 ]]; then
  echo "${out}"
  exit $rc
fi
echo "- FCCSW done"
cd ..

######################################################################
echo "Test FCCSW-Delphes -> fcc-physics"
######################################################################
cd FCCSW
./run gaudirun.py Sim/SimDelphesInterface/options/PythiaDelphes_config.py
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
mv FCCDelphesOutput.root ../fcc-physics/example.root
cd ../fcc-physics
./install/bin/fcc-physics-read-delphes
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
cd ..

######################################################################
echo "Test fcc-physics-pythia8 -> heppy"
######################################################################
cd fcc-physics
./install/bin/fcc-pythia8-generate ./pythia8/ee_ZH_Zmumu_Hbb.txt
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
mv ee_ZH_Zmumu_Hbb.root ../heppy/test/zh_zmumu_hbb.root
cd ../heppy/test
heppy_loop.py Trash analysis_ee_ZH_cfg.py -f
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
cd ../..
