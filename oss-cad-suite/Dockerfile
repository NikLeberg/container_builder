FROM ubuntu:26.04

ARG OSS_VERSION=2026-05-11
ARG OSS_SHA=8607a037f6552c5008094e53e2c5f49974f6d1909231f2f86ea26b9dc4d7cfed

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
ARG OSS_URL=https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${OSS_VERSION}/oss-cad-suite-linux-x64-${OSS_VERSION_SHORT}.tgz
RUN <<EOF
    set -e
    wget --progress=dot:giga $OSS_URL -O oss-cad-suite.tgz
    echo "$OSS_SHA *oss-cad-suite.tgz" | sha256sum --check --strict -
    tar -xzhf oss-cad-suite.tgz -C /opt
    rm oss-cad-suite.tgz
EOF

ENV PATH="/opt/oss-cad-suite/bin:${PATH}"
