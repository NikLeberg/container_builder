FROM ubuntu:24.04 AS builder

ARG OSS_VERSION
ARG OSS_SHA

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
    echo "$OSS_SHA *oss-cad-suite.tgz" | sha1sum --check --strict -
    tar -xzhf oss-cad-suite.tgz -C /opt
    rm oss-cad-suite.tgz
EOF

ENV PATH="/opt/oss-cad-suite/bin:${PATH}"
