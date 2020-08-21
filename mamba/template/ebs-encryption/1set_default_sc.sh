#!/bin/bash
set -xe
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass gp2-encryption -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
