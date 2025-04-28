ARG BASE_IMAGE_TAG
FROM ghcr.io/nikleberg/quartus:${BASE_IMAGE_TAG}-staging

ARG DEVICE_URL=https://downloads.intel.com/akdlm/software/acdsinst/23.1std.1/993/ib_installers/cyclone-23.1std.1.993.qdz
ARG DEVICE_SHA=4c260c32282032c477d5520a84ebd1200d01ecf0
ARG DEVICE_FILE=cyclone-23.1std.1.993.qdz

ARG DEBIAN_FRONTEND=noninteractive

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
