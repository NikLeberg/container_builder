FROM ubuntu:18.04 as openocd_builder

# Install neccessary tools and dependencies, libaji_client and aji_openocd use
# old compiler flags that are incompatible with gcc > 8.
RUN apt-get -q -y update \
    && apt-get -q -y install \
        autoconf automake m4 libtool pkg-config texinfo cpio zip \
        make gcc-8 g++-8 \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives \
        --install /usr/bin/gcc gcc /usr/bin/gcc-8 60 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
    && update-alternatives --config gcc

# Clone, configure and build libaji_client
# The library has -Werror enabled and has warnings that we cant fix, the below
# sed commands fix the hard errors to just warnings.
ARG LIBAJI_CLONE_URL=https://github.com/intel/libaji_client.git
ARG LIBAJI_CLONE_TAG=R22.4
RUN git clone $LIBAJI_CLONE_URL -b $LIBAJI_CLONE_TAG --depth 1 \
    && cd libaji_client \
    && ./bootstrap \
    && ./configure \
    && sed -i 's/#           error/\/\/#           error/g' ./src/h/aji_macros_sys.h \
    && sed -i 's/-Werror / /g' ./Makefile \
    && sed -i 's/-Werror / /g' ./src/jtag/Makefile \
    && make \
    && cd ..

# Clone, configure and build aji_openocd
# The aji fork uses C++ and as such the OpenOCD link step needs to happen with
# g++ instead of gcc.
ARG AJI_OPENOCD_CLONE_URL=https://github.com/intel/aji_openocd.git
ARG AJI_OPENOCD_CLONE_TAG=R22.4
RUN git clone $AJI_OPENOCD_CLONE_URL -b $AJI_OPENOCD_CLONE_TAG --depth 1 \
    && cd aji_openocd \
    && ./bootstrap \
    && ./configure --enable-aji_client CCLD=g++ \
    && cp ./../libaji_client/src/jtag/.libs/libaji_client.a ./src/ \
    && sed -i 's/-fstack-clash-protection / /g' ./src/jtag/drivers/aji_client/Makefile.am \
    && sed -i 's/-fstack-clash-protection / /g' ./src/jtag/drivers/aji_client/aji/Makefile.am \
    && make || true \
    && sed -i 's/CCLD = \$(CC)/CCLD = g++/g' ./Makefile \
    && make

# Import built openocd into quartus prime container.
FROM ghcr.io/nikleberg/quartus-prime:latest
RUN mkdir /opt/aji_openocd
COPY --from=openocd_builder /aji_openocd/src/openocd ./opt/aji_openocd/
COPY --from=openocd_builder /aji_openocd/tcl ./opt/aji_openocd/tcl
