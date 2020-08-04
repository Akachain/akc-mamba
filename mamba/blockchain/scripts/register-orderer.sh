#!/bin/bash

#
# This script does the following:
# 1) registers the orderer with fabric-ca
#

function main {
   export ORG=$ORDERERORG
   log "Registering orderer for org $ORG ..."
   registerOrdererIdentities
   log "Finished registering orderer for org $ORG"
}

# Enroll the CA administrator
function enrollCAAdmin {
   initOrgVars $ORG
   log "Enrolling with $CA_NAME as bootstrap identity ..."
   export FABRIC_CA_CLIENT_HOME=$HOME/cas/$CA_NAME
   export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
   fabric-ca-client enroll -d -u https://$CA_ADMIN_USER_PASS@$CA_HOST:7054
}

# Register any identities associated with the orderer
function registerOrdererIdentities {
    initOrgVars $ORG
    enrollCAAdmin
    local COUNT=1
    while [[ "$COUNT" -le $NUM_ORDERERS ]]; do
        initOrdererVars $ORG $COUNT
        log "Registering $ORDERER_NAME with $CA_NAME"
        fabric-ca-client register -d --id.name $ORDERER_NAME --id.secret $ORDERER_PASS --id.type orderer
        COUNT=$((COUNT+1))
    done
}

set +e

SDIR=$(dirname "$0")
source $SDIR/env.sh

main
