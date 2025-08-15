#!/bin/sh
# SPDX-License-Identifier: MIT
set -e

OPENOCD=/opt/openocd/openocd
WAIT_CFG=/wait.cfg

# Use a simple OpenOCD config to detect if remote is available.
# Wait until it is.
until $OPENOCD -f $WAIT_CFG; do
    echo "============================================================="
    echo "= Connection to DPI port failed. Retrying in 2 seconds ...  ="
    echo "============================================================="
    sleep 2
done

# Run the actual OpenOCD configuration.
exec $OPENOCD "$@"
