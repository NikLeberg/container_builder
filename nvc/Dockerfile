# Based off https://github.com/hdl/containers/blob/main/debian-bullseye/nvc/Dockerfile
FROM ubuntu:jammy AS builder

ARG NVC_VERSION
ARG NVC_SIG_KEY
ARG LLVM_VERSION

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Install neccessary build tools and dependencies.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install \
        git \
        wget \
        gpg \
        automake \
        autoconf \
        check \
        flex \
        bison \
        libdw-dev \
        libffi-dev \
        llvm-$LLVM_VERSION-dev \
        pkg-config \
        zlib1g-dev \
        libzstd-dev \
        tcl-dev \
        libreadline-dev
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Build from signed tarball.
ARG NV_TARBALL=nvc-$NVC_VERSION.tar.gz
ARG NVC_GIT_URL=https://github.com/nickg/nvc
ARG NVC_TARBALL_URL=$NVC_GIT_URL/releases/download/r$NVC_VERSION/$NV_TARBALL
ARG NVC_SIG_URL=$NVC_GIT_URL/releases/download/r$NVC_VERSION/$NV_TARBALL.sig
RUN <<EOF
    set -e
    if [ $NVC_VERSION = "master" ]; then
        git clone $NVC_GIT_URL --depth 1 ./nvc-$NVC_VERSION
        cd ./nvc-$NVC_VERSION
        ./autogen.sh
        cd ..
    else
        wget --progress=dot $NVC_TARBALL_URL
        wget --progress=dot $NVC_SIG_URL
        gpg --keyserver keyserver.ubuntu.com --recv-keys $NVC_SIG_KEY
        gpg --verify $NV_TARBALL.sig $NV_TARBALL
        tar xvzf $NV_TARBALL
    fi
    mkdir ./nvc-$NVC_VERSION/build
    cd ./nvc-$NVC_VERSION/build
    ../configure \
        --with-llvm=/usr/lib/llvm-$LLVM_VERSION/bin/llvm-config \
        --enable-tcl
    make -j$(nproc)
    make DESTDIR=/opt/nvc install
EOF

# Import built NVC into clean container.
FROM ubuntu:jammy AS base

ARG LLVM_VERSION

COPY --from=builder /opt/nvc /

# Install neccessary runtime dependencies.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        binutils \
        libdw1 \
        libllvm$LLVM_VERSION \
        make \
        libzstd1 \
        libtcl8.6 \
        libreadline8
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Entrypoint is the NVC executable.
ENTRYPOINT ["nvc"]
# With e.g. args "-a <file.vhd>" a VHDL design can be analyzed.
# See the manual for more options https://www.nickg.me.uk/nvc/manual.html.
# As default do nothing and just print the version.
CMD ["--version"]
