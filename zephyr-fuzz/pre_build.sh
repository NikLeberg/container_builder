#!/bin/sh

# Execute whatever zephyr-dev defines as pre build step.
cd ../zephyr-dev
./pre_build.sh

# Disable security scanning, zephyr-dev is already scanned and this "overlay"
# does not install many dependencies that could be checked automatically
# anyways. Fingers crossed...
echo "::set-output name=trivy_skip::skip"
echo "::set-output name=dockle_skip::skip"
