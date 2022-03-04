# Pull in the (probably) just built image, and show the architecture.
FROM ghcr.io/nikleberg/speki-ci:latest

RUN uname -a
RUN dpkg --print-architecture
