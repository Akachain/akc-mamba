#!/bin/bash
# Copyright 2018-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

source $(dirname "$0")/env.sh
# Initialize the root CA
fabric-ca-server init -b "$BOOTSTRAP_USER_PASS" --csr.hosts "$EXTERNAL_RCA_ADDRESSES" --csr.hosts "$RCA_NAME.$RCA_DOMAIN"

# Copy the root CA's signing certificate to the data directory to be used by others
cp $FABRIC_CA_SERVER_HOME/ca-cert.pem $TARGET_CERTFILE

# Add the custom orgs
for o in $FABRIC_ORGS; do
   aff=$aff"\n   $o: []"
done
aff="${aff#\\n   }"
sed -i "/affiliations:/a \\   $aff" \
   $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml

# sed -i 's+C: US+C: VN+g' $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml
# sed -i "s+ST: \"North Carolina\"+ST: \"Hanoi\"+g" $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml
# sed -i 's/O: Hyperledger/O: Akachain/g' $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml
# sed -i 's/OU: Fabric/OU:/' $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml

# Start the root CA
fabric-ca-server start --csr.hosts "$EXTERNAL_RCA_ADDRESSES" --csr.hosts "$RCA_NAME.$RCA_DOMAIN"
