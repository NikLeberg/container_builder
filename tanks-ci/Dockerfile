FROM ubuntu:hirsute

WORKDIR /

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -q -y update \
    && apt-get -q -y install \
        gcc-8 cmake  \
        libsdl2-dev libsdl2-image-dev libsdl2-net-dev libsdl2-ttf-dev libsdl2-mixer-dev \
        cppcheck python3 python3-pip \
        doxygen graphviz \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install cppcheck-junit doxygen-junit
