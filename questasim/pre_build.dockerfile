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
ARG QUESTA_URL=https://downloads.intel.com/akdlm/software/acdsinst/22.1std.1/917/ib_installers/QuestaSetup-22.1std.1.917-linux.run
ARG QUESTA_SHA=a10a65aecdf2b2d2bfbfaf1fa159d938b3cab4bf
ARG QUESTA_VERSION=22.1.1
ENV QUESTA_ROOTDIR="/opt/QuestaSim/$QUESTA_VERSION"
RUN <<EOF
    set -e
    mkdir questa-tmp
    cd questa-tmp
    wget --progress=dot:giga $QUESTA_URL -O QuestaSetup.run
    echo "$QUESTA_SHA *QuestaSetup.run" | sha1sum --check --strict -
    chmod +x QuestaSetup.run
    ./QuestaSetup.run \
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
