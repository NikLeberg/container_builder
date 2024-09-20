#!/bin/sh

# Fail on nonzero return
set -e

# Check the NVC executable is available.
testExe () {
    cmd="docker run ghcr.io/nikleberg/nvc:$1-staging"
    echo "Running command '$cmd'."
    $cmd | tee out.log

    if ! test $(grep -c "nvc $1" out.log) -eq 1; then
        echo "Incorrect version of NVC did start."
        exit 1
    fi
}

# Check the NVC executable in git master version is available.
testMasterExe () {
    cmd="docker run ghcr.io/nikleberg/nvc:master-staging"
    echo "Running command '$cmd'."
    $cmd | tee out.log

    if ! test $(grep -c "nvc .*-devel" out.log) -eq 1; then
        echo "Incorrect version of NVC did start."
        exit 1
    fi
}

# Simulate a test design.
testDesign () {
    cmd="docker build --build-arg IMAGE_TAG=$1 --progress plain -f tests.dockerfile ."
    echo "Running command '$cmd'."
    $cmd 2>&1 | tee out.log

    if ! test $(grep -c "Test OK" out.log) -eq 1; then
        echo "VHDL test design could not be analyzed/elaborated/run."
        exit 1
    fi
}

# Choose test depending on the given tag of the container/image.
case $1 in
    1.13.3)
        testExe $1
        testDesign $1;;
    master)
        testMasterExe
        testDesign $1;;
    *)
        echo "Unknown image tag to test against. Aborting."
        exit 1;;
esac
