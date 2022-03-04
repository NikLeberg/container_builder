# Pull in the (probably) just built image, and show the architecture.
FROM --platform=linux/arm/v7 ghcr.io/nikleberg/speki-ci:latest

RUN uname -a
RUN dpkg --print-architecture
