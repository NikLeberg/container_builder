# Build risc-v gcc compiler in separate docker builder.
# Process as described in: https://github.com/riscv-collab/riscv-gnu-toolchain
FROM ubuntu:22.04 as riscv_gcc_builder

# Install prerequisites.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        ca-certificates \
        git autoconf automake autotools-dev curl python3 libmpc-dev \
        libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf \
        libtool patchutils bc zlib1g-dev libexpat-dev ninja-build
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Get the sources.
ARG RISCV_GNU_CLONE_URL=https://github.com/riscv/riscv-gnu-toolchain
ARG RISCV_GNU_CLONE_TAG
RUN git clone $RISCV_GNU_CLONE_URL -b $RISCV_GNU_CLONE_TAG --depth 1

# Build with newlib cross-compiler
ARG RISCV_TOOLCHAIN_PATH=/opt/riscv
ARG RISCV_ARCH
ARG RISCV_ABI
ENV PATH="$RISCV_TOOLCHAIN_PATH/bin:${PATH}"
RUN <<EOF
    set -e
    cd riscv-gnu-toolchain
    ./configure --prefix=/opt/riscv \
        --with-arch=$RISCV_ARCH --with-abi=$RISCV_ABI
    make
EOF


# Put the compiled binaries into a fresh image.
FROM ubuntu:22.04

# Install host toolchain.
RUN <<EOF
    set -e
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        make gcc libc-dev openocd
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Install precompiled risc-v cross compiler toolchain.
ARG RISCV_TOOLCHAIN_PATH=/opt/riscv
COPY --from=riscv_gcc_builder $RISCV_TOOLCHAIN_PATH $RISCV_TOOLCHAIN_PATH
ENV PATH="$RISCV_TOOLCHAIN_PATH/bin:${PATH}"
ENV RISCV_PREFIX=riscv32-unknown-elf-

# Entrypoint is the gcc cross compiler.
ENTRYPOINT ["riscv32-unknown-elf-gcc"]
# As default do nothing and just print the version.
CMD ["--version"]
