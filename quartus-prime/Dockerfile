FROM scratch

# Quartus Prime is rather big and installing it in one run command would create
# a huge image layer. A pre-build step does that and splits the layer up into
# smaller chunks/tars. These can then be added one by one which results in
# smaller layers. the imag eremains large but can be more easily pulled.
ADD 0.tar /
ADD 1.tar /
ADD 2.tar /
ADD 3.tar /
ADD 4.tar /
ADD 5.tar /
ADD 6.tar /
ADD 7.tar /
ADD 8.tar /
ADD 9.tar /

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LC_CTYPE=C.UTF-8

# Install necessary tools and dependencies
# https://yoloh3.github.io/linux/2016/12/24/install-modelsim-in-linux/
RUN apt-get -q -y update \
    && apt-get -q -y upgrade \
    && apt-get -q -y install \
        git \
        libncurses6 libxtst6 libxft2 libstdc++6 libc6-dev lib32z1 libbz2-1.0 \
        libpng16-16 libqt5xml5 libx11-xcb1 libsm6 libdbus-1-3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add Quartus and Questa to path
ARG QUARTUS_VERSION=22.1
ENV QUARTUS_ROOTDIR="/opt/intelFPGA_lite/$QUARTUS_VERSION"
ENV PATH="$QUARTUS_ROOTDIR/quartus/bin:$QUARTUS_ROOTDIR/questa_fse/bin:${PATH}"

# Install license aquired from https://licensing.intel.com/ that was fixed to a
# manually crafted host / NIC / MAC id of 00:ab:ab:ab:ab:ab. To use this set the
# mac address in the docker run command with --mac-address="00:ab:ab:ab:ab:ab"
ENV LM_LICENSE_FILE=$QUARTUS_ROOTDIR/licenses/license.dat
COPY license.dat $LM_LICENSE_FILE
# Some documenting breadcrumbs:
# flexlm allows for any host id that is displayed with the "lmhostid" tool. For
# servers this could be the "real" hostid as in /etc/hostid. But with a server
# based license a daemon needs to be running and also the hostname needs to be
# fixed. So alternatively use the NIC based host id that is just the MAC addess.

# Quartus asks at first startup if we have a license. We can skip this by
# creating a specific file that quartus expects. What exactly the content is..
# no clue. It changes everytime quartus is started for the first time. The
# following values were observed: 47b262d9285cf37e, b3b88ae373d98a4f,
# 5aa8417559ca6424, bfa7fb05de703e01, f7fcb7797c7d8b54.
RUN mkdir ~/.altera.quartus \
    && echo -n "5aa8417559ca6424">.dPwdoBmbMGe
