# Pull in the just built image and simulate an example design.
ARG IMAGE_TAG
FROM ghcr.io/nikleberg/questasim:${IMAGE_TAG}-staging

ADD test_design.tar.bz2 /tmp/test_design
RUN cd /tmp/test_design/geni/modelsim \
    && vsim -c -do ./../scripts/modelsim_compile.tcl \
    && vsim -c -do ./../scripts/modelsim_test.tcl \
