#!/bin/sh

# Suppress Dockle error that is caused by baseimage using ADD instead of COPY.
echo "DOCKLE_IGNORES=CIS-DI-0009" >> $GITHUB_ENV
