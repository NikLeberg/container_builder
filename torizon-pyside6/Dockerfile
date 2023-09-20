# ARGUMENTS --------------------------------------------------------------------
##
# Base container version
##
ARG BASE_VERSION=3.0.8
ARG SDK_BASE_VERSION=3.0.8

##
# Application Name
##
ARG APP_EXECUTABLE=__change__

##
# Board architecture
# arm or arm64
##
ARG IMAGE_ARCH=arm64

##
# Board GPU vendor prefix
##
ARG GPU=

# TODO: cross compile x86 to arm
# We will use emulation here
# BUILD ------------------------------------------------------------------------
FROM --platform=linux/${IMAGE_ARCH} \
    torizon/wayland-base${GPU}:${SDK_BASE_VERSION} AS Build

ARG IMAGE_ARCH
ARG GPU

# stick to bookworm on /etc/apt/sources.list.d
RUN sed -i 's/sid/bookworm/g' /etc/apt/sources.list.d/debian.sources

# __deps__
RUN apt-get -q -y update && \
    apt-get -q -y install \
    build-essential \
    qmake6 \
    qt6-base-private-dev \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-declarative-private-dev \
    libqt6opengl6-dev \
    # ADD YOUR PACKAGES HERE
    file \
    curl \
    qt6-wayland \
    qt6-wayland-dev \
    qml6-module-qtqml \
    qml6-module-qtqml-workerscript \
    qml6-module-qtcore \
    qml6-module-qtquick \
    qml6-module-qtquick-window \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-templates \
    python3 \
    python3-dev \
    python3-pip \
    cmake \
    ninja-build \
    llvm-dev \
    clang \
    libclang-dev \
    git \
# DO NOT REMOVE THIS LABEL: this is used for VS Code automation
    # __torizon_packages_dev_start__
    # __torizon_packages_dev_end__
# DO NOT REMOVE THIS LABEL: this is used for VS Code automation
    && \
    apt-get clean && apt-get autoremove && \
    rm -rf /var/lib/apt/lists/*
# __deps__

# Compile PySide6 from source.
# see: https://codereview.qt-project.org/c/pyside/pyside-setup/+/374068
ARG PYSIDE6_SETUP_CLONE_URL=https://code.qt.io/pyside/pyside-setup
ARG PYSIDE6_SETUP_CLONE_TAG=6.4.2
RUN git clone $PYSIDE6_SETUP_CLONE_URL -b $PYSIDE6_SETUP_CLONE_TAG \
    && cd pyside-setup \
    && pip3 install -r requirements.txt --break-system-packages
COPY shiboken6.patch /pyside-setup/shiboken6.patch
RUN cd pyside-setup \
    && git apply shiboken6.patch \
    && python3 setup.py bdist_wheel --parallel=4 --ignore-git --reuse-build \
        --module-subset=Core,Gui,Widgets \
        --standalone --unity \
        --verbose-build --no-qt-tools
