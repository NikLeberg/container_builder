#!/bin/sh

# Fail on nonzero return
set -e

# Clean up files from pre_build.sh.
rm *.tar

# Build / run the test dockerfile.
docker build -f tests.dockerfile .
