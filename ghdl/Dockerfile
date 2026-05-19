FROM ubuntu:26.04 AS builder

ARG GHDL_VERSION=v6.0.0

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Install build tools.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install \
        make \
        gcc \
        llvm \
        clang \
        gnat \
        libz-dev \
        git
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Build GHDL from source.
ARG GHDL_GIT_URL=https://github.com/ghdl/ghdl.git
RUN <<EOF
    set -e
    git clone $GHDL_GIT_URL -b $GHDL_VERSION --depth 1
    mkdir ghdl/build
    cd ghdl/build
    ../configure --prefix=/opt/ghdl \
        --with-llvm-config \
        --with-llvm-jit \
        --enable-checks \
        --enable-libghdl \
        --enable-synth
    make -j $(nproc)
    make install
EOF


FROM ubuntu:26.04 AS ghdl

ARG USERNAME=ubuntu
ARG USERHOME=/home/$USERNAME

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8

# Install runtime dependencies.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install \
        libgnat-14 \
        libllvm21
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

COPY --from=builder /opt/ghdl/ /usr
ENV GHDL_PREFIX=/usr/lib/ghdl

USER $USERNAME
WORKDIR $USERHOME

# Entrypoint is the GHDL executable.
ENTRYPOINT ["ghdl"]
# With e.g. args "-a <file.vhd>" a VHDL design can be analyzed.
# Refer to the online docs for more options https://ghdl.github.io/ghdl/.
# As default do nothing and just print the version.
CMD ["--version"]
