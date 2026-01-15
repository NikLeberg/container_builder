ARG BASE_IMAGE_TAG=25.1
FROM ghcr.io/nikleberg/quartus:${BASE_IMAGE_TAG}-staging

ARG DEBIAN_FRONTEND=noninteractive

ARG DEVICE_URL=https://downloads.intel.com/akdlm/software/acdsinst/25.1std/1129/ib_installers/cyclone-25.1std.0.1129.qdz
ARG DEVICE_SHA=835d2b1732549294eed625b692d044135499b5e8
ARG DEVICE_FILE=cyclone-25.1std.0.1129.qdz

# Install Quartus device support files for Intel FPGAs from:
# https://www.intel.de/content/www/de/de/products/details/fpga/development-tools/quartus-prime/resource.html
# The .qdz file is just a glorified zip archive. The device installer from:
# $QUARTUS_ROOTDIR/quartus/common/devinfo/dev_install/dev_install.run is somehow
# not able to correctly install the support files. So we do it manually.
RUN <<EOF
    set -e
    wget --progress=dot:giga $DEVICE_URL -O $DEVICE_FILE
    echo "$DEVICE_SHA *${DEVICE_FILE}" | sha1sum --check --strict -
    $QUARTUS_ROOTDIR/quartus/linux64/unzip -q -d $QUARTUS_ROOTDIR $DEVICE_FILE
    rm -r $DEVICE_FILE
EOF

ARG ADDON_URL=
ARG ADDON_SHA=
ARG ADDON_FILE=

# Install optional Add-On
RUN <<EOF
    set -e
    if [ -n "$ADDON_URL" ]; then
        wget --progress=dot:giga $ADDON_URL -O $ADDON_FILE
        echo "$ADDON_SHA *${ADDON_FILE}" | sha1sum --check --strict -
        chmod +x $ADDON_FILE
        ./$ADDON_FILE \
            --mode unattended --accept_eula 1 --installdir $QUARTUS_ROOTDIR
        rm -r $ADDON_FILE $QUARTUS_ROOTDIR/uninstall $QUARTUS_ROOTDIR/logs
    fi
EOF
