#!/bin/bash
set -xe

helm repo add stable http://storage.googleapis.com/kubernetes-charts

helm install ~/.akachain/helm-charts/stable/openvpn \
    --name openvpn