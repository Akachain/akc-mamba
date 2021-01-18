#!/bin/bash
set -xe
helm upgrade metrics-server ~/.akachain/helm-charts/stable/metrics-server \
    --recreate-pods

