# Based on Zephyr "Getting Started Guide"
# https://docs.zephyrproject.org/latest/develop/getting_started/index.html

FROM ubuntu:jammy

ARG ZEPHYR_VERSION
ARG ZEPHYR_SDK_VERSION

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
    west update
    west zephyr-export
    pip3 install -r ./zephyr/scripts/requirements.txt
EOF
ENV ZEPHYR_BASE=/opt/zephyrproject/zephyr

# Install Zephyr SDK
RUN <<EOF
    set -e
    cd /opt
    wget --progress=dot:giga https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64.tar.xz
    wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/sha256.sum | shasum --check --ignore-missing
    tar xvf zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64.tar.xz > /dev/null
    rm zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64.tar.xz
    cd zephyr-sdk-${ZEPHYR_SDK_VERSION}
    ./setup.sh -t all
EOF
