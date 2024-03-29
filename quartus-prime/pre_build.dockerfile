FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LC_CTYPE=C.UTF-8

# Install wget so we can download quartus installer.
RUN apt-get -q -y update \
    && apt-get -q -y install wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Quartus Prime from:
# https://www.intel.de/content/www/de/de/products/details/fpga/development-tools/quartus-prime/resource.html
ARG QUARTUS_URL=https://downloads.intel.com/akdlm/software/acdsinst/22.1std/915/ib_tar/Quartus-lite-22.1std.0.915-linux.tar
ARG QUARTUS_SHA=9eeb9ce158348e34614e69873af15de223e786d8
ARG QUARTUS_VERSION=22.1
ENV QUARTUS_ROOTDIR="/opt/intelFPGA_lite/$QUARTUS_VERSION"
RUN mkdir quartus-lite-linux \
    && cd quartus-lite-linux \
    && wget --progress=dot:giga $QUARTUS_URL -O quartus.tar \
    && echo "$QUARTUS_SHA *quartus.tar" | sha1sum --check --strict - \
    && tar -xf quartus.tar \
    && ./setup.sh \
        --mode unattended --accept_eula 1 \
        --installdir $QUARTUS_ROOTDIR \
        --disable-components quartus_help,quartus_update,questa_fe \
    && cd .. \
    && rm -r quartus-lite-linux \
    && rm -r $QUARTUS_ROOTDIR/uninstall \
    && rm -r $QUARTUS_ROOTDIR/logs \
    && rm -r $QUARTUS_ROOTDIR/nios2eds \
    && rm -r $QUARTUS_ROOTDIR/ip
