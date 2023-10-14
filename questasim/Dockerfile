FROM scratch

# Questa is rather big and installing it in one run command would create a huge
# image layer. A pre-build step does that and splits the layer up into smaller
# chunks/tars. These can then be added one by one which results in smaller
# layers. The image remains large but can be more easily pulled.
ADD 0.tar /
ADD 1.tar /
ADD 2.tar /
ADD 3.tar /
ADD 4.tar /

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Install necessary tools and dependencies
# https://yoloh3.github.io/linux/2016/12/24/install-modelsim-in-linux/
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        libncurses6 libxtst6 libxft2 libstdc++6 libc6 lib32z1 libbz2-1.0 \
        libpng16-16 libqt5xml5 libx11-xcb1 libsm6 libdbus-1-3
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Add Questa to path
ARG QUESTA_VERSION=22.1.1
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

# Entrypoint is the vsim executable.
ENTRYPOINT ["vsim"]
# With args "-c -do <script.tcl>" an arbirtrary TCL script can be run.
# Without the "-c" flag vsim starts in GUI mode.
# As default do nothing and just print the version.
CMD ["-version"]
