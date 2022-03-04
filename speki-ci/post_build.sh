#!/bin/sh

docker buildx build --platform linux/arm/v7 -f tests.dockerfile .
