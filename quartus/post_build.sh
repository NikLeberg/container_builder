#!/bin/sh

# Fail on nonzero return
set -e

# Build / run the test dockerfile.
docker build -f tests.dockerfile .
