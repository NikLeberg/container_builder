# Pull in the (probably) just built image and build the hello_world example.
FROM ghcr.io/nikleberg/zephyr-dev:staging

RUN cd /opt/zephyrproject/zephyr \
    && west build -p auto -b native_posix samples/hello_world \
    && timeout 5 west build -t run | tee output.log \
    && if ! test $(grep -c "Hello World!" output.log) -eq 1; then \
            echo "FAIL: Could not boot zephyr on native."; \
            exit 1; \
        fi
