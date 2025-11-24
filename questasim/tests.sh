#!/bin/sh

# Fail on nonzero return
set -e

# Check the Questa Executable is available.
testQuestaExe () {
    cmd="docker run ghcr.io/nikleberg/questasim:$1-staging"
    echo "Running command '$cmd'."
    $cmd | tee out.log

    if ! test $(grep -c "$2" out.log) -eq 1; then
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
    docker build --network=container:mac00ababababab -f - . <<EOF
FROM ghcr.io/nikleberg/questasim:$1-staging
ADD test/design.tar.bz2 /tmp/test_design
RUN cd /tmp/test_design/geni/modelsim \
    && vsim -c -do ./../scripts/modelsim_compile.tcl \
    && vsim -c -do ./../scripts/modelsim_test.tcl
EOF
    docker rm --force mac00ababababab
}

# Run the Vsim GUI and verify that it started.
testQuestaGUI () {
    docker run --rm -v "$(pwd)/test:/test" -w /test \
        --mac-address=00:ab:ab:ab:ab:ab \
        --entrypoint bash ghcr.io/nikleberg/questasim:$1-staging -c "\
            set -e; \
            export DEBIAN_FRONTEND=noninteractive; \
            apt-get -q -y update; \
            apt-get -q -y install --no-install-recommends xvfb x11-apps imagemagick; \
            Xvfb :0 & \
            DISPLAY=:0 vsim -gui & \
            sleep 10; \
            xwd -display :0 -silent -root -out capture.xwd; \
            convert capture.xwd capture.png; \
            compare capture.png expected$1.png diff.png"
}

# Choose test depending on the given tag of the container/image.
case $1 in
    22.1)
        testQuestaExe "22.1" "Questa  Intel Starter FPGA Edition-64 vsim 2021.2 Simulator 2021.04 Apr 14 2021"
        testQuestaDesign $1
        testQuestaGUI $1;;
    23.1)
        testQuestaExe "23.1" "Questa Intel Starter FPGA Edition-64 vsim 2023.3 Simulator 2023.07 Jul 17 2023"
        testQuestaDesign $1
        testQuestaGUI $1;;
    24.1)
        testQuestaExe "24.1" "Questa Intel Starter FPGA Edition-64 vsim 2024.3 Simulator 2024.09 Sep 10 2024"
        testQuestaDesign $1
        testQuestaGUI $1;;
    25.1)
        testQuestaExe "25.1" "Questa Altera Starter FPGA Edition-64 vsim 2025.2 Simulator 2025.05 May 31 2025"
        testQuestaDesign $1
        testQuestaGUI $1;;
    *)
        echo "Unknown image tag to test against. Aborting."
        exit 1;;
esac
