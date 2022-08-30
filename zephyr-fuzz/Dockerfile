FROM ghcr.io/nikleberg/zephyr-dev:latest

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# Install llvm toolchain
RUN apt-get -q -y update && apt-get -q -y install --no-install-recommends \
        llvm \
        clang \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
# Install GraphFuzz for structure aware fuzzing
ARG GFUZZ_CLONE_URL=https://github.com/NikLeberg/GraphFuzz.git
ARG GFUZZ_CLONE_TAG=output_to_cerr
RUN apt-get -q -y update && apt-get -q -y install --no-install-recommends \
        protobuf-compiler \
        libprotobuf-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && pip install poetry \
    && cd /tmp \
    && git clone $GFUZZ_CLONE_URL -b $GFUZZ_CLONE_TAG --depth 1 \
    && cmake -S GraphFuzz -B GraphFuzz/build -DCMAKE_BUILD_TYPE=Release \
    && make -C GraphFuzz/build install \
    && cd ./GraphFuzz/cli \
    && poetry build \
    && poetry export > dist/requirements.txt \
    && pip install -r dist/requirements.txt \
    && pip install ./dist/gfuzz-*.whl \
    && cd ../../ \
    && rm -rf GraphFuzz
