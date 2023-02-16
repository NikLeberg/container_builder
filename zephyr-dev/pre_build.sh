#!/bin/sh

# Skip Trivy scan step, image needs too much disk space.
echo "trivy_skip=skip" >> $GITHUB_OUTPUT

# Suppress Dockle error that is caused by following suspicious files:
# - usr/local/lib/python3.10/dist-packages/isort/settings.py
# - usr/local/lib/python3.10/dist-packages/dill/settings.py
# additionally suppress Dockle error that is caused by baseimage ubuntu:jammy
# that uses ADD instead of COPY.
echo "DOCKLE_IGNORES=CIS-DI-0010,CIS-DI-0009" >> $GITHUB_ENV
