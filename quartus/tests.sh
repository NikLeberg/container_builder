#!/bin/sh

# Fail on nonzero return
set -e

# Check the basic Quartus Shell is available.
testQuartusBase18_1 () {
    cmd="docker run ghcr.io/nikleberg/quartus:18.1-staging"
    echo "Running command '$cmd'."
    $cmd | tee out.log

    if ! test $(grep -c "Quartus Prime Shell" out.log) -eq 1; then
        echo "No Quartus Prime Shell did start."
        exit 1
    fi
    if ! test $(grep -c "Version 18.1.0 Build 625 09/12/2018 SJ Lite Edition" out.log) -eq 1; then
        echo "Incorrect version of Quartus Prime Shell did start."
        exit 1
    fi
}

# Check the basic Quartus Shell is available.
testQuartusBase22_1 () {
    cmd="docker run ghcr.io/nikleberg/quartus:22.1-staging"
    echo "Running command '$cmd'."
    $cmd | tee out.log

    if ! test $(grep -c "Quartus Prime Shell" out.log) -eq 1; then
        echo "No Quartus Prime Shell did start."
        exit 1
    fi
    if ! test $(grep -c "Version 22.1std.2 Build 922 07/20/2023 SC Lite Edition" out.log) -eq 1; then
        echo "Incorrect version of Quartus Prime Shell did start."
        exit 1
    fi
}

# Check the basic Quartus Shell is available.
testQuartusBase23_1 () {
    cmd="docker run ghcr.io/nikleberg/quartus:23.1-staging"
    echo "Running command '$cmd'."
    $cmd | tee out.log

    if ! test $(grep -c "Quartus Prime Shell" out.log) -eq 1; then
        echo "No Quartus Prime Shell did start."
        exit 1
    fi
    if ! test $(grep -c "Version 23.1std.1 Build 993 05/14/2024 SC Lite Edition" out.log) -eq 1; then
        echo "Incorrect version of Quartus Prime Shell did start."
        exit 1
    fi
}

# Build a test design for the Cyclone IV device family.
testQuartusCyclone () {
    docker build -f - . <<EOF
FROM ghcr.io/nikleberg/quartus:$1-staging
ADD test_design.tar.bz2 /tmp/test_design
RUN cd /tmp/test_design/geni/quartus \
    && quartus_sh -t ../scripts/quartus_project.tcl \
    && quartus_sh -t ../scripts/quartus_compile.tcl
EOF
}

# Choose test depending on the given tag of the container/image.
case $1 in
    18.1)
        testQuartusBase18_1;;
    22.1)
        testQuartusBase22_1;;
    23.1)
        testQuartusBase23_1;;
    18.1-cycloneiv | 22.1-cycloneiv | 23.1-cycloneiv)
        testQuartusCyclone $1;;
    *)
        echo "Unknown image tag to test against. Aborting."
        exit 1;;
esac
