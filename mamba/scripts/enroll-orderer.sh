#!/bin/bash

set -e

# Setup orderer enrollment environment variables
source $(dirname "$0")/env.sh

COUNT=$(($1+1))

log "Enrolling orderer $COUNT for $ORDERERORG ..."
initOrdererVars $ORDERERORG $COUNT
ENROLLMENT_URL="https://$ORDERER_NAME_PASS@$CA_HOST:7054"

export FABRIC_CA_CLIENT_HOME=/$DATA/crypto-config/$ORDERERORG.$DOMAIN
mkdir -p $FABRIC_CA_CLIENT_HOME
export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE

export TLS_CONFIG_PATH=$FABRIC_CA_CLIENT_HOME/orderers/$ORDERER_HOST/tls
export MSPCONFIGPATH=$FABRIC_CA_CLIENT_HOME/orderers/$ORDERER_HOST/msp

mkdir -p $TLS_CONFIG_PATH
mkdir -p $MSPCONFIGPATH

log "Preparing to enroll '$ORDERER_HOST:$ORDERER_PORT', enrolled via '$ENROLLMENT_URL' with MSP at '$ORDERER_GENERAL_LOCALMSPDIR'"

# Enroll to get orderer's TLS cert (using the "tls" profile)
if [ "$EXTERNAL_ORDERER_ADDRESSES" == "" ]; then
    fabric-ca-client enroll -d --enrollment.profile tls -u $ENROLLMENT_URL -M $TLS_CONFIG_PATH --csr.hosts $ORDERER_HOST
else
    log "Enroll with EXTERNAL_ORDERER_ADDRESSES=$EXTERNAL_ORDERER_ADDRESSES"
    fabric-ca-client enroll -d --enrollment.profile tls -u $ENROLLMENT_URL -M $TLS_CONFIG_PATH --csr.hosts $ORDERER_HOST --csr.hosts $EXTERNAL_ORDERER_ADDRESSES
fi

# # Copy the TLS key and cert to the appropriate place
# TLSDIR=$ORDERER_HOME/tls
# mkdir -p $TLSDIR
# cp /tmp/tls/keystore/* $ORDERER_GENERAL_TLS_PRIVATEKEY
# cp /tmp/tls/signcerts/* $ORDERER_GENERAL_TLS_CERTIFICATE
# rm -rf /tmp/tls

# Enroll again to get the orderer's enrollment certificate (default profile)
if [ "$EXTERNAL_ORDERER_ADDRESSES" != ""]; then
    fabric-ca-client enroll -d -u $ENROLLMENT_URL -M $MSPCONFIGPATH --csr.hosts $ORDERER_HOST --csr.hosts $EXTERNAL_ORDERER_ADDRESSES
else
    fabric-ca-client enroll -d -u $ENROLLMENT_URL -M $MSPCONFIGPATH --csr.hosts $ORDERER_HOST
fi
# fabric-ca-client enroll -d -u $ENROLLMENT_URL -M $ORDERER_GENERAL_LOCALMSPDIR

# Finish setting up the local MSP for the orderer
finishMSPSetup $MSPCONFIGPATH
cp ${FABRIC_CA_CLIENT_HOME}/msp/config.yaml ${MSPCONFIGPATH}/config.yaml
set -x
cp ${TLS_CONFIG_PATH}/tlscacerts/*  ${TLS_CONFIG_PATH}/ca.crt
cp ${TLS_CONFIG_PATH}/signcerts/*  ${TLS_CONFIG_PATH}/server.crt
cp ${TLS_CONFIG_PATH}/keystore/*  ${TLS_CONFIG_PATH}/server.key

mkdir -p ${MSPCONFIGPATH}/tlscacerts
cp ${TLS_CONFIG_PATH}/tlscacerts/* ${MSPCONFIGPATH}/tlscacerts/tlsca.$ORDERERORG.$DOMAIN-cert.pem

mkdir -p ${FABRIC_CA_CLIENT_HOME}/msp/tlscacerts
cp ${TLS_CONFIG_PATH}/tlscacerts/* ${FABRIC_CA_CLIENT_HOME}/msp/tlscacerts/tlsca.$ORDERERORG.$DOMAIN-cert.pem
set +x
# mkdir -p ${FABRIC_CA_CLIENT_HOME}/ca
# cp ${MSPCONFIGPATH}/cacerts/* ${FABRIC_CA_CLIENT_HOME}/ca/ca.$PEERORG.$DOMAIN-cert.pem
# copyAdminCert $ORDERER_GENERAL_LOCALMSPDIR

# copy tls & msp crt
# cp /etc/hyperledger/orderer/msp/keystore/* /data/orgs/orderer/msp/keystore/key.pem
# cp /etc/hyperledger/orderer/msp/signcerts/cert.pem /data/orgs/orderer/msp/signcerts/
# mkdir -p /data/orgs/orderer/tls
# cp $ORDERER_GENERAL_TLS_PRIVATEKEY /data/orgs/orderer/tls
# cp $ORDERER_GENERAL_TLS_CERTIFICATE /data/orgs/orderer/tls