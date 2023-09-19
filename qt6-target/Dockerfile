# Build Qt6.5 and PySide6.5 for the aarch64/arm64 architecture.

ARG USERNAME=torizon
ARG IMAGE_BASE=debian:bookworm
ARG TARGET_ARCH=linux/arm64

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


# Do the builk of the work on the host machine architecture.
FROM ghcr.io/nikleberg/qt6-host:staging AS host

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
        -prefix /usr/local/qt6 -xplatform linux-aarch64-gnu-g++ \
        -device-option CROSS_COMPILE=aarch64-linux-gnu- \
        -skip qt3d -skip qtquick3d -skip qtwebengine -skip qtwebview \
        -skip qtwebsockets -skip qtwebchannel -skip qtmultimedia \
        -skip qtquick3dphysics \
        -- -DCMAKE_TOOLCHAIN_FILE=/qt6-targetbuild/toolchain.cmake \
        -DBUILD_qtwayland=ON -DFEATURE_xcb=OFF \
    && cmake --build . --parallel \
    && cmake --install .
