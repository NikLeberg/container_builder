# Copyright 2023 by the SpinalHDL Docker contributors
# SPDX-License-Identifier: GPL-3.0-only
#
# Author(s): Pavel Benacek <pavel.benacek@gmail.com>
#            Leuenberger Niklaus <https://github.com/NikLeberg>

ARG UBUNTU_VERSION=22.04
FROM ubuntu:$UBUNTU_VERSION AS base

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 PATH="$PATH:/opt/bin"

ARG COURSIER_CACHE_DEFAULT="/sbt/.cache/coursier/v1"
ARG SBT_OPTS_DEFAULT="-Dsbt.override.build.repos=true -Dsbt.boot.directory=/sbt/.sbt/boot -Dsbt.global.base=/sbt/.sbt -Dsbt.ivy.home=/sbt/.ivy2 -Duser.home=/sbt -Dsbt.global.localcache=/sbt/.sbt/cache"
ENV COURSIER_CACHE=$COURSIER_CACHE_DEFAULT
ENV SBT_OPTS=$SBT_OPTS_DEFAULT

ARG DEPS_RUNTIME="ca-certificates gnupg2 openjdk-17-jdk-headless ccache curl g++ gcc git libtcl8.6 python3 python3-pip python3-pip-whl libpython3-dev ssh locales make ghdl iverilog libboost1.74-dev"
RUN apt-get update && \
    apt-get install -y --no-install-recommends $DEPS_RUNTIME

FROM base AS build-symbiyosys

ENV PREFIX=/opt
ARG DEPS_YOSYS="autoconf build-essential clang cmake libffi-dev libreadline-dev pkg-config tcl-dev unzip flex bison"
RUN apt-get install -y --no-install-recommends $DEPS_YOSYS

ARG YOSYS_VERSION="yosys-0.28"
RUN git clone https://github.com/YosysHQ/yosys.git yosys && \
    cd yosys && \
    git checkout $YOSYS_VERSION && \
    make PREFIX=$PREFIX -j$(nproc) && \
    make PREFIX=$PREFIX install && \
    cd .. && \
    rm -Rf yosys

ARG SOLVERS_PATH="snapshot-20221212/ubuntu-22.04-bin.zip"
RUN mkdir solver && cd solver && \
    curl -o solvers.zip -sL "https://github.com/GaloisInc/what4-solvers/releases/download/${SOLVERS_PATH}" && \
    unzip solvers.zip && \
    rm solvers.zip && \
    chmod +x * && \
    cp cvc4 $PREFIX/bin/cvc4 && \
    cp cvc5 $PREFIX/bin/cvc5 && \
    cp z3 $PREFIX/bin/z3 && \
    cp yices $PREFIX/bin/yices && \
    cp yices-smt2 $PREFIX/bin/yices-smt2 && \
    cd .. && rm -rf solver

ARG BOOLECTOR_VERSION="3.2.2"
RUN curl -L "https://github.com/Boolector/boolector/archive/refs/tags/$BOOLECTOR_VERSION.tar.gz" \
      | tar -xz \
    && cd boolector-$BOOLECTOR_VERSION \
    && ./contrib/setup-lingeling.sh \
    && ./contrib/setup-btor2tools.sh \
    && ./configure.sh --prefix $PREFIX \
    && make PREFIX=$PREFIX -C build -j$(nproc) \
    && make PREFIX=$PREFIX -C build install \
    && cd .. \
    && rm -Rf boolector-$BOOLECTOR_VERSION

ARG SYMBIYOSYS_VERSION="yosys-0.28"
RUN git clone https://github.com/YosysHQ/sby.git SymbiYosys && \
    cd SymbiYosys && \
    git checkout $SYMBIYOSYS_VERSION && \
    make PREFIX=$PREFIX -j$(nproc) install && \
    cd .. && \
    rm -Rf SymbiYosys

FROM base AS build-verilator

ENV PREFIX=/opt
ARG DEPS_VERILATOR="perl make autoconf g++ flex bison ccache libgoogle-perftools-dev numactl perl-doc libfl2 libfl-dev zlib1g zlib1g-dev"
RUN apt-get install -y --no-install-recommends $DEPS_VERILATOR

ARG VERILATOR_VERSION="v4.228"
RUN git clone https://github.com/verilator/verilator verilator && \
    cd verilator && \
    git checkout $VERILATOR_VERSION && \
    autoconf && \
    ./configure --prefix $PREFIX && \
    make PREFIX=$PREFIX -j$(nproc) && \
    make PREFIX=$PREFIX install && \
    cd ../.. && \
    rm -Rf verilator

FROM base AS build-spinal

# # Add repos and install sbt 
# RUN curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" \
#         | gpg2 --dearmour -o /usr/share/keyrings/sdb-keyring.gpg \
#     && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/sdb-keyring.gpg] https://repo.scala-sbt.org/scalasbt/debian all main" \
#         | tee /etc/apt/sources.list.d/sbt.list \
#     && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/sdb-keyring.gpg] https://repo.scala-sbt.org/scalasbt/debian /" \
#         | tee /etc/apt/sources.list.d/sbt_old.list \
#     && apt update && apt install sbt

ARG MILL_VERSION="0.10.9"
RUN \
  curl -L -o /usr/local/bin/mill https://github.com/lihaoyi/mill/releases/download/$MILL_VERSION/$MILL_VERSION && \
  chmod +x /usr/local/bin/mill && \
  touch build.sc && \
  mill -i resolve _ && \
  rm build.sc

FROM base AS run

RUN pip install --break-system-packages cocotb cocotb-test click && \
    pip cache purge

# Add repos and install sbt 
RUN curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" \
        | gpg2 --dearmour -o /usr/share/keyrings/sdb-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/sdb-keyring.gpg] https://repo.scala-sbt.org/scalasbt/debian all main" \
        | tee /etc/apt/sources.list.d/sbt.list \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/sdb-keyring.gpg] https://repo.scala-sbt.org/scalasbt/debian /" \
        | tee /etc/apt/sources.list.d/sbt_old.list \
    && apt update && apt install sbt && apt clean && rm -rf /var/lib/apt/lists/*

RUN git config --system --add safe.directory '*'

COPY --from=build-symbiyosys /opt /opt
COPY --from=build-verilator /opt /opt
COPY --from=build-spinal /opt /opt
COPY --from=build-spinal /usr/local/bin/mill /opt/bin/mill
# COPY --from=build-spinal /sbt /sbt