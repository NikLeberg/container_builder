# Pull in the just built image and simulate an example design.
ARG IMAGE_TAG=latest
FROM ghcr.io/nikleberg/ghdl:${IMAGE_TAG}-staging

COPY <<EOF test.vhd
entity ent is
end entity;

architecture arch of ent is
begin
    assert false report "Test OK" severity note;
end architecture;
EOF

RUN <<EOF
    set -e
    ghdl -a test.vhd
    ghdl --elab-run ent
EOF
