#!/bin/sh

# Fail on nonzero return
set -e

# Check the ModelSim Executable is available.
testModelsimExe18_1 () {
    cmd="docker run ghcr.io/nikleberg/questasim:18.1-staging"
    echo "Running command '$cmd'."
    $cmd | tee out.log

    if ! test $(grep -c "Model Technology ModelSim ALTERA STARTER EDITION vsim 10.5b Simulator 2016.10 Oct  5 2016" out.log) -eq 1; then
        echo "Incorrect version of ModelSim did start."
        exit 1
    fi
}

# Check the Questa Executable is available.
testQuestaExe22_1 () {
    cmd="docker run ghcr.io/nikleberg/questasim:22.1-staging"
    echo "Running command '$cmd'."
    $cmd | tee out.log

    if ! test $(grep -c "Questa  Intel Starter FPGA Edition-64 vsim 2021.2 Simulator 2021.04 Apr 14 2021" out.log) -eq 1; then
        echo "Incorrect version of Questa did start."
        exit 1
    fi
}

# Check the Questa Executable is available.
testQuestaExe23_1 () {
    cmd="docker run ghcr.io/nikleberg/questasim:23.1-staging"
    echo "Running command '$cmd'."
    $cmd | tee out.log

    if ! test $(grep -c "Questa Intel Starter FPGA Edition-64 vsim 2023.3 Simulator 2023.07 Jul 17 2023" out.log) -eq 1; then
        echo "Incorrect version of Questa did start."
        exit 1
    fi
}

# Simulate a test design.
# We need to set the container MAC address while building the tests.dockerfile.
# For this we start a dummy alpine container with the needed MAC address and
# then build the test container with the network of that dummy container
# attached to it. We have to disable buildkit though as it does not support the
# network build option. Source: https://stackoverflow.com/a/48676884/16034014
testQuestaDesign () {
    export DOCKER_BUILDKIT=0
    docker run --name=mac00ababababab --mac-address=00:ab:ab:ab:ab:ab -d alpine tail -f /dev/null
    docker build --build-arg IMAGE_TAG=$1 --network=container:mac00ababababab -f tests.dockerfile .
    docker rm --force mac00ababababab
}

# Choose test depending on the given tag of the container/image.
case $1 in
    18.1)
        testModelsimExe18_1
        testQuestaDesign $1;;
    22.1)
        testQuestaExe22_1
        testQuestaDesign $1;;
    23.1)
        testQuestaExe23_1
        testQuestaDesign $1;;
    *)
        echo "Unknown image tag to test against. Aborting."
        exit 1;;
esac
