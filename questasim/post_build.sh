#!/bin/sh

# Fail on nonzero return
set -e

# We need to set the container MAC address while building the tests.dockerfile.
# For this we start a dummy alpine container with the needed MAC address and
# then build the test container with the network of that dummy container
# attached to it. We have to disable buildkit though as it does not support the
# network build option. Source: https://stackoverflow.com/a/48676884/16034014
export DOCKER_BUILDKIT=0
docker run --name=mac00ababababab --mac-address=00:ab:ab:ab:ab:ab -d alpine tail -f /dev/null
docker build --network=container:mac00ababababab -f tests.dockerfile .
docker rm --force mac00ababababab
