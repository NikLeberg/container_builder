FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Install wget so we can download questa installer.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        wget ca-certificates
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Install QuestaSim for Intel FPGAs from:
# https://www.intel.de/content/www/de/de/products/details/fpga/development-tools/quartus-prime/resource.html
ARG QUESTA_VER_MAJOR=22
ARG QUESTA_VER_MINOR=1
ARG QUESTA_VER_PATCH=2
ARG QUESTA_VER_BUILD=922
ARG QUESTA_SHA=a25801f1180c017ccc2459bce2acd833012adf38
#
ARG FILE_VERSION=${QUESTA_VER_MAJOR}.${QUESTA_VER_MINOR}std.${QUESTA_VER_PATCH}.${QUESTA_VER_BUILD}
ARG PATH_VERSION=${QUESTA_VER_MAJOR}.${QUESTA_VER_MINOR}std.${QUESTA_VER_PATCH}/${QUESTA_VER_BUILD}
ARG QUESTA_VERSION=${QUESTA_VER_MAJOR}.${QUESTA_VER_MINOR}.${QUESTA_VER_PATCH}
#
ARG QUESTA_URL=https://downloads.intel.com/akdlm/software/acdsinst/${PATH_VERSION}/ib_installers/QuestaSetup-${FILE_VERSION}-linux.run
ENV QUESTA_ROOTDIR="/opt/QuestaSim/$QUESTA_VERSION"
RUN <<EOF
    set -e
    mkdir questa-tmp
    cd questa-tmp
    wget --progress=dot:giga $QUESTA_URL
    echo "$QUESTA_SHA *QuestaSetup-${FILE_VERSION}-linux.run" | sha1sum --check --strict -
    chmod +x QuestaSetup-${FILE_VERSION}-linux.run
    ./QuestaSetup-${FILE_VERSION}-linux.run \
        --mode unattended --accept_eula 1 \
        --installdir $QUESTA_ROOTDIR
    cd ..
    rm -r questa-tmp
    rm -r $QUESTA_ROOTDIR/uninstall
    rm -r $QUESTA_ROOTDIR/logs
EOF

# Post process the install dir and remove duplicates.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        rdfind
    rdfind -makehardlinks true $QUESTA_ROOTDIR
    apt-get -q -y remove rdfind
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF
