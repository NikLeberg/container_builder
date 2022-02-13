# Pull in the (probably) just built image, clone the tdd-platform project repo
# and try to build for each platform.
FROM ghcr.io/nikleberg/tdd-platform:latest

RUN git clone https://github.com/NikLeberg/tdd-platform.git --recurse-submodules \
    && cd tdd-platform \
    && git reset --hard 689b179

SHELL ["/bin/bash", "-c"]
WORKDIR /tdd-platform

RUN cmake -S . -B build/linux -DPLATFORM=linux \
    && make -C build/linux all

RUN source platform/esp32/environment.sh \
    && cmake -S . -B build/esp32 -DPLATFORM=esp32 \
    && make -C build/esp32 all

RUN source platform/esp8266/environment.sh \
    && cmake -S . -B build/esp8266 -DPLATFORM=esp8266 \
    && make -C build/esp8266 all

RUN source platform/carme-m4/environment.sh \
    && cmake -S . -B build/carme-m4 -DPLATFORM=carme-m4 \
    && make -C build/carme-m4 all
