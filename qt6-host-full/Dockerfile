ARG IMAGE_BASE=debian:bookworm

# Do the bulk of the work on the host machine architecture.
FROM $IMAGE_BASE AS host

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
        # wayland support?
        libwayland-dev \
        libwayland-egl1 \
        libwayland-bin \
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
        -- -DBUILD_qtwayland=ON \
    && cmake --build . --parallel \
    && cmake --install .

# Only keep build Qt6 binaries
FROM $IMAGE_BASE AS min_host
COPY --from=host /opt/qt6-host /opt/qt6-host
