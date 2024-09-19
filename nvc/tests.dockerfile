# Pull in the just built image and simulate an example design.
ARG IMAGE_TAG
FROM ghcr.io/nikleberg/nvc:${IMAGE_TAG}-staging

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
    nvc -a test.vhd
    nvc -e ent -r
EOF
