FROM scratch

# Quartus is rather big and installing it in one run command would create a huge
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

# Add Quartus to path
ARG QUARTUS_VERSION=22.1.2
ENV QUARTUS_ROOTDIR="/opt/intelFPGA_lite/$QUARTUS_VERSION"
ENV PATH="$QUARTUS_ROOTDIR/quartus/bin:${PATH}"

# Quartus asks at first startup if we have a license. We can skip this by
# creating a specific file that quartus expects. What exactly the content is..
# no clue. It changes everytime quartus is started for the first time. The
# following values were observed: 47b262d9285cf37e, b3b88ae373d98a4f,
# 5aa8417559ca6424, bfa7fb05de703e01, f7fcb7797c7d8b54.
RUN mkdir ~/.altera.quartus \
    && echo -n "5aa8417559ca6424">.dPwdoBmbMGe

# Entrypoint is the quartus shell.
ENTRYPOINT ["quartus_sh"]
# With args "-c -do <script.tcl>" an arbirtrary TCL script can be run.
# Without the "-c" flag vsim starts in GUI mode.
# As default do nothing and just print the version.
CMD ["-version"]
