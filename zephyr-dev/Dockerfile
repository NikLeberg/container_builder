# Based on Zephyr "Getting Started Guide"
# https://docs.zephyrproject.org/latest/develop/getting_started/index.html

FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# Install host dependencies
RUN apt-get -q -y update && apt-get -q -y install --no-install-recommends \
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
        libmagic1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Get Zephyr and install Python dependencies
RUN pip3 install west \
    && mkdir -p /opt/zephyrproject \
    && west init /opt/zephyrproject \
    && cd /opt/zephyrproject \
    && west update \
    && pip3 install -r ./zephyr/scripts/requirements.txt
ENV ZEPHYR_BASE=/opt/zephyrproject/zephyr

# Install Zephyr SDK
ARG SDK_VERSION=0.15.0
RUN cd /opt \
    && wget -nv https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VERSION}/zephyr-sdk-${SDK_VERSION}_linux-x86_64.tar.gz \
    && wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VERSION}/sha256.sum | shasum --check --ignore-missing \
    && tar xvf zephyr-sdk-${SDK_VERSION}_linux-x86_64.tar.gz > /dev/null \
    && rm zephyr-sdk-${SDK_VERSION}_linux-x86_64.tar.gz \
    && cd zephyr-sdk-${SDK_VERSION} \
    && ./setup.sh -t all
