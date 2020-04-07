#!/bin/bash
set -e

source $(dirname "$0")/env.sh
log "Enrolling peer for org $PEERORG ..."
initPeerVars $PEERORG
ENROLLMENT_URL="https://$PEER_NAME_PASS@$CA_HOST:7054"

log "Preparing to enroll peer '$CORE_PEER_ID', host '$PEER_HOST', enrolled via '$ENROLLMENT_URL' with MSP at '$CORE_PEER_MSPCONFIGPATH'"

# Although a peer may use the same TLS key and certificate file for both inbound and outbound TLS,
# we generate a different key and certificate for inbound and outbound TLS simply to show that it is permissible

# Generate server TLS cert and key pair for the peer
if [ "$EXTERNAL_PEER_HOST" != ""]; then
    fabric-ca-client enroll -d --enrollment.profile tls -u $ENROLLMENT_URL -M /tmp/tls --csr.hosts $PEER_HOST --csr.hosts $EXTERNAL_PEER_HOST
else
    fabric-ca-client enroll -d --enrollment.profile tls -u $ENROLLMENT_URL -M /tmp/tls --csr.hosts $PEER_HOST
fi

log "Copy the TLS key and cert to the appropriate place"
TLSDIR=$PEER_HOME/tls
mkdir -p $TLSDIR
cp /tmp/tls/signcerts/* $CORE_PEER_TLS_CERT_FILE
cp /tmp/tls/keystore/* $CORE_PEER_TLS_KEY_FILE
rm -rf /tmp/tls

log "Generate client TLS cert and key pair for the peer"
genClientTLSCert $PEER_HOST $CORE_PEER_TLS_CLIENTCERT_FILE $CORE_PEER_TLS_CLIENTKEY_FILE

log "Generate client TLS cert and key pair for the peer CLI"
genClientTLSCert $PEER_HOST /$DATA/tls/$PEER_NAME-cli-client.crt /$DATA/tls/$PEER_NAME-cli-client.key

# Enroll the peer to get an enrollment certificate and set up the core's local MSP directory
fabric-ca-client enroll -d -u $ENROLLMENT_URL -M $CORE_PEER_MSPCONFIGPATH
sleep 10
finishMSPSetup $CORE_PEER_MSPCONFIGPATH
copyAdminCert $CORE_PEER_MSPCONFIGPATH

# copy tls & msp crt
mkdir -p /data/orgs/$CORE_PEER_ID/msp/keystore
mkdir -p /data/orgs/$CORE_PEER_ID/msp/signcerts
mkdir -p /data/orgs/$CORE_PEER_ID/tls
cp $CORE_PEER_MSPCONFIGPATH/keystore/* /data/orgs/$CORE_PEER_ID/msp/keystore/key.pem
cp $CORE_PEER_MSPCONFIGPATH/signcerts/cert.pem /data/orgs/$CORE_PEER_ID/msp/keystore/cert.pem
cp $CORE_PEER_TLS_CERT_FILE /data/orgs/$CORE_PEER_ID/tls/
cp $CORE_PEER_TLS_KEY_FILE /data/orgs/$CORE_PEER_ID/tls/

log "Finished registering peer for org $PEERORG"