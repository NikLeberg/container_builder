# This docker image gets rather big as it needs to download Questa with a hefty
# size of more than 2 GB. This would create a single layer in the image with a
# huge size and that has to be downloaded and can't be parallelized. To break
# this layer up, an exotic multi-stage approach is taken:
#  - Download / Extract / Install Questasim in a builder docker stage.
#  - Pack the contents of the install dir into a single huge tar file.
#  - Split the tar at file boundaries into multiple tars.
#  - The split tars are then imported in multiple layers in the second stage.

FROM ubuntu:jammy AS builder

ARG QUESTA_VERSION
ARG QUESTA_URL
ARG QUESTA_SHA

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
ENV QUESTA_ROOTDIR="/opt/QuestaSim/$QUESTA_VERSION"
RUN <<EOF
    set -e
    mkdir questa-tmp
    cd questa-tmp
    wget --progress=dot:giga $QUESTA_URL -O QuestaSetup-linux.run
    echo "$QUESTA_SHA *QuestaSetup-linux.run" | sha1sum --check --strict -
    chmod +x QuestaSetup-linux.run
    ./QuestaSetup-linux.run \
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
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Package the install dir into ~500MB tar-ed chunks at file boundaries.
ARG TAR_SPLITTER_URL=https://github.com/AQUAOSOTech/tarsplitter/releases/download/v2.2.0/tarsplitter_linux
ARG TAR_SPLITTER_SHA=d92d19b36f03eadd25e9ee17d659761a0788b2e5
RUN <<EOF
    set -e
    tar -cf questasim_dir.tar $QUESTA_ROOTDIR
    wget --progress=dot $TAR_SPLITTER_URL -O tarsplitter
    echo "$TAR_SPLITTER_SHA *tarsplitter" | sha1sum --check --strict -
    chmod +x tarsplitter
    ./tarsplitter -i questasim_dir.tar -p 5
    rm questasim_dir.tar tarsplitter
EOF


FROM ubuntu:jammy AS base

ARG QUESTA_VERSION

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
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        libncurses6 libxtst6 libxft2 libstdc++6 libc6 lib32z1 libbz2-1.0 \
        libpng16-16 libqt5xml5 libx11-xcb1 libsm6 libdbus-1-3 \
        make wget ca-certificates
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Add Questa to path
ENV QUESTA_ROOTDIR="/opt/QuestaSim/$QUESTA_VERSION"
ENV PATH="$QUESTA_ROOTDIR/questa_fse/bin:${PATH}"

# Install license aquired from https://licensing.intel.com/ that was fixed to a
# manually crafted host / NIC / MAC id of 00:ab:ab:ab:ab:ab. To use this set the
# mac address in the docker run command with --mac-address="00:ab:ab:ab:ab:ab"
ENV LM_LICENSE_FILE=$QUESTA_ROOTDIR/licenses/license.dat
COPY license.dat $LM_LICENSE_FILE
# Some documenting breadcrumbs:
# flexlm allows for any host id that is displayed with the "lmhostid" tool. For
# servers this could be the "real" hostid as in /etc/hostid. But with a server
# based license a daemon needs to be running and also the hostname needs to be
# fixed. So alternatively use the NIC based host id that is just the MAC addess.

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
