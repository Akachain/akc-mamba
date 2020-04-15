#!/bin/bash

#
# This script does the following:
# 1) registers an organisation with fabric-ca, and generates the CA certs
#

function main {
   log "Registering organisation $ORG ..."
   registerOrgIdentities
   getCACerts
   log "Finished registering organisation $ORG"
}

# Enroll the CA administrator
function enrollCAAdmin {
   initOrgVars $ORG
   log "Enrolling with $CA_NAME as bootstrap identity ...${DOMAIN}..."
   export FABRIC_CA_CLIENT_HOME=$HOME/cas/$CA_NAME
   export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
   fabric-ca-client enroll -d -u https://$CA_ADMIN_USER_PASS@$CA_HOST:7054
}

# Register the admin and user identities associated with the org
function registerOrgIdentities {
    initOrgVars $ORG
    enrollCAAdmin
    log "Registering admin identity: $ADMIN_NAME with $CA_NAME"
    # The admin identity has the "admin" attribute which is added to ECert by default
    fabric-ca-client register -d --id.name $ADMIN_NAME --id.secret $ADMIN_PASS --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"
    log "Registering user identity: $USER_NAME with $CA_NAME"
    fabric-ca-client register -d --id.name $USER_NAME --id.secret $USER_PASS
}

function getCACerts {
    initOrgVars $ORG
    log "Getting CA certs for organization $ORG and storing in $ORG_MSP_DIR"
    export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
    fabric-ca-client getcacert -d -u https://$CA_HOST:7054 -M $ORG_MSP_DIR
    finishMSPSetup $ORG_MSP_DIR
    # If ADMINCERTS is true, we need to enroll the admin now to populate the admincerts directory
    if [ $ADMINCERTS ]; then
        switchToAdminIdentity
    fi
}

set +e

SDIR=$(dirname "$0")
source $SDIR/env.sh

main
