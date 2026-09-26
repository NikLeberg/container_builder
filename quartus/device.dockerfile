ARG QUARTUS_ROOTDIR="/opt/quartus_lite"

FROM ubuntu:26.04 AS installer

ARG DEBIAN_FRONTEND=noninteractive

ARG DEVICE_URL=https://download.altera.com/akdlm/software/acdsinst/25.1std/1129/ib_installers/cyclone-25.1std.0.1129.qdz
ARG DEVICE_SHA=835d2b1732549294eed625b692d044135499b5e8
ARG DEVICE_FILE=cyclone-25.1std.0.1129.qdz

# Install required tools.
#  - wget to fetch curl impersonate
#  - curl-impersonate to bypass Akamai bot protection
#  - unzip as Quartus installer replacement
#  - rdfind for Quartus install deduplication
ARG CURL_IMPERSONATE_URL=https://github.com/lexiforest/curl-impersonate/releases/download/v2.2.3/curl-impersonate-v2.2.3.x86_64-linux-gnu.tar.gz
ARG CURL_IMPERSONATE_SHA=ca7c8aae49e33260d3a2400db16c7737aaf04692d606a843502056b42990f989
ARG CURL_IMPERSONATE_PATH=/opt/curl-impersonate
ARG CURL_IMPERSONATE_BIN=$CURL_IMPERSONATE_PATH/curl_firefox144
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        wget ca-certificates unzip rdfind
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    wget --progress=dot $CURL_IMPERSONATE_URL -O curl-impersonate.tar.gz
    echo "$CURL_IMPERSONATE_SHA *curl-impersonate.tar.gz" | \
        sha256sum --check --strict -
    mkdir -p $CURL_IMPERSONATE_PATH
    tar -xvzf curl-impersonate.tar.gz -C $CURL_IMPERSONATE_PATH
    rm curl-impersonate.tar.gz
EOF

# Install Quartus device support files for Altera FPGAs from:
# https://www.altera.com/products/development-tools/quartus
# The .qdz file is just a glorified zip archive. The device installer from:
# $QUARTUS_ROOTDIR/quartus/common/devinfo/dev_install/dev_install.run is somehow
# not able to correctly install the support files. So we do it manually.
ARG QUARTUS_ROOTDIR
RUN <<EOF
    set -e
    $CURL_IMPERSONATE_BIN -f $DEVICE_URL -o $DEVICE_FILE
    echo "$DEVICE_SHA *${DEVICE_FILE}" | sha1sum --check --strict -
    unzip -q -d $QUARTUS_ROOTDIR $DEVICE_FILE
    rm -r $DEVICE_FILE
    rdfind -makehardlinks true $QUARTUS_ROOTDIR
EOF


# Package device files into data-only image.
# Installed files live in $QUARTUS_ROOTDIR/quartus/common/devinfo/$DEVICE.
FROM scratch
ARG QUARTUS_ROOTDIR
COPY --from=installer $QUARTUS_ROOTDIR $QUARTUS_ROOTDIR
CMD ["invalid"]
