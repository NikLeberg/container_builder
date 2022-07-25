FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# Update all packages and install neccessary tools and dependencies
RUN apt-get -q -y update \
    && apt-get -q -y upgrade \
    && apt-get -q -y install \
        git wget make python3 python3-pip \
        cpio libncurses5 openocd gdb \
        cppcheck doxygen graphviz \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN pip3 install cppcheck-junit doxygen-junit

# Install gcc-arm-none-eabi
RUN wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 -O gcc-arm-none-eabi.tar.bz2 \
    && mkdir gcc-arm-none-eabi && tar xjfv gcc-arm-none-eabi.tar.bz2 -C gcc-arm-none-eabi --strip-components 1 \
    && rm gcc-arm-none-eabi.tar.bz2
ENV PATH="/gcc-arm-none-eabi/bin:${PATH}"
