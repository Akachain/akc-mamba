#!/bin/bash
set -xe
helm upgrade metrics-server stable/metrics-server \
    --recreate-pods

