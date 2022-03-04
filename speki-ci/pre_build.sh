#!/bin/sh

# Enable buildx and create a builder for the ARMv8 platform
docker buildx install
docker buildx create --platform linux/arm/v8 --use
