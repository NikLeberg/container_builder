# Use staging tag to depend on just build image from previous CI stage. For
# releases this is equivalent to latest tag.
FROM ghcr.io/nikleberg/quartus-prime-aji:staging

# Install neccessary tools and dependencies.
RUN apt-get -q -y update \
    && apt-get -q -y install \
        git wget \
        make gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

# Install precompiled risc-v cross compiler toolchain.
ARG RISCV_TOOLCHAIN_URL=https://github.com/stnolting/riscv-gcc-prebuilt/releases/download/rv64imc-3.0.0/riscv64-unknown-elf.gcc-12.1.0.tar.gz
ARG RISCV_TOOLCHAIN_SHA=8f3ea0f821feaaf664a442cd7e2871b1b1b3ace1
ARG RISCV_TOOLCHAIN_PATH=/opt/riscv
RUN wget --progress=dot:giga $RISCV_TOOLCHAIN_URL -O toolchain.tar.gz \
    && echo "$RISCV_TOOLCHAIN_SHA *toolchain.tar.gz" | sha1sum --check --strict - \
    && mkdir -p $RISCV_TOOLCHAIN_PATH \
    && tar -xzf toolchain.tar.gz -C $RISCV_TOOLCHAIN_PATH \
    && rm toolchain.tar.gz
ENV PATH="$RISCV_TOOLCHAIN_PATH/bin:${PATH}"

# GDB was compiled with support for python debugging, but in the version 3.8.
# Available python version from apt is only the newer 3.10. Install that one and
# create a symlink from "libpython3.10.so.1.0" to "libpython3.8.so.1.0" to allow
# gdb to start i.e. the dynamic library to be loaded at startup. This probably
# breaks python support within gdb, be cautious.
RUN apt-get -q -y update \
    && apt-get -q -y install libpython3.10 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s \
        /usr/lib/x86_64-linux-gnu/libpython3.10.so.1.0 \
        /usr/lib/x86_64-linux-gnu/libpython3.8.so.1.0
