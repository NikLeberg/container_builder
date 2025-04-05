FROM ubuntu:24.04 AS builder

ARG OSS_VERSION

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Install tools.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install \
        wget \
        git \
        make
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Download and extract release package.
ARG OSS_VERSION_SHORT=${OSS_VERSION//-/}
RUN <<EOF
    set -e
    wget --progress=dot:giga https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${OSS_VERSION}/oss-cad-suite-linux-arm64-${OSS_VERSION_SHORT}.tgz
    tar -xzhf oss-cad-suite-linux-arm64-${OSS_VERSION_SHORT}.tgz -C /opt
    rm oss-cad-suite-linux-arm64-${OSS_VERSION_SHORT}.tgz
EOF

ENV PATH="/opt/oss-cad-suite/bin:${PATH}"
