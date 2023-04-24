FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

RUN apt-get -q -y update && apt-get -q -y install --no-install-recommends \
        git \
        libc-dev \
        gcc \
        llvm \
        clang \
        make \
        cmake \
        ccache \
        doxygen \
        graphviz \
        cppcheck \
        clang-tidy \
        jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Update ca-certificates to fix failing git server certificate verification.
RUN apt-get -q -y update && apt-get -q -y install --no-install-recommends \
        apt-transport-https ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates

# Install packages for libFuzzer fuzzing with protocol buffers support
ARG PROTOBUF_MUTATOR_CLONE_URL=https://github.com/google/libprotobuf-mutator.git
ARG PROTOBUF_MUTATOR_CLONE_TAG=v1.0

RUN apt-get -q -y update && apt-get -q -y install --no-install-recommends \
        protobuf-compiler \
        libprotobuf-dev \
        liblzma-dev \
        libz-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && cd /tmp \
    && git clone $PROTOBUF_MUTATOR_CLONE_URL -b $PROTOBUF_MUTATOR_CLONE_TAG --depth 1 \
    && cd ./libprotobuf-mutator && mkdir ./build && cd ./build \
    && cmake .. -DCMAKE_BUILD_TYPE=Release -DLIB_PROTO_MUTATOR_TESTING=OFF \
    && make install \
    && rm -rf /tmp/libprotobuf-mutator

# Install packages for Python support
RUN apt-get -q -y update && apt-get -q -y install --no-install-recommends \
        python3=3.10* \
        python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install \
        /usr/bin/python python /usr/bin/python3.10 1 \
    && update-alternatives --set \
        python /usr/bin/python3.10

# Install packages for KLEE symbolic execution support.
ARG STP_CLONE_URL=https://github.com/stp/stp.git
ARG STP_CLONE_TAG=2.3.3
ARG KLEE_CLONE_URL=https://github.com/klee/klee.git
ARG KLEE_CLONE_TAG=master

RUN apt-get -q -y update && apt-get -q -y install --no-install-recommends \
        zlib1g-dev \
        minisat \
        bison \
        flex \
        libsqlite3-dev \
        llvm-dev \
        wget \
        file \
    && cd /tmp \
    && git clone $STP_CLONE_URL -b $STP_CLONE_TAG --depth 1 \
    && CXXFLAGS="-w" cmake -S stp -B stp/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DSTATICCOMPILE=ON \
    && make -C stp/build install \
    && rm -rf stp \
    && apt-get -q -y remove bison flex \
    && apt-get autoremove -q -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && git clone $KLEE_CLONE_URL -b $KLEE_CLONE_TAG \
    && CXXFLAGS="-w" cmake -S klee -B klee/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_SOLVER_STP=ON \
        -DKLEE_RUNTIME_BUILD_TYPE=Release \
        -DENABLE_TCMALLOC=OFF \
        -DENABLE_SYSTEM_TESTS=OFF \
    && make -C klee/build install \
    && rm -rf klee \
    && pip install wllvm tabulate

# Install packages for GraphFuzz structure aware fuzzing.
ARG GFUZZ_CLONE_URL=https://github.com/hgarrereyn/GraphFuzz.git
ARG GFUZZ_CLONE_TAG=master

RUN pip install poetry \
    && cd /tmp \
    && git clone $GFUZZ_CLONE_URL -b $GFUZZ_CLONE_TAG --depth 1 \
    && cmake -S GraphFuzz -B GraphFuzz/build -DCMAKE_BUILD_TYPE=Release \
    && make -C GraphFuzz/build install \
    && cd ./GraphFuzz/cli \
    && poetry build \
    && poetry export > dist/requirements.txt \
    && pip install -r dist/requirements.txt \
    && pip install ./dist/gfuzz-*.whl \
    && cd ../../ \
    && rm -rf GraphFuzz

# Install shared packages for ESP8266 & ESP32 support
RUN apt-get -q -y update && apt-get -q -y install --no-install-recommends \
        libusb-1.0-0-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install esp-idf for ESP32 support
ARG ESP32_CLONE_URL=https://github.com/espressif/esp-idf.git
ARG ESP32_CLONE_TAG=v4.4

RUN mkdir -p ~/.espressif \
    && cd ~/.espressif \
    && git clone $ESP32_CLONE_URL -b $ESP32_CLONE_TAG --depth 1 \
    && cd ./esp-idf \
    && jq '.tools[] .install = "never"' \
        ./tools/tools.json > ./tools/tools_never.json \
    && jq '(.tools[] | select(.name == "xtensa-esp32-elf" or .name == "esp32ulp-elf" or .name == "openocd-esp32")).install = "always"' \
        ./tools/tools_never.json > ./tools/tools.json \
    && rm ./tools/tools_never.json \
    && sed -i -e 's/^__main && __enable_autocomplete$/__main/g' ./export.sh \
    && ./install.sh \
    && rm -rf ~/.espressif/dist

# Install sdk for ESP8266 support
ARG ESP8266_CLONE_URL=https://github.com/espressif/ESP8266_RTOS_SDK.git
ARG ESP8266_CLONE_TAG=v3.4

RUN mkdir -p ~/.espressif \
    && cd ~/.espressif \
    && git clone $ESP8266_CLONE_URL -b $ESP8266_CLONE_TAG --depth 1 \
    && ./ESP8266_RTOS_SDK/install.sh \
    && rm -rf ~/.espressif/dist

# Install packages for CARME-M4 support (see: https://askubuntu.com/a/1243405)
# https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/downloads
ARG ARM_TOOLCHAIN_VERSION=10.3-2021.10

RUN apt-get -q -y update && apt-get -q -y install --no-install-recommends \
        wget \
        bzip2 \
        stlink-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && wget -nv -O gcc-arm-none-eabi.tar.bz2 https://developer.arm.com/-/media/Files/downloads/gnu-rm/${ARM_TOOLCHAIN_VERSION}/gcc-arm-none-eabi-${ARM_TOOLCHAIN_VERSION}-x86_64-linux.tar.bz2 \
    && mkdir -p ~/.stm32 \
    && tar -xjf gcc-arm-none-eabi.tar.bz2 -C ~/.stm32/ \
    && mv ~/.stm32/gcc-arm-none-eabi-${ARM_TOOLCHAIN_VERSION} ~/.stm32/gcc-arm-none-eabi/

# Install sdk for CARME-M4 support
ARG STM32_CMAKE_CLONE_URL=https://github.com/ObKo/stm32-cmake
ARG STM32_CMAKE_CLONE_TAG=v2.1.0

RUN mkdir -p ~/.stm32 \
    && cd ~/.stm32 \
    && git clone $STM32_CMAKE_CLONE_URL -b $STM32_CMAKE_CLONE_TAG --depth 1 \
    && rm -rf ~/.stm32/.git
