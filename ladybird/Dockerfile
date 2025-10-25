# SPDX-License-Identifier: MIT

FROM ubuntu:24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        ca-certificates git \
        autoconf autoconf-archive automake build-essential ccache cmake clang-20 \
        fonts-liberation2 libdrm-dev libgl1-mesa-dev libtool nasm ninja-build \
        pkg-config python3-venv qt6-base-dev qt6-tools-dev-tools qt6-wayland \
        qt6-multimedia-dev unzip zip curl
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
    set -e
    groupadd ladybird
    useradd -m -g ladybird ladybird
EOF
USER ladybird
WORKDIR /home/ladybird

ARG LADYBIRD_CLONE_URL=https://github.com/LadybirdBrowser/ladybird.git
ARG LADYBIRD_CLONE_TAG
RUN <<EOF
    set -e
    git clone $LADYBIRD_CLONE_URL -b $LADYBIRD_CLONE_TAG --depth 1
    cd ladybird
    ./Meta/ladybird.py run
EOF
