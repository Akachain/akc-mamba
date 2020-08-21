#!/bin/bash
set -xe
helm upgrade efs stable/efs-provisioner \
    --set efsProvisioner.efsFileSystemId=$1 \
    --set efsProvisioner.awsRegion=$2 \
    --set efsProvisioner.path=/pvs \
    --set efsProvisioner.provisionerName=akachain.io/efs --recreate-pods
