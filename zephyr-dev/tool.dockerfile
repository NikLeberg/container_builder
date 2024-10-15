# Based on Zephyr "Getting Started Guide"
# https://docs.zephyrproject.org/latest/develop/getting_started/index.html

ARG BASE_IMAGE_TAG
FROM ghcr.io/nikleberg/zephyr-dev:${BASE_IMAGE_TAG}-staging

ARG ZEPHYR_SDK_VERSION
ARG ZEPHYR_TOOLCHAIN

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# Install Zephyr SDK
RUN <<EOF
    set -e
    cd /opt
    wget --progress=dot:mega https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz
    wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/sha256.sum | shasum --check --ignore-missing
    tar xvf zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz > /dev/null
    rm zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz
    cd zephyr-sdk-${ZEPHYR_SDK_VERSION}
    ./setup.sh -h
    ./setup.sh -t ${ZEPHYR_TOOLCHAIN}
EOF
