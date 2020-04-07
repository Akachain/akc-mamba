#!/bin/bash

set -e

# Setup orderer enrollment environment variables
source $(dirname "$0")/env.sh
initOrdererVars orderer 1
ENROLLMENT_URL="https://$ORDERER_NAME_PASS@$CA_HOST:7054"

log "Preparing to enroll '$ORDERER_HOST:$ORDERER_PORT', enrolled via '$ENROLLMENT_URL' with MSP at '$ORDERER_GENERAL_LOCALMSPDIR'"

# Enroll to get orderer's TLS cert (using the "tls" profile)
if [ "$EXTERNAL_ORDERER_ADDRESSES" == "" ]; then
    fabric-ca-client enroll -d --enrollment.profile tls -u $ENROLLMENT_URL -M /tmp/tls --csr.hosts $ORDERER_HOST
else
    log "Enroll with EXTERNAL_ORDERER_ADDRESSES=$EXTERNAL_ORDERER_ADDRESSES"
    fabric-ca-client enroll -d --enrollment.profile tls -u $ENROLLMENT_URL -M /tmp/tls --csr.hosts $ORDERER_HOST --csr.hosts $EXTERNAL_ORDERER_ADDRESSES
fi

# Copy the TLS key and cert to the appropriate place
TLSDIR=$ORDERER_HOME/tls
mkdir -p $TLSDIR
cp /tmp/tls/keystore/* $ORDERER_GENERAL_TLS_PRIVATEKEY
cp /tmp/tls/signcerts/* $ORDERER_GENERAL_TLS_CERTIFICATE
rm -rf /tmp/tls

# Enroll again to get the orderer's enrollment certificate (default profile)
fabric-ca-client enroll -d -u $ENROLLMENT_URL -M $ORDERER_GENERAL_LOCALMSPDIR

# Finish setting up the local MSP for the orderer
finishMSPSetup $ORDERER_GENERAL_LOCALMSPDIR
copyAdminCert $ORDERER_GENERAL_LOCALMSPDIR

# copy tls & msp crt
cp /etc/hyperledger/orderer/msp/keystore/* /data/orgs/orderer/msp/keystore/key.pem
cp /etc/hyperledger/orderer/msp/signcerts/cert.pem /data/orgs/orderer/msp/signcerts/
mkdir -p /data/orgs/orderer/tls
cp $ORDERER_GENERAL_TLS_PRIVATEKEY /data/orgs/orderer/tls
cp $ORDERER_GENERAL_TLS_CERTIFICATE /data/orgs/orderer/tls