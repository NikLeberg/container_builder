#!/bin/sh

# https://stackoverflow.com/questions/51903877/docker-load-no-space-left-on-device-rhel
docker system prune -a -f --volumes

# Skip Trivy scan step, image needs too much disk space.
echo "trivy_skip=skip" >> $GITHUB_OUTPUT

# Suppress Dockle errors that are caused by baseimage fdagosti/quartus_cyclone.
echo "DOCKLE_IGNORES=DKL-DI-0001,DKL-DI-0005" >> $GITHUB_ENV
