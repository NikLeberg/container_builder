FROM espressif/idf:release-v5.1

WORKDIR /

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# Install espressif QEMU fork https://github.com/espressif/qemu
ENV QEMU_REL=esp-develop-20220203
ENV QEMU_SHA256=c83e483e3290f48a563c2a376b7413cd94a8692d8c7308b119f4268ca6d164b6
ENV QEMU_DIST=qemu-${QEMU_REL}.tar.bz2
ENV QEMU_URL=https://github.com/espressif/qemu/releases/download/${QEMU_REL}/${QEMU_DIST}
RUN wget --no-verbose ${QEMU_URL} \
    && echo "${QEMU_SHA256} *${QEMU_DIST}" | sha256sum --check --strict - \
    && tar -xf $QEMU_DIST -C /opt \
    && rm ${QEMU_DIST}
ENV PATH=/opt/qemu/bin:${PATH}

# Install QEMU runtime dependencies and newest git
RUN apt-get -q -y update && apt-get -q -y install \
        libpixman-1-0 \
        libnuma1 \
        libglib2.0-0 \
        software-properties-common \
    && add-apt-repository -y ppa:git-core/ppa \
    && apt-get -q -y install git \
    && rm -rf /var/lib/apt/lists/*

# Fixup idf export script. Then add a bash env file that sources it.
RUN sed -i -e 's/^__main && __enable_autocomplete$/__main/g' /opt/esp/idf/export.sh
COPY env.sh /opt/esp/env.sh
ENV BASH_ENV=/opt/esp/env.sh

# Fix CVE-2021-3995 and CVE-2021-3996
RUN apt-get -q -y update && apt-get -q -y install \
        util-linux \
    && rm -rf /var/lib/apt/lists/*
