# Based on Zephyr "Getting Started Guide"
# https://docs.zephyrproject.org/latest/develop/getting_started/index.html

FROM ubuntu:jammy

ARG ZEPHYR_VERSION

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# Install host dependencies
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        git \
        cmake \
        ninja-build \
        gperf \
        ccache \
        dfu-util \
        device-tree-compiler \
        wget \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-tk \
        python3-wheel \
        xz-utils \
        file \
        make \
        gcc \
        gcc-multilib \
        g++-multilib \
        libsdl2-dev \
        libmagic1
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Get Zephyr and install Python dependencies
RUN <<EOF
    set -e
    pip3 install west
    mkdir -p /opt/zephyrproject
    cd /opt/zephyrproject
    west init --mr ${ZEPHYR_VERSION}
    west update --fetch-opt=--filter=tree:0
    west zephyr-export
    pip3 install -r ./zephyr/scripts/requirements.txt
EOF
ENV ZEPHYR_BASE=/opt/zephyrproject/zephyr
