#!/bin/bash

source $(dirname "$0")/env.sh
initOrgVars $ORG

set -e

# Initialize the intermediate CA
fabric-ca-server init -b $BOOTSTRAP_USER_PASS -u $PARENT_URL

# Copy the intermediate CA's certificate chain to the data directory to be used by others
cp $FABRIC_CA_SERVER_HOME/ca-chain.pem $TARGET_CHAINFILE

# Add the custom orgs
# for o in $ORGS; do
aff=$aff"\n   $ORG.akc: []"
# done
aff="${aff#\\n   }"
sed -i "/affiliations:/a \\   $aff" \
   $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml

sed -i 's+C: US+C: VN+g' $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml
sed -i "s+ST: \"North Carolina\"+ST: \"Hanoi\"+g" $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml
sed -i "s/O: Hyperledger/O: $ORG/g" $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml
sed -i 's/OU: Fabric/OU:/' $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml

# Start the intermediate CA
fabric-ca-server start
