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

# Setup device info from data-only docker image.
setupDevinfoCycloneIV () {
    if docker ps -a --format '{{.Names}}' | grep -q '^quartus-devinfo$'; then
        docker rm quartus-devinfo
    fi
    docker create --name quartus-devinfo \
        -v /opt/quartus_lite/quartus/common/devinfo/cycloneive \
        -v /opt/quartus_lite/quartus/common/devinfo/cycloneivgx \
        ghcr.io/nikleberg/quartus:$1-staging
}

# Build a test design for the Cyclone IV device family.
testQuartusCycloneIV () {
    local version="${1%%-*}" # "25.1" part of "25.1-cycloneiv"
    docker run --rm \
        --volumes-from quartus-devinfo \
        -v "./test/design.tar.bz2:/tmp/design.tar.bz2:ro" \
        --entrypoint bash \
        ghcr.io/nikleberg/quartus:${version}-staging -c "\
            set -e; \
            export DEBIAN_FRONTEND=noninteractive; \
            apt-get -q -y update; \
            apt-get -q -y install --no-install-recommends bzip2; \
            cd /tmp; \
            tar -xjf design.tar.bz2; \
            ls -la; \
            cd geni/quartus; \
            quartus_sh -t ../scripts/quartus_project.tcl; \
            quartus_sh -t ../scripts/quartus_compile.tcl"
}

# Setup device info from data-only docker image.
setupDevinfoCycloneV () {
    if docker ps -a --format '{{.Names}}' | grep -q '^quartus-devinfo$'; then
        docker rm quartus-devinfo
    fi
    docker create --name quartus-devinfo \
        -v /opt/quartus_lite/quartus/common/devinfo/cyclonev \
        ghcr.io/nikleberg/quartus:$1-staging
}

# Build a test design for the Cyclone V device family.
# TODO: synthesize an actual design.
testQuartusCycloneV () {
    local version="${1%%-*}" # "25.1" part of "25.1-cyclonev"
    docker run --rm \
        --volumes-from quartus-devinfo \
        --entrypoint bash \
        ghcr.io/nikleberg/quartus:${version}-staging -c "\
            set -e; \
            if [ ! -d '/opt/quartus_lite/quartus/common/devinfo/cyclonev' ]; then \
                echo 'Error: Devinfo of Cyclone V not found!' >&2; \
                exit 1; \
            fi"
}

# Run the quartus GUI and verify that it started.
testQuartusGUI () {
    local version="${1%%-*}"
    # optionally mount device info files
    local devinfo_volumes=""
    if docker inspect quartus-devinfo >/dev/null 2>&1; then
        devinfo_volumes="--volumes-from quartus-devinfo"
    fi
    docker run --rm \
        $devinfo_volumes \
        -v "$(pwd)/test:/test" -w /test \
        --entrypoint bash \
        ghcr.io/nikleberg/quartus:${version}-staging -c "\
            set -e; \
            export DEBIAN_FRONTEND=noninteractive; \
            apt-get -q -y update; \
            apt-get -q -y install --no-install-recommends xvfb x11-apps imagemagick; \
            echo \$(ls -1q /root/.altera.quartus/.?* | head -n 1); \
            cp \$(ls -1q /root/.altera.quartus/.?* | head -n 1) shizzolator; \
            Xvfb :0 & \
            DISPLAY=:0 quartus & \
            sleep 10; \
            xwd -display :0 -silent -root -out capture.xwd; \
            convert capture.xwd capture.png; \
            tar cvf artifact.tar shizzolator capture.png; \
            compare capture.png expected$1.png diff.png"
}

# Choose test depending on the given tag of the container/image.
case $1 in
    18.1)
        testQuartusBase "18.1" "18.1.0 Build 625 09/12/2018 SJ"
        testQuartusGUI  "18.1";;
    22.1)
        testQuartusBase "22.1" "22.1std.2 Build 922 07/20/2023 SC"
        testQuartusGUI  "22.1";;
    23.1)
        testQuartusBase "23.1" "23.1std.1 Build 993 05/14/2024 SC"
        testQuartusGUI  "23.1";;
    24.1)
        testQuartusBase "24.1" "24.1std.0 Build 1077 03/04/2025 SC"
        testQuartusGUI  "24.1";;
    25.1)
        testQuartusBase "25.1" "25.1std.0 Build 1129 10/21/2025 SC"
        testQuartusGUI  "25.1";;
    18.1-cycloneiv | 22.1-cycloneiv | 23.1-cycloneiv | 24.1-cycloneiv | 25.1-cycloneiv)
        setupDevinfoCycloneIV $1
        testQuartusCycloneIV  $1
        testQuartusGUI        $1;;
    18.1-cyclonev | 22.1-cyclonev | 23.1-cyclonev | 24.1-cyclonev | 25.1-cyclonev)
        setupDevinfoCycloneV $1
        testQuartusCycloneV  $1
        testQuartusGUI       $1;;
    *)
        echo "Unknown image tag to test against. Aborting."
        exit 1;;
esac
