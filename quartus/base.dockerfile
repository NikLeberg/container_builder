# This docker image gets rather big as it needs to download Quartus with a hefty
# size of more than 2 GB. This would create a single layer in the image with a
# huge size and that has to be downloaded and can't be parallelized. To break
# this layer up, an exotic multi-stage approach is taken:
#  - Download / Extract / Install Quartus in a builder docker stage.
#  - Pack the contents of the install dir into a single huge tar file.
#  - Split the tar at file boundaries into multiple tars.
#  - The split tars are then imported in multiple layers in the second stage.

FROM ubuntu:jammy AS builder

ARG QUARTUS_VERSION
ARG QUARTUS_URL
ARG QUARTUS_SHA

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Install wget so we can download quartus installer.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        wget ca-certificates
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Install Quartus (without device support files) for Intel FPGAs from:
# https://www.intel.de/content/www/de/de/products/details/fpga/development-tools/quartus-prime/resource.html
ENV QUARTUS_ROOTDIR="/opt/intelFPGA_lite/$QUARTUS_VERSION"
RUN <<EOF
    set -e
    wget --progress=dot:giga $QUARTUS_URL -O QuartusLiteSetup-linux.run
    echo "$QUARTUS_SHA *QuartusLiteSetup-linux.run" | sha1sum --check --strict -
    chmod +x QuartusLiteSetup-linux.run
    ./QuartusLiteSetup-linux.run \
        --mode unattended --accept_eula 1 --installdir $QUARTUS_ROOTDIR
    cat $QUARTUS_ROOTDIR/logs/quartus-*.log
    rm QuartusLiteSetup-linux.run
    rm -r $QUARTUS_ROOTDIR/uninstall
    rm -r $QUARTUS_ROOTDIR/logs
EOF

# Post process the install dir and remove duplicates.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        rdfind
    rdfind -makehardlinks true $QUARTUS_ROOTDIR
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Package the install dir into ~500MB tar-ed chunks at file boundaries.
ARG TAR_SPLITTER_URL=https://github.com/AQUAOSOTech/tarsplitter/releases/download/v2.2.0/tarsplitter_linux
ARG TAR_SPLITTER_SHA=d92d19b36f03eadd25e9ee17d659761a0788b2e5
RUN <<EOF
    set -e
    tar -cf quartus_dir.tar $QUARTUS_ROOTDIR
    wget --progress=dot $TAR_SPLITTER_URL -O tarsplitter
    echo "$TAR_SPLITTER_SHA *tarsplitter" | sha1sum --check --strict -
    chmod +x tarsplitter
    ./tarsplitter -i quartus_dir.tar -p 5
    rm quartus_dir.tar tarsplitter
EOF


# Fix Quartus malloc/free issues in docker environment.
# Source: https://community.intel.com/t5/Intel-Quartus-Prime-Software/quartus-map-crash-possibly-due-to-shared-library-shenanigans/m-p/1285186
FROM ubuntu:jammy AS dlopen_hack

RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends gcc libc-dev
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

COPY <<dlopen_hack.c /
#define _GNU_SOURCE 1
#include <dlfcn.h>
static void *(*orig_dlopen)(char const *, int) = 0;
void *dlopen(char const *name, int flags) {
    if(!orig_dlopen)
        orig_dlopen = dlsym(RTLD_NEXT, "dlopen");
    flags &= ~RTLD_DEEPBIND;
    return orig_dlopen(name, flags);
}
dlopen_hack.c
RUN gcc -shared -o dlopen_hack.so dlopen_hack.c -ldl


FROM ubuntu:jammy AS base

ARG QUARTUS_VERSION

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

# Add Quartus to path
ENV QUARTUS_ROOTDIR="/opt/intelFPGA_lite/$QUARTUS_VERSION"
ENV PATH="$QUARTUS_ROOTDIR/quartus/bin:${PATH}"

# Fixup Quartus quirks in version 18.1 that prevent loading the executables
# alltogether or end up in crashes in quartus_map with some errors like:
#  - missing libpng12
#  => install from ppa
#  - Inconsistency detected by ld.so: dl-close.c: 811: _dl_close: Assertion `map->l_init_called' failed!
#  => delete corrupt library libccl_curl_drl.so bundled with quartus
#  - invalid command name "vsyscall" / invalid command name "realloc():"
#  - munmap invalid pointer
#  => use dlopen_hack, see above
# Source: https://community.intel.com/t5/Intel-Quartus-Prime-Software/Quartus-failed-to-run-inside-Docker-Linux/td-p/241058?profile.language=en
RUN --mount=type=bind,from=dlopen_hack,target=/dlopen_hack <<EOF
    set -e
    if [ "$QUARTUS_VERSION" = "18.1" ]; then
        apt-get -q -y update
        apt-get -q -y install --no-install-recommends \
            gnupg software-properties-common
        add-apt-repository ppa:linuxuprising/libpng12
        apt-get -q -y install --no-install-recommends libpng12-0
        apt-get -q -y remove gnupg software-properties-common
        apt-get -q -y autoremove
        apt-get clean
        rm -rf /var/lib/apt/lists/*
        rm $QUARTUS_ROOTDIR/quartus/linux64/libccl_curl_drl.so
        cp /dlopen_hack/dlopen_hack.so $QUARTUS_ROOTDIR/quartus/linux64/
        echo 'export LD_PRELOAD=$QUARTUS_BINDIR/dlopen_hack.so:$LD_PRELOAD' >> $QUARTUS_ROOTDIR/quartus/adm/qenv.sh
    fi
EOF

# Quartus asks at first startup if we have a license. We can skip this by
# creating a specific file that quartus expects. What exactly the content is..
# no clue. It changes everytime quartus is started for the first time. The
# following values were observed: 47b262d9285cf37e, b3b88ae373d98a4f,
# 5aa8417559ca6424, bfa7fb05de703e01, f7fcb7797c7d8b54, c00a2ee0c5154f94.
# We also tell it to not show the "are you trusting this project" dialog.
COPY <<.5NoREgoqh7Y <<.iV72V2fdjta <<quartus2.qreg /root/.altera.quartus/
c00a2ee0c5154f94
.5NoREgoqh7Y
1c35b4094c56f765
.iV72V2fdjta
[22.1]
General\\show_project_open_security_prompt=false
Registry_version=27
quartus2.qreg

# Entrypoint is the quartus shell.
ENTRYPOINT ["quartus_sh"]
# With args "-c -do <script.tcl>" an arbirtrary TCL script can be run.
# Without the "-c" flag vsim starts in GUI mode.
# As default do nothing and just print the version.
CMD ["-version"]
