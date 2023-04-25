# Build risc-v gcc compiler in separate docker builder.
# Process as described in: https://github.com/riscv-collab/riscv-gnu-toolchain
FROM ubuntu:jammy as riscv_gcc_builder

# Install prerequisites.
RUN apt-get -q -y update \
    && apt-get -q -y install \
        git autoconf automake autotools-dev curl python3 libmpc-dev \
        libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf \
        libtool patchutils bc zlib1g-dev libexpat-dev ninja-build \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Get the sources.
ARG RISCV_GNU_CLONE_URL=https://github.com/riscv/riscv-gnu-toolchain
ARG RISCV_GNU_CLONE_TAG=2023.04.21
RUN git clone $RISCV_GNU_CLONE_URL -b $RISCV_GNU_CLONE_TAG --depth 1

# Build with newlib cross-compiler
ARG RISCV_TOOLCHAIN_PATH=/opt/riscv
ARG RISCV_ARCH=rv32imac
ARG RISCV_ABI=ilp32
ENV PATH="$RISCV_TOOLCHAIN_PATH/bin:${PATH}"
RUN cd riscv-gnu-toolchain \
    && ./configure --prefix=/opt/riscv \
        --with-arch=$RISCV_ARCH --with-abi=$RISCV_ABI \
    && make


# Use staging tag to depend on just build image from previous CI stage. For
# releases this is equivalent to latest tag.
FROM ghcr.io/nikleberg/quartus-prime-aji:staging

# Install neccessary tools and dependencies.
RUN apt-get -q -y update \
    && apt-get -q -y install \
        git wget \
        make gcc \
        cutecom \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install precompiled risc-v cross compiler toolchain.
ARG RISCV_TOOLCHAIN_PATH=/opt/riscv
COPY --from=riscv_gcc_builder $RISCV_TOOLCHAIN_PATH $RISCV_TOOLCHAIN_PATH
ENV PATH="$RISCV_TOOLCHAIN_PATH/bin:${PATH}"
ENV RISCV_PREFIX=riscv32-unknown-elf-

# GDB was compiled with support for python debugging, but in the version 3.8.
# Available python version from apt is only the newer 3.10. Install that one and
# create a symlink from "libpython3.10.so.1.0" to "libpython3.8.so.1.0" to allow
# gdb to start i.e. the dynamic library to be loaded at startup. This probably
# breaks python support within gdb, be cautious.
RUN apt-get -q -y update \
    && sed -i '/messagebus/d' /var/lib/dpkg/statoverride \
    && apt-get -q -y install libpython3.10 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s \
        /usr/lib/x86_64-linux-gnu/libpython3.10.so.1.0 \
        /usr/lib/x86_64-linux-gnu/libpython3.8.so.1.0
