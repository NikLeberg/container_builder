#!/bin/sh

# Fail on nonzero return
set -e

# Check the basic Quartus Shell is available.
testQuartusBase () {
    cmd="docker run ghcr.io/nikleberg/quartus:$1-staging"
    echo "Running command '$cmd'."
    $cmd | tee out.log

    if ! test $(grep -c "Quartus Prime Shell" out.log) -eq 1; then
        echo "No Quartus Prime Shell did start."
        exit 1
    fi
    if ! test $(grep -c "Version $2 Lite Edition" out.log) -eq 1; then
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
        testQuartusBase "18.1" "18.1.0 Build 625 09/12/2018 SJ";;
    22.1)
        testQuartusBase "22.1" "22.1std.2 Build 922 07/20/2023 SC";;
    23.1)
        testQuartusBase "23.1" "23.1std.1 Build 993 05/14/2024 SC";;
    24.1)
        testQuartusBase "24.1" "24.1std.0 Build 1077 03/04/2025 SC";;
    25.1)
        testQuartusBase "25.1" "25.1std.0 Build 1129 10/21/2025 SC";;
    18.1-cycloneiv | 22.1-cycloneiv | 23.1-cycloneiv | 24.1-cycloneiv | 25.1-cycloneiv)
        testQuartusCyclone $1;;
    *)
        echo "Unknown image tag to test against. Aborting."
        exit 1;;
esac
