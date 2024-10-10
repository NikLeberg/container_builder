#!/bin/sh

docker build --build-arg IMAGE_TAG=$1 -f test.dockerfile .
