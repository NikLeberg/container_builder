# This docker image gets rather big as it needs to download Questa with a hefty
# size of more than 2 GB. This would create a single layer in the image with a
# huge size and that has to be downloaded and can't be parallelized. To break
# this layer up, an exotic multi-stage approach is taken:
#  - Download / Extract / Install Questasim in a builder docker stage.
#  - Pack the contents of the install dir into a single huge tar file.
#  - Split the tar at file boundaries into multiple tars.
#  - The split tars are then imported in multiple layers in the second stage.

FROM ubuntu:jammy AS builder

ARG MODELSIM_VERSION
ARG MODELSIM_URL
ARG MODELSIM_SHA

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

# Install ModelSim for Intel FPGAs from:
# https://www.intel.de/content/www/de/de/products/details/fpga/development-tools/quartus-prime/resource.html
ENV MODELSIM_ROOTDIR="/opt/ModelSim/$MODELSIM_VERSION"
RUN <<EOF
    set -e
    mkdir modelsim-tmp
    cd modelsim-tmp
    wget --progress=dot:giga $MODELSIM_URL -O ModelsimSetup-linux.run
    echo "$MODELSIM_SHA *ModelsimSetup-linux.run" | sha1sum --check --strict -
    chmod +x ModelsimSetup-linux.run
    ./ModelsimSetup-linux.run \
        --mode unattended --accept_eula 1 \
        --installdir $MODELSIM_ROOTDIR
    cd ..
    rm -r modelsim-tmp
    rm -r $MODELSIM_ROOTDIR/uninstall
    rm -r $MODELSIM_ROOTDIR/logs
EOF

# Post process the install dir and remove duplicates.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        rdfind
    rdfind -makehardlinks true $MODELSIM_ROOTDIR
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Package the install dir into ~500MB tar-ed chunks at file boundaries.
ARG TAR_SPLITTER_URL=https://github.com/AQUAOSOTech/tarsplitter/releases/download/v2.2.0/tarsplitter_linux
ARG TAR_SPLITTER_SHA=d92d19b36f03eadd25e9ee17d659761a0788b2e5
RUN <<EOF
    set -e
    tar -cf questasim_dir.tar $MODELSIM_ROOTDIR
    wget --progress=dot $TAR_SPLITTER_URL -O tarsplitter
    echo "$TAR_SPLITTER_SHA *tarsplitter" | sha1sum --check --strict -
    chmod +x tarsplitter
    ./tarsplitter -i questasim_dir.tar -p 5
    rm questasim_dir.tar tarsplitter
EOF


FROM ubuntu:jammy AS base

ARG MODELSIM_VERSION

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

# Install runtime dependencies and additional tools.
# https://yoloh3.github.io/linux/2016/12/24/install-modelsim-in-linux/
RUN <<EOF
    set -e
    dpkg --add-architecture i386
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        libncurses5:i386 libxtst6:i386 libxft2:i386 libstdc++6:i386 libc6:i386 \
        libbz2-1.0:i386 libpng16-16:i386 libqt5xml5:i386 \
        libx11-xcb1:i386 libsm6:i386 libdbus-1-3:i386 \
        make wget ca-certificates
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Add Questa to path
ENV MODELSIM_ROOTDIR="/opt/ModelSim/$MODELSIM_VERSION"
ENV PATH="$MODELSIM_ROOTDIR/modelsim_ase/bin:${PATH}"

# Patch 32/64-bit detection to always use 32-bit and fix binary paths.
# https://mil.ufl.edu/3701/docs/quartus/linux/ModelSim_linux.pdf
RUN <<EOF
    set -e
    sed -i \
        -e 's/mode=\${MTI_VCO_MODE:-""}/mode=\${MTI_VCO_MODE:-"32"}/g' \
        -e 's/vco="linux_rh60"/vco="linux"/g' \
        $MODELSIM_ROOTDIR/modelsim_ase/vco
EOF

# ModelSim requires no licensing setup.

# Install additional development tools.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        make
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Entrypoint is the vsim executable.
ENTRYPOINT ["vsim"]
# With args "-c -do <script.tcl>" an arbirtrary TCL script can be run.
# Without the "-c" flag vsim starts in GUI mode.
# As default do nothing and just print the version.
CMD ["-version"]
