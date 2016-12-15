FROM ubuntu:16.04
MAINTAINER Joschka Lingemann <joschka.lingemann@cern.ch>
ENV FCCBASE=/usr/local/fcc
ENV SPACK_ROOT=$FCCBASE/spack
RUN apt-get update && apt-get install -y cmake git python curl libtool build-essential zlib1g-dev libncurses5

RUN mkdir -p $FCCBASE

WORKDIR $FCCBASE

RUN git clone https://github.com/llnl/spack $SPACK_ROOT
RUN git clone https://github.com/jlingema/fcc-spack $SPACK_ROOT/var/spack/repos/fcc-spack
RUN git clone https://github.com/jlingema/hep-spack -b fcc $SPACK_ROOT/var/spack/repos/hep-spack
RUN git clone https://github.com/jlingema/fcc-spi -b spack
RUN python fcc-spi/fcc_define_spack
RUN $SPACK_ROOT/bin/spack repo add $SPACK_ROOT/var/spack/repos/hep-spack
RUN $SPACK_ROOT/bin/spack repo add $SPACK_ROOT/var/spack/repos/fcc-spack
RUN $SPACK_ROOT/bin/spack install --dirty fcc-physics
