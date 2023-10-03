#!/bin/sh

# Fail on nonzero return
set -e

# https://stackoverflow.com/questions/51903877/docker-load-no-space-left-on-device-rhel
docker system prune -a -f --volumes

# Skip Trivy and Dockle scan steps, image needs too much disk space.
echo "trivy_skip=skip" >> $GITHUB_OUTPUT
echo "dockle_skip=skip" >> $GITHUB_OUTPUT

# This docker image gets rather big as it needs to download Questa with a hefty
# size of more than 2 GB. This would create a single layer in the image with a
# huge size and that has to be downloaded and can't be parallelized. To break
# this layer up, a few steps are performed here in this script that is run
# before the main image is built:
#  - Download / Extract / Install Questa in a separate docker container.
#  - Run the image as container so that the `docker export` command works.
#  - Export the content of that dockerfile to a tar.
#  - Split the tar as file boundaries into multiple tars.
#  - The split tars can be imported with multiple layers on the real Dockerfile.

# Build pre_build dockerfile and export its filesystem as tar.
docker build -t ghcr.io/nikleberg/questasim_pre-build -f pre_build.dockerfile .
docker create --name questasim_pre-build ghcr.io/nikleberg/questasim_pre-build
docker export questasim_pre-build -o questasim_pre-build.tar
docker rm questasim_pre-build

# Split tar into smaller chunks at file boundaries.
TAR_SPLITTER_URL=https://github.com/AQUAOSOTech/tarsplitter/releases/download/v2.2.0/tarsplitter_linux
TAR_SPLITTER_SHA=d92d19b36f03eadd25e9ee17d659761a0788b2e5
wget --progress=dot $TAR_SPLITTER_URL -O tarsplitter
echo "$TAR_SPLITTER_SHA *tarsplitter" | sha1sum --check --strict -
chmod +x tarsplitter
./tarsplitter -i questasim_pre-build.tar -p 5
rm questasim_pre-build.tar
rm tarsplitter
