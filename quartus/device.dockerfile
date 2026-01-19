ARG QUARTUS_ROOTDIR="/opt/quartus_lite"

FROM ubuntu:24.04 AS installer

ARG DEBIAN_FRONTEND=noninteractive

ARG DEVICE_URL=https://downloads.intel.com/akdlm/software/acdsinst/25.1std/1129/ib_installers/cyclone-25.1std.0.1129.qdz
ARG DEVICE_SHA=835d2b1732549294eed625b692d044135499b5e8
ARG DEVICE_FILE=cyclone-25.1std.0.1129.qdz

# Install required tools.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        ca-certificates wget unzip rdfind
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Install Quartus device support files for Intel FPGAs from:
# https://www.intel.de/content/www/de/de/products/details/fpga/development-tools/quartus-prime/resource.html
# The .qdz file is just a glorified zip archive. The device installer from:
# $QUARTUS_ROOTDIR/quartus/common/devinfo/dev_install/dev_install.run is somehow
# not able to correctly install the support files. So we do it manually.
ARG QUARTUS_ROOTDIR
RUN <<EOF
    set -e
    wget --progress=dot:giga $DEVICE_URL -O $DEVICE_FILE
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
