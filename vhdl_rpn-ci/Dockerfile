# https://hub.docker.com/r/fdagosti/quartus_cyclone
FROM fdagosti/quartus_cyclone:21

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# Add quartus to path
ENV PATH="/home/developer/altera_lite/quartus/bin/:${PATH}"

# Update packages
RUN apt-get -q -y update \
    && apt-get -q -y upgrade \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
