FROM ubuntu:jammy

# Install neccessary tools and dependencies.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install \
        wget ca-certificates
    apt-get clean
    rm -rf /var/lib/apt/lists/* 
EOF

# Install precompiled risc-v cross compiler toolchain.
ARG OSS_CAD_SUITE_URL=https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2023-10-15/oss-cad-suite-linux-x64-20231015.tgz
ARG OSS_CAD_SUITE_SHA=4c2a399e09596279f4eb9e545a3f2955df1d3aeb
ARG OSS_CAD_SUITE_PATH=/opt
RUN <<EOF
    set -e
    wget --progress=dot:giga $OSS_CAD_SUITE_URL -O oss-cad-suite.tgz
    echo "$OSS_CAD_SUITE_SHA *oss-cad-suite.tgz" | sha1sum --check --strict -
    tar -xf oss-cad-suite.tgz -C $OSS_CAD_SUITE_PATH
    rm oss-cad-suite.tgz
EOF
ENV PATH="$OSS_CAD_SUITE_PATH/oss-cad-suite/bin:${PATH}"
