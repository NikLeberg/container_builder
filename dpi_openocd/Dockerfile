# SPDX-License-Identifier: MIT

FROM ubuntu:24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        ca-certificates git \
        autoconf automake libtool pkg-config gcc make libjim-dev
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

ARG OPENOCD_CLONE_URL
ARG OPENOCD_CLONE_TAG
ARG OPENOCD_PATCH
COPY $OPENOCD_PATCH patch.patch
RUN <<EOF
    set -e
    git clone $OPENOCD_CLONE_URL -b $OPENOCD_CLONE_TAG --depth 1 openocd
    cd openocd
    git apply ../patch.patch
    ./bootstrap
    ./configure --enable-jtag-dpi
    make -j$(nproc)
EOF


FROM ubuntu:24.04

RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        libjim0.82
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

COPY --from=builder /openocd/src/openocd /opt/openocd/
COPY --from=builder /openocd/tcl /opt/openocd/tcl

COPY entrypoint.sh entrypoint.sh
COPY default.cfg default.cfg
COPY wait.cfg wait.cfg

# jtag_dpi
EXPOSE 5555

# gdb
EXPOSE 3333

ENTRYPOINT ["/entrypoint.sh"]
CMD ["-f", "default.cfg"]
