#!/bin/bash
set -xe
helm install ~/.akachain/helm-charts/stable/metrics-server \
    --name metrics-server \
    --namespace metrics

