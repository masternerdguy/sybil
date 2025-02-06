#!/bin/bash

# create .ollama directory
mkdir -v .ollama

# build and tag core herdmate image
podman build -t localhost/herdmate --file herdmate/Dockerfile.herdmate

# compose up
podman-compose up
