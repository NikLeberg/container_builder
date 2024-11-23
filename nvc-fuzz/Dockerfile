FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Update ca-certificates to fix failing server certificate verification.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        apt-transport-https ca-certificates
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    update-ca-certificates
EOF

# Dependencies to build and run NVC.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        git \
        wget \
        automake \
        autoconf \
        check \
        flex \
        bison \
        libdw-dev \
        libffi-dev \
        pkg-config \
        zlib1g-dev \
        libzstd-dev \
        tcl-dev \
        libreadline-dev
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Dependencies for CMAKE based LibFuzzer.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        git \
        clang \
        libclang-rt-dev \
        ninja-build \
        cmake
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF
