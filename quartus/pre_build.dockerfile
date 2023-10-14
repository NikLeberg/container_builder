FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Install wget so we can download quartus installer.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        wget ca-certificates
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Install Quartus and device support files for Intel FPGAs from:
# https://www.intel.de/content/www/de/de/products/details/fpga/development-tools/quartus-prime/resource.html
ARG QUARTUS_VER_MAJOR=22
ARG QUARTUS_VER_MINOR=1
ARG QUARTUS_VER_PATCH=2
ARG QUARTUS_VER_BUILD=922
ARG QUARTUS_SHA=9fbb3a3721c3cb94706c2d9532a8213f120f5c56
ARG CYCLONE_IV_SHA=97163542d8dd846703fc1912ea0c844bc9359a2e
#
ARG FILE_VERSION=${QUARTUS_VER_MAJOR}.${QUARTUS_VER_MINOR}std.${QUARTUS_VER_PATCH}.${QUARTUS_VER_BUILD}
ARG PATH_VERSION=${QUARTUS_VER_MAJOR}.${QUARTUS_VER_MINOR}std.${QUARTUS_VER_PATCH}/${QUARTUS_VER_BUILD}
ARG QUARTUS_VERSION=${QUARTUS_VER_MAJOR}.${QUARTUS_VER_MINOR}.${QUARTUS_VER_PATCH}
#
ARG QUARTUS_URL=https://downloads.intel.com/akdlm/software/acdsinst/${PATH_VERSION}/ib_installers/QuartusLiteSetup-${FILE_VERSION}-linux.run
ARG CYCLONE_IV_URL=https://downloads.intel.com/akdlm/software/acdsinst/${PATH_VERSION}/ib_installers/cyclone-${FILE_VERSION}.qdz
#
ENV QUARTUS_ROOTDIR="/opt/intelFPGA_lite/$QUARTUS_VERSION"
RUN <<EOF
    set -e
    mkdir quartus-tmp
    cd quartus-tmp
    wget --progress=dot:giga $QUARTUS_URL
    echo "$QUARTUS_SHA *QuartusLiteSetup-${FILE_VERSION}-linux.run" | sha1sum --check --strict -
    wget --progress=dot:giga $CYCLONE_IV_URL
    echo "$CYCLONE_IV_SHA *cyclone-${FILE_VERSION}.qdz" | sha1sum --check --strict -
    chmod +x QuartusLiteSetup-${FILE_VERSION}-linux.run
    ./QuartusLiteSetup-${FILE_VERSION}-linux.run \
        --mode unattended --accept_eula 1 \
        --installdir $QUARTUS_ROOTDIR
    cd ..
    rm -r quartus-tmp
    rm -r $QUARTUS_ROOTDIR/uninstall
    rm -r $QUARTUS_ROOTDIR/logs
EOF
