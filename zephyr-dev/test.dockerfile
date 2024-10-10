# Pull in the just built image and build the hello_world example.
ARG IMAGE_TAG
FROM ghcr.io/nikleberg/zephyr-dev:${IMAGE_TAG}-staging

RUN <<EOF
    set -e
    cd /opt/zephyrproject/zephyr
    west build -p auto -b native_posix samples/hello_world
    timeout 5 west build -t run | tee output.log
    if ! test $(grep -c "Hello World!" output.log) -eq 1; then \
        echo "FAIL: Could not boot zephyr on native."; \
        exit 1; \
    fi
EOF
