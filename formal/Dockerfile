FROM ubuntu:24.04 AS builder

ARG YOSYS_VERSION=v0.51
ARG GHDL_VERSION=v5.0.1
ARG PLUGIN_VERSION=4ea20ad
ARG SBY_VERSION=v0.51

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

ENV GHDL_PREFIX=/usr/lib/ghdl
