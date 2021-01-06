#!/bin/bash
set -xe
helm upgrade efs ~/.akachain/helm-charts/stable/efs-provisioner \
    --set efsProvisioner.efsFileSystemId=$1 \
    --set efsProvisioner.awsRegion=$2 \
    --set efsProvisioner.path=/pvs \
    --set efsProvisioner.storageClass.name=efs \
    --set efsProvisioner.provisionerName=akachain.io/efs --recreate-pods
