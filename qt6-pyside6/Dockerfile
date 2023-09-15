# Build Qt6.5 and PySide6.5 for the aarch64/arm64 architecture.

ARG USERNAME=torizon
ARG IMAGE_BASE=debian:bookworm
ARG TARGET_ARCH=linux/arm64

# Create a target layer where the correct arm64 libraries are available
FROM --platform=$TARGET_ARCH $IMAGE_BASE AS target

# Do the build of the work on the host machine architecture.
FROM $IMAGE_BASE AS host

# Cross-Compile Qt6, source:
# https://wiki.qt.io/Cross-Compile_Qt_6_for_Raspberry_Pi
# ToDo: check how to support Wayland

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
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
    && apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

# Build Qt6 from source for host.
# https://wiki.qt.io/Building_Qt_6_from_Git
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
        -- -DBUILD_qtwebengine=OFF \
    && cmake --build . --parallel \
    && cmake --install .

# Copy the target sysroot.
COPY --from=target /lib target-sysroot/lib
COPY --from=target /usr/include target-sysroot/usr/include
COPY --from=target /usr/lib target-sysroot/usr/lib
RUN symlinks -rc target-sysroot

# Build Qt6 from source for target (cross-compiling).
COPY toolchain.cmake /qt6-targetbuild/toolchain.cmake
RUN cd qt6-targetbuild \
    && ../qt6/configure -release -opengl es2 -nomake examples \
        -nomake tests -qt-host-path /opt/qt6-host -extprefix /opt/qt6-target \
        -prefix /usr/local/qt6 -device linux-aarch64 \
        -device-option CROSS_COMPILE=aarch64-linux-gnu- -- \
        -DBUILD_qtwebengine=OFF \
        -DCMAKE_TOOLCHAIN_FILE=/qt6-targetbuild/toolchain.cmake \
        -DQT_FEATURE_xcb=ON -DFEATURE_xcb_xlib=ON -DQT_FEATURE_xlib=ON \
    && cmake --build . --parallel \
    && cmake --install .
