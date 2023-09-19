# Build Qt6.5 and PySide6.5 for the aarch64/arm64 architecture.

ARG USERNAME=torizon
ARG IMAGE_BASE=debian:bookworm
ARG TARGET_ARCH=linux/arm64

# Create a target layer where the correct arm64 libraries are available
FROM --platform=$TARGET_ARCH $IMAGE_BASE AS target

# Install EGL and Wayland backend
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
        libwayland-bin \
        libgles2-mesa-dev \
        # basic python environment
        python3 \
        python3-dev \
    && apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*


# Do the bulk of the work on the host machine architecture.
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
        pkg-config \
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
        -- -DBUILD_qtwayland=ON \
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
        -prefix /usr/local/qt6 -xplatform linux-aarch64-gnu-g++ \
        -device-option CROSS_COMPILE=aarch64-linux-gnu- \
        -skip qt3d -skip qtquick3d -skip qtwebengine -skip qtwebview \
        -skip qtwebsockets -skip qtwebchannel -skip qtmultimedia \
        -skip qtquick3dphysics \
        -- -DCMAKE_TOOLCHAIN_FILE=/qt6-targetbuild/toolchain.cmake \
        -DBUILD_qtwayland=ON -DFEATURE_xcb=OFF \
    && cmake --build . --parallel \
    && cmake --install .

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
    && pip3 install -r requirements.txt --break-system-packages \
    && git apply shiboken6.patch \
    && python3 setup.py bdist_wheel --parallel=4 --ignore-git --reuse-build \
        --cmake-toolchain-file=/qt6-targetbuild/toolchain.cmake \
        --qt-host-path=/opt/qt6-host \
        --qt-target-path=/opt/qt6-target \
        --plat-name=linux_aarch64 \
        --module-subset=Core,Gui,Widgets \
        --standalone --unity \
        --verbose-build --no-qt-tools
