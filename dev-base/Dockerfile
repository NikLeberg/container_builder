# A basic devcontainer image with basic bootstraping tools for development.
#
# Main goal is to provide Docker-outside-of-Docker (DooD) functionality to
# re-use the hosts docker environment to launch additional containers as needed.
#
# Parts of this Dockerfile are based off (both under MIT license):
#  - https://github.com/devcontainers/images/blob/main/src/universal/.devcontainer/Dockerfile
#  - https://github.com/devcontainers/features/blob/main/src/docker-outside-of-docker/install.sh

FROM ubuntu:jammy

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ARG DEBIAN_FRONTEND=noninteractive

# Development tools
RUN <<EOF
    set -e
    apt-get -q -y update && apt-get -q -y install --no-install-recommends \
        git wget make
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Docker-outside-of-Docker (DooD)
# requires "-v /var/run/docker.sock:/var/run/docker.sock" on run
RUN <<EOF
    set -e
    apt-get -q -y update && apt-get -q -y install --no-install-recommends \
        ca-certificates curl gnupg
    mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu `. /etc/os-release && echo $VERSION_CODENAME` stable" > /etc/apt/sources.list.d/docker.list
    apt-get -q -y update
    apt-get -q -y install --no-install-recommends \
        docker-ce-cli
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF
