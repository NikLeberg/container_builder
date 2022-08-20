# Pull in the (probably) just built image, clone the tdd-platform project repo
# and try to build for each platform.
FROM ghcr.io/nikleberg/tdd-platform:latest

RUN git clone https://github.com/NikLeberg/tdd-platform.git --recurse-submodules \
    && cd tdd-platform \
    && git reset --hard 135907c

SHELL ["/bin/bash", "-c"]
WORKDIR /tdd-platform

# ESP32
RUN source platform/esp32/environment.sh \
    && cmake -S . -B build/esp32 -DPLATFORM=esp32 \
    && make -C build/esp32 all

# ESP8266
RUN source platform/esp8266/environment.sh \
    && cmake -S . -B build/esp8266 -DPLATFORM=esp8266 \
    && make -C build/esp8266 all

# Carme-M4
RUN source platform/carme-m4/environment.sh \
    && cmake -S . -B build/carme-m4 -DPLATFORM=carme-m4 \
    && make -C build/carme-m4 all

# Linux
RUN cmake -S . -B build/linux -DPLATFORM=linux \
    && make -C build/linux all

# Fuzzing - Protobuf
ADD corpus_proto.tar.bz2 build/linux/tests/fuzzing/buggy_api_proto/corpus
RUN make -C build/linux fuzzing_buggy_api_proto_run

# Fuzzing - GraphFuzz
ADD corpus_graphfuzz.tar.bz2 build/linux/tests/fuzzing/buggy_api_graphfuzz/corpus
RUN make -C build/linux fuzzing_buggy_api_graphfuzz_run

# Symbolic execution
RUN make -C build/linux symbolic_buggy_api_run
