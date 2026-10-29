# This docker image gets rather big as it needs to download Lattice Diamond with
# a hefty size of more than 3 GB. This would create a single layer in the image
# with a huge size and that has to be downloaded and can't be parallelized. To
# break this layer up, an exotic multi-stage approach is taken:
#  - Download / Extract / Install Diamond in a builder docker stage.
#  - Pack the contents of the install dir into a single huge tar file.
#  - Split the tar at file boundaries into multiple tars.
#  - The split tars are then imported in multiple layers in the second stage.

ARG DIAMOND_URL=https://files.latticesemi.com/Diamond/3.14/3.14.0.75.2_Diamond_lin.zip
ARG DIAMOND_SHA=8e793407c595455af5304b68fdc7c16d7992a5f1ed0fb963998db88699292a95
ARG DIAMOND_PREFIX=/opt/diamond
ARG DEVICE_KEEP=sa5p00,sa5p00a,sa5p00b,sa5p00g,sa5p00m,xo2c00,xo2c00a,or5s00,or5g00,mg5g00

FROM ubuntu:24.04 AS builder

ARG DIAMOND_URL
ARG DIAMOND_SHA
ARG DIAMOND_PREFIX
ARG DEVICE_KEEP

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Install wget so we can download diamond installer.
# Install rdfind to remove install duplicates.
# Install GUI dependencies for the stupid installer.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        wget ca-certificates rdfind \
        libx11-xcb1 libfontconfig
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Install Diamond for Lattice FPGAs from:
# https://www.latticesemi.com/latticediamond
# This also post-processes the install dir to remove unwanted install components
# and device types as well as removing duplicates with rdfind.
RUN <<EOF
    set -e
    wget --progress=dot:giga $DIAMOND_URL -O Diamond_lin.zip
    echo "$DIAMOND_SHA *Diamond_lin.zip" | sha256sum --check --strict -
    gunzip -c Diamond_lin.zip > Diamond_lin.run
    chmod +x Diamond_lin.run
    ./Diamond_lin.run \
        --console --prefix $DIAMOND_PREFIX
    cat $DIAMOND_PREFIX/InstallationLog.txt
    rm -r \
        Diamond_lin.zip \
        Diamond_lin.run \
        $DIAMOND_PREFIX/InstallationLog.txt \
        $DIAMOND_PREFIX/uninstaller* \
        $DIAMOND_PREFIX/examples \
        $DIAMOND_PREFIX/cae_library/ibis \
        $DIAMOND_PREFIX/micosystem \
        $DIAMOND_PREFIX/questasim
    cd $DIAMOND_PREFIX
    mkdir keep
    ISPFPGA_COMMON=bin,data,maco,msgdata,slayer,userware,verilog,vhdl,vhdl_packages,webhelp
    for d in $(echo "$ISPFPGA_COMMON,$DEVICE_KEEP" | tr ',' ' '); do
        mv ispfpga/$d keep/
    done
    rm -rf ispfpga
    mv keep ispfpga
    rdfind -makehardlinks true -outputname /dev/null $DIAMOND_PREFIX
EOF

# Package the install dir into ~500MB tar-ed chunks at file boundaries.
ARG TAR_SPLITTER_URL=https://github.com/AQUAOSOTech/tarsplitter/releases/download/v2.2.0/tarsplitter_linux
ARG TAR_SPLITTER_SHA=d92d19b36f03eadd25e9ee17d659761a0788b2e5
RUN <<EOF
    set -e
    tar -cf diamond_dir.tar $DIAMOND_PREFIX
    wget --progress=dot $TAR_SPLITTER_URL -O tarsplitter
    echo "$TAR_SPLITTER_SHA *tarsplitter" | sha1sum --check --strict -
    chmod +x tarsplitter
    ./tarsplitter -i diamond_dir.tar -p 7
    rm diamond_dir.tar tarsplitter
EOF


FROM ubuntu:24.04 AS base

ARG DIAMOND_PREFIX

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Import the split-up tars from previous build stage.
RUN --mount=type=bind,from=builder,target=/builder tar -xf /builder/0.tar
RUN --mount=type=bind,from=builder,target=/builder tar -xf /builder/1.tar
RUN --mount=type=bind,from=builder,target=/builder tar -xf /builder/2.tar
RUN --mount=type=bind,from=builder,target=/builder tar -xf /builder/3.tar
RUN --mount=type=bind,from=builder,target=/builder tar -xf /builder/4.tar
RUN --mount=type=bind,from=builder,target=/builder tar -xf /builder/5.tar
RUN --mount=type=bind,from=builder,target=/builder tar -xf /builder/6.tar

# Install runtime dependencies and additional tools.
# Given by $DIAMOND_PREFIX/bin/lin64/check_systemlibrary_diamond.bash
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        libjpeg-dev libieee1284-3 libusb-0.1-4 libnss3 libdbus-1-3 libxslt1.1 \
        libxft2 libxt6 libxtst6 libxcursor1 libxcomposite1 libxdamage1 \
        libxinerama1 libxrandr2 libxss1 libxcb-cursor0 libxcb-icccm4 \
        libxcb-keysyms1 libxcb-xinput0 libxcb-xinerama0 libxcb-shape0 \
        libxkbcommon-x11-0 libgl1 libgl1-mesa-dri libatk1.0-0 libcairo2 \
        libpango-1.0-0 libgssapi-krb5-2 libgstreamer-plugins-base1.0-0 \
        libstdc++6 dbus \
        make wget ca-certificates
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    # Fix synplify libstdc++ incompatibility with newer kerberos and libcuuc.
    rm $DIAMOND_PREFIX/synpbase/linux_a_64/lib/libstdc++.so.*
    ln -sfn /usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
        $DIAMOND_PREFIX/synpbase/linux_a_64/lib/libstdc++.so.6
EOF

# Add Diamond to path
ENV PATH="$DIAMOND_PREFIX/bin/lin64:${PATH}"

# Tell diamond to print debugging information to terminal.
ENV PNMAIN_CONSOLE_DEBUG=1
# Do not share X11 memory. Otherwise we only get a white window on host.
ENV QT_X11_NO_MITSHM=1

# Install license aquired from https://latticesemi.com/license that was fixed to
# manually crafted host / NIC / MAC id of 00:ab:ab:ab:ab:ab. To use this set the
# mac address in the docker run command with --mac-address="00:ab:ab:ab:ab:ab".
ENV LM_LICENSE_FILE=$DIAMOND_PREFIX/license/license.dat
COPY license.dat $LM_LICENSE_FILE

# Diamond asks at first startup if we want to send telemetry data. We don't.
# It also checks if an update is available. Disable that.
COPY <<EOF /root/.config/LatticeSemi/.setting.ini
[General]
UploadMessageID=false
AutoCheck=false
EOF

# Entrypoint is the diamond shell.
ENTRYPOINT ["diamondc"]
# With args "<script.tcl>" an arbitrary Tcl script can be run.
