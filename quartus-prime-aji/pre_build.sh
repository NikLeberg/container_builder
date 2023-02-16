#!/bin/sh

# https://stackoverflow.com/questions/51903877/docker-load-no-space-left-on-device-rhel
docker system prune -a -f --volumes

# Skip Trivy and Dockle scan steps, image needs too much disk space.
echo "trivy_skip=skip" >> $GITHUB_OUTPUT
echo "dockle_skip=skip" >> $GITHUB_OUTPUT
