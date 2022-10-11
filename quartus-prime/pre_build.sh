#!/bin/sh

# https://stackoverflow.com/questions/51903877/docker-load-no-space-left-on-device-rhel
docker system prune -a -f --volumes

# Skip Trivy scan step, image needs too much disk space.
echo "::set-output name=trivy_skip::skip"
