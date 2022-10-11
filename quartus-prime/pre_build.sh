#!/bin/sh

# https://stackoverflow.com/questions/51903877/docker-load-no-space-left-on-device-rhel
docker system prune -a -f --volumes

# Skip Trivy and Dockle scan steps, image needs too much disk space.
echo "::set-output name=trivy_skip::skip"
echo "::set-output name=dockle_skip::skip"
