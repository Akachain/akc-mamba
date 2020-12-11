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
    getDomain $ORG
    log "Enrolling with $CA_NAME as bootstrap identity ...${DOMAIN}..."
    export FABRIC_CA_CLIENT_HOME=/$DATA/crypto-config/$ORG.$DOMAIN
    mkdir -p $FABRIC_CA_CLIENT_HOME
    export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
    fabric-ca-client enroll -u https://$CA_ADMIN_USER_PASS@$CA_HOST:7054

    echo "NodeOUs:
    Enable: true
    ClientOUIdentifier:
      Certificate: intermediatecerts/ica-${ORG}-${DOMAIN}-7054.pem
      OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
      Certificate: intermediatecerts/ica-${ORG}-${DOMAIN}-7054.pem
      OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
      Certificate: intermediatecerts/ica-${ORG}-${DOMAIN}-7054.pem
      OrganizationalUnitIdentifier: admin
    OrdererOUIdentifier:
      Certificate: intermediatecerts/ica-${ORG}-${DOMAIN}-7054.pem
      OrganizationalUnitIdentifier: orderer" > ${FABRIC_CA_CLIENT_HOME}/msp/config.yaml
}

# Register the admin and user identities associated with the org
function registerOrgIdentities {
    initOrgVars $ORG
    enrollCAAdmin
    log "Registering admin identity: $ADMIN_NAME with $CA_NAME"
    # The admin identity has the "admin" attribute which is added to ECert by default
    # fabric-ca-client register -d --id.name $ADMIN_NAME --id.secret $ADMIN_PASS --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"
    fabric-ca-client register --id.name $ADMIN_NAME --id.secret $ADMIN_PASS --id.type admin --id.affiliation ""
    log "Registering user identity: $USER_NAME with $CA_NAME"
    fabric-ca-client register --id.name $USER_NAME --id.secret $USER_PASS --id.type client --id.affiliation ""
}

function getCACerts {
    initOrgVars $ORG
    # log "Getting CA certs for organization $ORG and storing in $ORG_MSP_DIR"
    # export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
    # fabric-ca-client getcacert -d -u https://$CA_HOST:7054 -M $ORG_MSP_DIR
    finishMSPSetup $FABRIC_CA_CLIENT_HOME/msp
    # If ADMINCERTS is true, we need to enroll the admin now to populate the admincerts directory
    if [ $ADMINCERTS ]; then
        # switchToAdminIdentity
        echo
        echo "## Generate the org admin msp"
        echo
        set -x
        mkdir -p ${FABRIC_CA_CLIENT_HOME}/users/admin/msp
        fabric-ca-client enroll -u https://$ADMIN_NAME:$ADMIN_PASS@$CA_HOST:7054 -M ${FABRIC_CA_CLIENT_HOME}/users/admin/msp
        cp ${FABRIC_CA_CLIENT_HOME}/msp/config.yaml ${FABRIC_CA_CLIENT_HOME}/users/admin/msp/config.yaml
        set +x
    fi

    mkdir -p ${FABRIC_CA_CLIENT_HOME}/users/${USER_NAME}
    echo
    echo "## Generate the user msp"
    echo
    set -x
    fabric-ca-client enroll -u https://${USER_NAME}:$USER_PASS@$CA_HOST:7054 -M ${FABRIC_CA_CLIENT_HOME}/users/${USER_NAME}/msp
    set +x
}

set +e

SDIR=$(dirname "$0")
source $SDIR/env.sh

main
