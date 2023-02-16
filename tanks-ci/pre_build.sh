#!/bin/sh

# Suppress Dockle error that is caused by baseimage ubuntu:jammy that uses ADD
# instead of COPY.
echo "DOCKLE_IGNORES=CIS-DI-0009" >> $GITHUB_ENV
