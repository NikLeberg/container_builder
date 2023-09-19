# Build Qt6.5 and PySide6.5 for the aarch64/arm64 architecture.

ARG USERNAME=torizon
ARG IMAGE_BASE=debian:bookworm
ARG TARGET_ARCH=linux/arm64

# Do the builk of the work on the host machine architecture.
FROM ghcr.io/nikleberg/qt6-target:staging AS host

# Create a target layer where the correct arm64 libraries are available
FROM --platform=$TARGET_ARCH $IMAGE_BASE AS target

# Install EGL backend
RUN apt-get -y update && apt-get install -y --no-install-recommends \
        # from qtwayland5 debian package dependencies:
        libegl1-mesa-dev \
        libfontconfig-dev \
        libglib2.0-dev \
        libinput-dev \
        libmtdev-dev \
        libudev-dev \
        libwayland-dev \
        libwayland-egl1 \
        libxcomposite-dev \
        libxkbcommon-dev \
        libxrender-dev \
        # incrementally added:
        libdrm-dev \
        libgbm-dev \
    && apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

# Add Qt6 to the actual target.
COPY --from=host /opt/qt6-target /opt/qt6

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

# Build PySide6 from source.
ARG PYSIDE6_SETUP_CLONE_URL=https://code.qt.io/pyside/pyside-setup
ARG PYSIDE6_SETUP_CLONE_TAG=6.5
RUN git clone $PYSIDE6_SETUP_CLONE_URL -b $PYSIDE6_SETUP_CLONE_TAG --depth 1 \
    && cd pyside-setup \
    && pip3 install -r requirements.txt --break-system-packages \
    && python3 setup.py build \
        --qtpaths=/opt/qt6/bin/qtpaths6 \
        --module-subset=Core,Gui,Widgets --standalone \
        --ignore-git --parallel=4 --unity --no-qt-tools
