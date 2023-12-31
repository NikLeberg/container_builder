# Build ghdl into standalone execitable with mcode backend.
# Process as described in: https://ghdl.github.io/ghdl/development/building/mcode.html
FROM ubuntu:jammy as builder

# Install prerequisites.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        ca-certificates \
        git \
        make \
        gcc \
        gnat \
        libz-dev
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Get the sources.
ARG GHDL_CLONE_URL=https://github.com/ghdl/ghdl
ARG GHDL_CLONE_TAG=master
RUN git clone $GHDL_CLONE_URL -b $GHDL_CLONE_TAG

# Build and install to /opt
ARG PREFIX=/opt/ghdl
RUN <<EOF
    set -e
    mkdir ghdl/build
    cd ghdl/build
    ../configure --prefix=$PREFIX
    make
    make install
EOF


# Put the compiled binary into a fresh image.
FROM ubuntu:jammy

# Install host tools.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        make gcc
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Install precompiled ghdl executable.
ARG PREFIX=/opt/ghdl
COPY --from=builder $PREFIX $PREFIX
ENV PATH="$PREFIX/bin:${PATH}"

# Set entrypoint to the executable.
ENTRYPOINT ["ghdl"]
# As default do nothing and just print the version.
CMD ["--version"]
