# Extend base quartus image with optional add-ons.
ARG QUARTUS_VERSION=25.1
FROM ghcr.io/nikleberg/quartus:${QUARTUS_VERSION}-staging

ARG QUARTUS_ROOTDIR="/opt/quartus_lite"
ARG ADDON_URL=https://downloads.intel.com/akdlm/software/acdsinst/25.1std/1129/ib_installers/RiscFreeSetup-25.1std.0.1129-linux.run
ARG ADDON_SHA=2d457bd18bfbf32f8f4037266b6c04853caed8e8
ARG ADDON_FILE=RiscFreeSetup-25.1std.0.1129-linux.run

# Install Add-On package.
RUN <<EOF
    set -e
    wget --progress=dot:giga $ADDON_URL -O $ADDON_FILE
    echo "$ADDON_SHA *${ADDON_FILE}" | sha1sum --check --strict -
    chmod +x $ADDON_FILE
    ./$ADDON_FILE \
        --mode unattended --accept_eula 1 --installdir $QUARTUS_ROOTDIR
    rm -r $ADDON_FILE $QUARTUS_ROOTDIR/uninstall $QUARTUS_ROOTDIR/logs
EOF
