#!/bin/sh

# Fail on nonzero return
set -e

# Check the basic diamondc Tcl shell is available.
testDiamondcVersion() {
    local output
    if ! output=$(
        echo 'puts [sys_install version]' |
            docker run --rm -i --mac-address=00:ab:ab:ab:ab:ab \
                "ghcr.io/nikleberg/diamond:$1-staging"
    ); then
        echo "Failed to run diamondc."
        exit 1
    fi
    printf '%s\n' "$output"

    if [ "$(echo $output | grep -c $2)" -ne 1 ]; then
        echo "Incorrect version of diamondc did start."
        exit 1
    fi
}

# Run the Diamond GUI and verify that it started.
testDiamondGUI () {
    docker run --rm \
        --mac-address=00:ab:ab:ab:ab:ab \
        -v "$(pwd)/test:/test" -w /test \
        --entrypoint bash \
        ghcr.io/nikleberg/diamond:$1-staging -c "\
            set -xe; \
            export DEBIAN_FRONTEND=noninteractive; \
            apt-get -q -y update; \
            apt-get -q -y install --no-install-recommends xvfb x11-apps imagemagick; \
            Xvfb :0 & \
            DISPLAY=:0 diamond & \
            sleep 10; \
            xwd -display :0 -silent -root -out capture.xwd; \
            convert capture.xwd capture.png; \
            RMSE=\$(compare -metric RMSE capture.png expected$1.png null: 2>&1 | sed -E 's/^.*\((.+)\).*$/\1/g'); \
            echo RMSE=\$RMSE; \
            awk -v r=\$RMSE 'BEGIN { exit !(r <= 0.005) }'; \
        "
}

# Choose test depending on the given tag of the image.
case $1 in
    3.14-ecp5)
        testDiamondcVersion "3.14-ecp5" "3.14.0.75.2"
        testDiamondGUI      "3.14-ecp5";;
    *)
        echo "Unknown image tag to test against. Aborting."
        exit 1;;
esac
