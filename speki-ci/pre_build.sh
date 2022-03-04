#!/bin/sh

# Enable buildx and create a builder for the ARMv7 platform
docker buildx install
docker buildx create --platform linux/arm/v7 --use
