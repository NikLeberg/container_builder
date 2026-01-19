#!/bin/sh

set -e
docker run --rm --entrypoint bash ghcr.io/nikleberg/load-test:test-v1-staging -c "\
    set -e; \
    cat load.txt"
