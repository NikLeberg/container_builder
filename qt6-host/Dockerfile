# Build Qt6.5 and PySide6.5 for the aarch64/arm64 architecture.

ARG USERNAME=torizon
ARG IMAGE_BASE=debian:bookworm
ARG TARGET_ARCH=linux/arm64

# Do the builk of the work on the host machine architecture.
FROM $IMAGE_BASE AS host

# Cross-Compile Qt6, source:
# https://wiki.qt.io/Cross-Compile_Qt_6_for_Raspberry_Pi

# Install Qt6 build dependencies and arm cross compiler
RUN apt-get -y update && apt-get install -y --no-install-recommends \
        # build dependencies
        cmake \
        gcc \
        g++ \
        libc-dev \
        ninja-build \
        git \
        wget \
        libegl1-mesa-dev \
        python3 \
        # cross-compile dependencies
        symlinks \
        pkg-config \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
    && apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

# Build Qt6 from source for host.
# https://wiki.qt.io/Building_Qt_6_from_Git
# See dependency graph: https://qt-kde-team.pages.debian.net/images/qt6_build_deps.png
ARG QT_CLONE_URL=git://code.qt.io/qt/qt5.git
ARG QT_CLONE_TAG=v6.5.2
RUN git clone $QT_CLONE_URL qt6 -b $QT_CLONE_TAG --depth 1 \
    && cd qt6 \
    && git config --global http.sslverify false \
    && perl init-repository \
    && git config --global http.sslverify true \
    && mkdir ../qt6-hostbuild \
    && cd ../qt6-hostbuild \
    && ../qt6/configure -release -prefix /opt/qt6-host \
        -skip qt3d -skip qtquick3d -skip qtwebengine -skip qtwebview \
        -skip qtwebsockets -skip qtwebchannel -skip qtmultimedia \
        -skip qtquick3dphysics \
    && cmake --build . --parallel \
    && cmake --install .
