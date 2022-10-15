FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LC_CTYPE=C.UTF-8

# Update all packages and install neccessary tools and dependencies
# https://yoloh3.github.io/linux/2016/12/24/install-modelsim-in-linux/
RUN apt-get -q -y update \
    && apt-get -q -y upgrade \
    && apt-get -q -y install \
        git wget \
        libncurses6 libxtst6 libxft2 libstdc++6 libc6-dev lib32z1 libbz2-1.0 \
        libpng16-16 libqt5xml5 libx11-xcb1 libsm6 libdbus-1-3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Quartus Prime from:
# https://www.intel.de/content/www/de/de/products/details/fpga/development-tools/quartus-prime/resource.html
ARG QUARTUS_URL=https://downloads.intel.com/akdlm/software/acdsinst/21.1std.1/850/ib_tar/Quartus-lite-21.1.1.850-linux.tar
ARG QUARTUS_SHA=789c1133d99fde7146fdb99c1f5dcb4d2e5cc0cc
ARG QUARTUS_VERSION=21.1
ENV QUARTUS_ROOTDIR="/opt/intelFPGA_lite/$QUARTUS_VERSION"
RUN mkdir quartus-lite-linux \
    && cd quartus-lite-linux \
    && wget --progress=dot:giga $QUARTUS_URL -O quartus.tar \
    && echo "$QUARTUS_SHA *quartus.tar" | sha1sum --check --strict - \
    && tar -xf quartus.tar \
    && ./setup.sh \
        --mode unattended --accept_eula 1 \
        --installdir $QUARTUS_ROOTDIR \
        --disable-components quartus_help,quartus_update,questa_fe,modelsim_ase,modelsim_ae \
    && cd .. \
    && rm -r quartus-lite-linux \
    && rm -r $QUARTUS_ROOTDIR/uninstall \
    && rm -r $QUARTUS_ROOTDIR/logs \
    && rm -r $QUARTUS_ROOTDIR/nios2eds \
    && rm -r $QUARTUS_ROOTDIR/ip
ENV PATH="$QUARTUS_ROOTDIR/quartus/bin:$QUARTUS_ROOTDIR/questa_fse/bin:${PATH}"

# Install license aquired from https://licensing.intel.com/ that was fixed to a
# manually crafted host / NIC / MAC id of 00:ab:ab:ab:ab:ab. To use this set the
# mac address in the docker run command with --mac-address="00:ab:ab:ab:ab:ab"
ENV LM_LICENSE_FILE=$QUARTUS_ROOTDIR/licenses/license.dat
COPY license.dat $LM_LICENSE_FILE
# Some documenting breadcrumbs:
# flexlm allows for any host id that is displayed with the "lmhostid" tool. For
# servers this could be the "real" hostid as in /etc/hostid. But with a server
# based license a daemon needs to be running and also the hostname needs to be
# fixed. So alternatively use the NIC based host id that is just the MAC addess.
