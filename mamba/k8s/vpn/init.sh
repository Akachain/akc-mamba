#!/bin/bash
set -xe

helm repo add stable http://storage.googleapis.com/kubernetes-charts

helm install stable/openvpn \
    --name openvpn