#!/bin/bash

# Setup cluster variables
# RUN_MODE=$(grep RUN_MODE $(dirname "$0")/configuration.sh | xargs)
# IFS='=' read -ra RUN_MODE <<< "$RUN_MODE"
# RUN_MODE=${RUN_MODE[1]}

# if [[ "$RUN_MODE" == "operator" ]]; then
#   source $(dirname "$0")/env-operator.sh
# elif [[ "$RUN_MODE" == "build" ]]; then
#   source $(dirname "$0")/env-build.sh
# elif [[ "$RUN_MODE" == "merchant" ]]; then
#   source $(dirname "$0")/env-merchant.sh
# fi

source $(dirname "$0")/env-scripts.sh

#####################################################################################
# The remainder of this file contains variables which typically would not be changed.
# The exception would be FABRIC_TAG, which you use to change to a different Fabric version.
#####################################################################################

# All org names
ORGS="$ORDERER_ORGS $PEER_ORGS"
DOMAINS="$ORDERER_DOMAINS $PEER_DOMAINS"

# Set to true to populate the "admincerts" folder of MSPs
ADMINCERTS=true

# The volume mount to share data between containers
DATA=data

# The path to the genesis block
GENESIS_BLOCK_FILE=/$DATA/genesis.block

# The path to a channel transaction
CHANNEL_TX_FILE=/$DATA/channel.tx

# Query timeout in seconds
QUERY_TIMEOUT=15

# Setup timeout in seconds (for setup container to complete)
SETUP_TIMEOUT=120

# Log directory
LOGDIR=$DATA/logs
LOGPATH=/$LOGDIR

# Affiliation is not used to limit users in this sample, so just put
# all identities in the same affiliation.
export FABRIC_CA_CLIENT_ID_AFFILIATION=org1

# Set to true to enable use of intermediate CAs
USE_INTERMEDIATE_CA=true

# Config block file path
CONFIG_BLOCK_FILE=/tmp/config_block.pb

# Update config block payload file path
CONFIG_UPDATE_ENVELOPE_FILE=/tmp/config_update_as_envelope.pb

# initOrgVars <ORG>
# This function runs when we create a new organization.
function initOrgVars {
   if [ $# -ne 1 ]; then
      echo "Usage: initOrgVars <ORG>"
      exit 1
   fi
   set -x
   ORG=$1
   getDomain $ORG
   ORG_CONTAINER_NAME=${ORG//./-}

   # Host name of the Root CA (don't change this)
   ROOT_CA_HOST="rca-akc.akachain"
   ROOT_CA_NAME="rca.akachain.io"
   ROOT_CA_LOGFILE=$LOGDIR/${ROOT_CA_NAME}.log

   # Intermediate CA
   INT_CA_HOST=ica-${ORG}.${DOMAIN}
   INT_CA_NAME=ica-${ORG}.${DOMAIN}
   INT_CA_LOGFILE=$LOGDIR/${INT_CA_NAME}.log

   # Intermediate CA admin identity
   INT_CA_ADMIN_USER=ica-${ORG}-admin
   INT_CA_ADMIN_PASS=${INT_CA_ADMIN_USER}pw
   INT_CA_ADMIN_USER_PASS=${INT_CA_ADMIN_USER}:${INT_CA_ADMIN_PASS}

   # Admin identity for the org
   ADMIN_NAME=admin-${ORG}
   ADMIN_PASS=${ADMIN_NAME}pw

   # Typical user identity for the org
   USER_NAME=user-${ORG}
   USER_PASS=${USER_NAME}pw

   # Cert files
   ROOT_CA_CERTFILE=/${DATA}/rca-${ORG}-ca-cert.pem
   INT_CA_CHAINFILE=/${DATA}/ica-${ORG}-ca-chain.pem
   ANCHOR_TX_FILE=/${DATA}/orgs/${ORG}/anchors.tx
   ORG_MSP_ID=${ORG}MSP
   ORG_MSP_DIR=/${DATA}/orgs/${ORG}/msp
   ORG_ADMIN_CERT=${ORG_MSP_DIR}/admincerts/cert.pem
   ORG_ADMIN_HOME=/${DATA}/orgs/$ORG/admin

   # Set intermediate CA configuration
   CA_NAME=$INT_CA_NAME
   CA_HOST=$INT_CA_HOST
   CA_CHAINFILE=$INT_CA_CHAINFILE
   CA_ADMIN_USER_PASS=$INT_CA_ADMIN_USER_PASS
   CA_LOGFILE=$INT_CA_LOGFILE
   set +x
}

# initOrdererVars <NUM>
function initOrdererVars {
   if [ $# -ne 2 ]; then
      echo "Usage: initOrdererVars <ORG> <NUM>"
      exit 1
   fi
   set -x
   ORG=$1
   NUM=$2
   if [ "$NUM" -eq "1" ]; then
      INDEX=0
   else
      INDEX=`expr $NUM - 1`
   fi
   
   initOrgVars $ORG
   getDomain $ORG

   # TODO: need to update this to add external addresses for Orderer
   ORDERER_HOST=orderer${INDEX}-${ORG}.${DOMAIN}
   ORDERER_PORT=7050

   ORDERER_NAME=orderer${INDEX}-${ORG}
   ORDERER_PASS=${ORDERER_NAME}pw
   ORDERER_NAME_PASS=${ORDERER_NAME}:${ORDERER_PASS}
   ORDERER_LOGFILE=$LOGDIR/${ORDERER_NAME}.log
   MYHOME=/etc/hyperledger/orderer

   export FABRIC_CA_CLIENT=$MYHOME
   export ORDERER_GENERAL_LOGLEVEL=debug
   export ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
   export ORDERER_GENERAL_GENESISMETHOD=file
   export ORDERER_GENERAL_GENESISFILE=$GENESIS_BLOCK_FILE
   export ORDERER_GENERAL_LOCALMSPID=$ORG_MSP_ID
   export ORDERER_GENERAL_LOCALMSPDIR=$MYHOME/msp

   # enabled TLS
   export ORDERER_GENERAL_TLS_ENABLED=true
   TLSDIR=$MYHOME/tls
   export ORDERER_GENERAL_TLS_PRIVATEKEY=$TLSDIR/server.key
   export ORDERER_GENERAL_TLS_CERTIFICATE=$TLSDIR/server.crt
   export ORDERER_GENERAL_TLS_ROOTCAS=[$CA_CHAINFILE]
   export ORDERER_GENERAL_TLS_CLIENTROOTCAS=[$CA_CHAINFILE]
   export ORDERER_GENERAL_TLS_CLIENTAUTHREQUIRED=false
   set +x
}


# Generate TLS cert for all clients.
function genClientTLSCert {
   if [ $# -ne 3 ]; then
      echo "Usage: genClientTLSCert <host name> <cert file> <key file>: $*"
      exit 1
   fi

   echo "Generating genClientTLSCert for host: <host name> <cert file> <key file>: $*"
   HOST_NAME=$1
   CERT_FILE=$2
   KEY_FILE=$3

   if ! [ -x "$(command -v fabric-ca-client)" ]; then
      echo 'fabric-ca-client is not installed - installing it now.'
      installFabricCA
   fi

   # Get a client cert
   fabric-ca-client enroll -d --enrollment.profile tls -u $ENROLLMENT_URL -M /tmp/tls --csr.hosts $HOST_NAME

   mkdir /$DATA/tls || true
   cp /tmp/tls/signcerts/* $CERT_FILE
   cp /tmp/tls/keystore/* $KEY_FILE
   rm -rf /tmp/tls
}

# initPeerVars <ORG> <NUM optional>
function initPeerVars {
   if [ $# -gt 2 ]; then
      echo "Usage: initPeerVars <ORG> <NUM optional>: $*"
      exit 1
   fi

   ORG=$1
   initOrgVars $ORG

   # PEER_NAME and PEER_HOST are set from yaml
   # Set peer variables. TODO: Deal with anchor peer external Host
   # PEER_NAME=${PEER_PREFIX}${NUM}-${ORG}
   # PEER_HOST=${PEER_NAME}.${DOMAIN}
   if [ $# -eq 2 ]; then
      NUM=$2
      initOrgVars $ORG
      getDomain $ORG
      PEER_NAME=${PEER_PREFIX}${NUM}-${ORG}
   fi

   PEER_PASS=${PEER_NAME}pw
   PEER_NAME_PASS=${PEER_NAME}:${PEER_PASS}
   PEER_LOGFILE=$LOGDIR/${PEER_NAME}.log
   MYHOME=/opt/gopath/src/github.com/hyperledger/fabric/peer
   TLSDIR=$MYHOME/tls

   export CORE_PEER_TLS_CLIENTCERT_FILE=/$DATA/tls/$PEER_NAME-cli-client.crt
   export CORE_PEER_TLS_CLIENTKEY_FILE=/$DATA/tls/$PEER_NAME-cli-client.key
}

# Switch to the current org's admin identity.  Enroll if not previously enrolled.
function switchToAdminIdentity {
   if [ ! -d $ORG_ADMIN_HOME ]; then
      dowait "$CA_NAME to start" 60 $CA_LOGFILE $CA_CHAINFILE
      log "Enrolling admin '$ADMIN_NAME' with $CA_HOST ..."
      export FABRIC_CA_CLIENT_HOME=$ORG_ADMIN_HOME
      export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
      if ! [ -x "$(command -v fabric-ca-client)" ]; then
         echo 'fabric-ca-client is not installed - installing it now.'
         installFabricCA
      fi
      fabric-ca-client enroll -d -u https://$ADMIN_NAME:$ADMIN_PASS@$CA_HOST:7054
      # If admincerts are required in the MSP, copy the cert there now and to my local MSP also
      if [ $ADMINCERTS ]; then
         mkdir -p $(dirname "${ORG_ADMIN_CERT}")
         cp $ORG_ADMIN_HOME/msp/signcerts/* $ORG_ADMIN_CERT
         mkdir $ORG_ADMIN_HOME/msp/admincerts
         cp $ORG_ADMIN_HOME/msp/signcerts/* $ORG_ADMIN_HOME/msp/admincerts
      fi
   fi
   export CORE_PEER_MSPCONFIGPATH=$ORG_ADMIN_HOME/msp
}

# Switch to the current org's user identity.  Enroll if not previously enrolled.
function switchToUserIdentity {
   log "Switching to user '$USER_NAME'"
   export FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric/orgs/$ORG/user
   export CORE_PEER_MSPCONFIGPATH=$FABRIC_CA_CLIENT_HOME/msp
   if [ ! -d $FABRIC_CA_CLIENT_HOME ]; then
      dowait "$CA_NAME to start" 60 $CA_LOGFILE $CA_CHAINFILE
      log "Enrolling user '$USER_NAME' for organization $ORG with home directory $FABRIC_CA_CLIENT_HOME ..."
      export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
      env
      if ! [ -x "$(command -v fabric-ca-client)" ]; then
         echo 'fabric-ca-client is not installed - installing it now.'
         installFabricCA
      fi
      fabric-ca-client enroll -d -u https://$USER_NAME:$USER_PASS@$CA_HOST:7054
      # Set up admincerts directory if required
      if [ $ADMINCERTS ]; then
         ACDIR=$CORE_PEER_MSPCONFIGPATH/admincerts
         mkdir -p $ACDIR
         cp $ORG_ADMIN_HOME/msp/signcerts/* $ACDIR
      fi
   fi
}

# Copy the org's admin cert into some target MSP directory
# This is only required if ADMINCERTS is enabled.
function copyAdminCert {
   if [ $# -ne 1 ]; then
      fatal "Usage: copyAdminCert <targetMSPDIR>"
   fi
   if $ADMINCERTS; then
      dstDir=$1/admincerts
      log "copyAdminCert - copying '$ORG_ADMIN_CERT' to '$dstDir'"
      mkdir -p $dstDir
      cp $ORG_ADMIN_CERT $dstDir
   fi
}

# Create the TLS directories of the MSP folder if they don't exist.
# The fabric-ca-client should do this.
function finishMSPSetup {
   log "finishMSPSetup - copying '$1'/cacerts/* to '$1'/tlscacerts and '$1'/intermediatecerts/* '$1'/tlsintermediatecerts"
   if [ $# -ne 1 ]; then
      fatal "Usage: finishMSPSetup <targetMSPDIR>"
   fi
   if [ ! -d $1/tlscacerts ]; then
      mkdir $1/tlscacerts
      cp $1/cacerts/* $1/tlscacerts
      if [ -d $1/intermediatecerts ]; then
         mkdir $1/tlsintermediatecerts
         cp $1/intermediatecerts/* $1/tlsintermediatecerts
      fi
   fi
}

# Get the domain associated with the ORG. ORG is input, DOMAIN is output
function getDomain {
   if [ $# -ne 1 ]; then
      echo "Usage: getDomain <ORG>"
      exit 1
   fi
   orgsarr=($ORGS)
   domainarr=($DOMAINS)

   for i in "${!orgsarr[@]}"; do
      if [[ "${orgsarr[$i]}" = "${1}" ]]; then
           DOMAIN=${domainarr[$i]}
           return
      fi
   done
}

# Get the external address associated with the ORG. ORG is input, EXTERNAL_PEER_HOST is output
function getOrgExternalAddress {
   if [ $# -ne 2 ]; then
      echo "Usage: getOrgExternalAddress <ORG> <PEER_NUM>"
      exit 1
   fi
   orgsarr=($ORGS)
   addressarr=($EXTERNAL_ORG_PEER0_ADDRESSES)
   if [[ "${2}" = "1" ]]; then
      addressarr=($EXTERNAL_ORG_PEER1_ADDRESSES)
   fi
   for i in "${!orgsarr[@]}"; do
      if [[ "${orgsarr[$i]}" = "${1}" ]]; then
           EXTERNAL_PEER_HOST=${addressarr[$i-1]}
           return
      fi
   done
}

# Wait for one or more files to exist
# Usage: dowait <what> <timeoutInSecs> <errorLogFile> <file> [<file> ...]
function dowait {
   if [ $# -lt 4 ]; then
      fatal "Usage: dowait: $*"
   fi
   local what=$1
   local secs=$2
   local logFile=$3
   shift 3
   local logit=true
   local starttime=$(date +%s)
   for file in $*; do
      until [ -f $file ]; do
         if [ "$logit" = true ]; then
            log -n "Waiting for $what ..."
            logit=false
         fi
         sleep 1
         if [ "$(($(date +%s)-starttime))" -gt "$secs" ]; then
            echo ""
            fatal "Failed waiting for $what ($file not found); see $logFile"
         fi
         echo -n "."
      done
   done
   echo ""
}

# log a message
function log {
   if [ "$1" = "-n" ]; then
      shift
      echo -n "##### `date '+%Y-%m-%d %H:%M:%S'` $*"
   else
      echo "##### `date '+%Y-%m-%d %H:%M:%S'` $*"
   fi
}

# fatal a message
function fatal {
   log "FATAL: $*"
   exit 1
}
