#!/bin/sh

# Skip Trivy and Dockle scan steps.
echo "trivy_skip=skip" >> $GITHUB_OUTPUT
echo "dockle_skip=skip" >> $GITHUB_OUTPUT
