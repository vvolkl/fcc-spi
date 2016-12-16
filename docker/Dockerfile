FROM ubuntu:16.04
MAINTAINER Joschka Lingemann <joschka.lingemann@cern.ch>
ENV FCCBASE=/usr/local/fcc
ENV SPACK_ROOT=$FCCBASE/spack
RUN apt-get update && apt-get install -y cmake git python curl libtool build-essential gfortran python-yaml libpcre3 zlib1g libpng libfreetype6 liblzma5 python-libxml2 libfftw3-3 libx11-dev libxpm4 libxpm-dev libxft2 libxft-dev libxext6 libxext-dev

RUN mkdir -p $FCCBASE

WORKDIR $FCCBASE

RUN git clone https://github.com/llnl/spack $SPACK_ROOT
RUN git clone https://github.com/jlingema/fcc-spack $SPACK_ROOT/var/spack/repos/fcc-spack
RUN git clone https://github.com/jlingema/hep-spack -b fcc $SPACK_ROOT/var/spack/repos/hep-spack
RUN git clone https://github.com/jlingema/fcc-spi -b spack $FCCBASE/fcc-spi
# RUN python $FCCBASE/fcc-spi/fcc_define_stack.py -o $SPACK_ROOT/etc/spack/packages.yaml $FCCBASE/fcc-spi/docpage/_data/packages.yml 0.8pre2
RUN $SPACK_ROOT/bin/spack repo add $SPACK_ROOT/var/spack/repos/hep-spack
RUN $SPACK_ROOT/bin/spack repo add $SPACK_ROOT/var/spack/repos/fcc-spack
# RUN $SPACK_ROOT/bin/spack install fcc-physics
