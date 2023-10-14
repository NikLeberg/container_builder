# Pull in the (probably) just built image and build an example design.
FROM ghcr.io/nikleberg/questasim:staging

ADD test_design.tar.bz2 /tmp/test_design
RUN cd /tmp/test_design/geni/modelsim \
    && vsim -c -do ./../scripts/modelsim_compile.tcl \
    && vsim -c -do ./../scripts/modelsim_test.tcl \
