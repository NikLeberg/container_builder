# Extend base quartus image with optional add-ons.
ARG QUARTUS_VERSION=25.1
FROM ghcr.io/nikleberg/quartus:${QUARTUS_VERSION}-staging

ARG QUARTUS_ROOTDIR="/opt/quartus_lite"
ARG ADDON_URL=https://download.altera.com/akdlm/software/acdsinst/25.1std/1129/ib_installers/RiscFreeSetup-25.1std.0.1129-linux.run
ARG ADDON_SHA=2d457bd18bfbf32f8f4037266b6c04853caed8e8
ARG ADDON_FILE=RiscFreeSetup-25.1std.0.1129-linux.run

ARG CURL_IMPERSONATE_URL=https://github.com/lexiforest/curl-impersonate/releases/download/v2.2.3/curl-impersonate-v2.2.3.x86_64-linux-gnu.tar.gz
ARG CURL_IMPERSONATE_SHA=ca7c8aae49e33260d3a2400db16c7737aaf04692d606a843502056b42990f989
ARG CURL_IMPERSONATE_PATH=/opt/curl-impersonate
ARG CURL_IMPERSONATE_BIN=$CURL_IMPERSONATE_PATH/curl_firefox144
RUN <<EOF
    set -e
    # Impersonate real browser to bypass Akamai bot protection.
    wget --progress=dot $CURL_IMPERSONATE_URL -O curl-impersonate.tar.gz
    echo "$CURL_IMPERSONATE_SHA *curl-impersonate.tar.gz" | \
        sha256sum --check --strict -
    mkdir -p $CURL_IMPERSONATE_PATH
    tar -xvzf curl-impersonate.tar.gz -C $CURL_IMPERSONATE_PATH
    rm curl-impersonate.tar.gz
    # Download add-on package.
    $CURL_IMPERSONATE_BIN -f $ADDON_URL -o $ADDON_FILE
    echo "$ADDON_SHA *${ADDON_FILE}" | sha1sum --check --strict -
    chmod +x $ADDON_FILE
    ./$ADDON_FILE \
        --mode unattended --accept_eula 1 --installdir $QUARTUS_ROOTDIR
    rm -r $CURL_IMPERSONATE_PATH $ADDON_FILE \
        $QUARTUS_ROOTDIR/uninstall $QUARTUS_ROOTDIR/logs
EOF
