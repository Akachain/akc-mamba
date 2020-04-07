#!/bin/bash
set -xe
helm install stable/metrics-server \
    --name metrics-server \
    --namespace metrics

