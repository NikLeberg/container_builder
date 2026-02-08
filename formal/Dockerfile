FROM ubuntu:24.04 AS builder

ARG YOSYS_VERSION=v0.62
ARG GHDL_VERSION=v5.1.1
ARG PLUGIN_VERSION=07a30ed
ARG SBY_VERSION=v0.62
ARG Z3_VERSION=4.15.5
ARG Z3_GLIBC_VERSION=2.39
ARG Z3_SHA=e70681818b7fcdf2be66c5931c8f5b0cdc2d3752
ARG YICES2_VERSION=yices-2.7.0

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Install build tools.
RUN <<EOF
    set -e
    apt-get -q -y update
    ## yosys
    apt-get -q -y install \
        build-essential \
        bison \
        flex \
        gawk \
        pkg-config \
        libreadline-dev \
        zlib1g-dev \
        tcl-dev \
        clang \
        git
    ## GHDL
    apt-get -q -y install \
        make \
        gcc \
        llvm \
        clang \
        gnat \
        libz-dev \
        git
    ## ghdl-yosys-plugin
    apt-get -q -y install \
        make \
        llvm \
        clang \
        git
    ## sby
    apt-get -q -y install \
        python3 \
        python3-click
    ## z3
    apt-get -q -y install \
        wget \
        unzip
    ## yices2
    apt-get -q -y install \
        clang \
        gperf \
        libgmp10-dev \
        autoconf \
        make
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Build yosys from source.
ARG YOSYS_GIT_URL=https://github.com/YosysHQ/yosys.git
RUN <<EOF
    set -e
    git clone $YOSYS_GIT_URL -b $YOSYS_VERSION --depth 1 \
        --recurse-submodules --shallow-submodules
    cd yosys
    make config-clang
    make -j $(nproc)
    make DESTDIR=/opt/yosys install
EOF

# Build GHDL from source.
ARG GHDL_GIT_URL=https://github.com/ghdl/ghdl.git
RUN <<EOF
    set -e
    git clone $GHDL_GIT_URL -b $GHDL_VERSION --depth 1
    mkdir ghdl/build
    cd ghdl/build
    ../configure --prefix=/opt/ghdl \
        --with-llvm-config \
        --with-llvm-jit \
        --enable-checks \
        --enable-libghdl \
        --enable-synth
    make -j $(nproc)
    make install
EOF

# Build ghdl-yosys-plugin from source.
ARG PLUGIN_GIT_URL=https://github.com/ghdl/ghdl-yosys-plugin.git
RUN <<EOF
    set -e
    git clone $PLUGIN_GIT_URL
    cd ghdl-yosys-plugin
    git reset $PLUGIN_VERSION --hard
    make GHDL=/opt/ghdl/bin/ghdl YOSYS_CONFIG=/opt/yosys/usr/local/bin/yosys-config CFLAGS="-I /opt/yosys/usr/local/share/yosys/include"
    mkdir -p /opt/plugin/usr/local/share/yosys/plugins/
    cp ghdl.so /opt/plugin/usr/local/share/yosys/plugins/ghdl.so
EOF

## Build sby from source.
ARG SBY_GIT_URL=https://github.com/YosysHQ/sby.git
RUN <<EOF
    set -e
    git clone $SBY_GIT_URL -b $SBY_VERSION --depth 1
    cd sby
    make DESTDIR=/opt/sby install
EOF

## Download Z3 theorem solver.
ARG Z3_RELEASE_URL=https://github.com/Z3Prover/z3/releases/download/z3-$Z3_VERSION/z3-$Z3_VERSION-x64-glibc-$Z3_GLIBC_VERSION.zip
RUN <<EOF
    set -e
    wget --progress=dot:giga $Z3_RELEASE_URL -O z3.zip
    echo "$Z3_SHA *z3.zip" | sha1sum --check --strict -
    unzip z3.zip -d /opt/z3
    mv /opt/z3/z3-*/* /opt/z3/
    rm -r /opt/z3/z3-*
EOF

## Build Yices2 theorem solver.
ARG YICES2_GIT_URL=https://github.com/SRI-CSL/yices2.git
RUN <<EOF
    set -e
    git clone $YICES2_GIT_URL -b $YICES2_VERSION --depth 1
    cd yices2
    autoconf
    ./configure --prefix=/opt/yices2
    make
    make install
EOF


FROM ubuntu:24.04 AS formal

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Install runtime dependencies.
RUN <<EOF
    set -e
    apt-get -q -y update
    ## yosys
    apt-get -q -y install \
        libffi8 \
        tcl
    ## GHDL
    apt-get -q -y install \
        libgnat-13 \
        libllvm18
    ## sby
    apt-get -q -y install \
        python3 \
        python3-click
    ## yices2
    apt-get -q -y install \
        libgmp10
    ## utils
    apt-get -q -y install \
        make \
        jq
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

COPY --from=builder /opt/yosys/ /
COPY --from=builder /opt/ghdl/ /usr
COPY --from=builder /opt/plugin/ /
COPY --from=builder /opt/sby/ /
COPY --from=builder /opt/z3/ /usr/local
COPY --from=builder /opt/yices2/ /usr/local

ENV GHDL_PREFIX=/usr/lib/ghdl
