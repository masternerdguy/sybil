#!/bin/bash

# build and tag core herdmate image
docker build -t localhost/herdmate --file herdmate/Dockerfile.herdmate
