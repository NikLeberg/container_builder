# Build Qt6.5 and PySide6.5 for the aarch64/arm64 architecture.

ARG USERNAME=torizon
ARG IMAGE_BASE=debian:bookworm
ARG TARGET_ARCH=linux/arm64

# Do the builk of the work on the host machine architecture.
FROM ghcr.io/nikleberg/qt6-target:staging AS host

# Install PySide6 build dependencies.
RUN apt-get -y update && apt-get install -y --no-install-recommends \
        # basic python environment
        python3 \
        python3-dev \
        python3-pip \
        # qt dependencies
        # we depend on qt6.5 that was built further up, as soon as that is
        # mainlined (see: https://tracker.debian.org/pkg/qt6-base) we can just
        # install these:
        #qt6-base-dev \
        #qt6-declarative-dev \
        #qt6-wayland-dev \
        # build dependencies
        cmake \
        ninja-build \
        llvm-dev \
        clang \
        libclang-dev \
        # dev dependencies
        git \
    && apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

# Cross-Compile PySide6 from source.
# see: https://codereview.qt-project.org/c/pyside/pyside-setup/+/374068
ARG PYSIDE6_SETUP_CLONE_URL=https://code.qt.io/pyside/pyside-setup
ARG PYSIDE6_SETUP_CLONE_TAG=6.5
COPY shiboken6.patch /pyside-setup/shiboken6.patch
RUN git clone $PYSIDE6_SETUP_CLONE_URL -b $PYSIDE6_SETUP_CLONE_TAG \
    && cd pyside-setup \
    && git apply shiboken6.patch \
    && pip3 install -r requirements.txt --break-system-packages \
    && python3 setup.py bdist_wheel --parallel=2 --ignore-git --reuse-build \
        --cmake-toolchain-file=/qt6-targetbuild/toolchain.cmake \
        --qt-host-path=/opt/qt6-host \
        --qt-target-path=/opt/qt6-target \
        --plat-name=linux_aarch64 \
        --module-subset=Core,Gui,Widgets \
        --standalone --unity \
        --verbose-build --no-qt-tools
