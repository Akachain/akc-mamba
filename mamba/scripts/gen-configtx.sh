#!/bin/bash

# Setup cluster variables
source $(dirname "$0")/env.sh

function main() {
  local ORG=$PEER_DOMAINS
  echo $ORG
  getDomain $ORG
  mkdir -p /data/add-org/$ORG
  printConfigtx
}

# print configtx
function printConfigtx() {
  local configDir="/data/add-org/$ORG/configtx.yaml"
  echo ".$configDir."
  { 
  echo "
################################################################################
#
#   Section: Organizations
#
################################################################################
Organizations:
  - &$ORG

    Name: $ORG

    # ID to load the MSP definition as
    ID: ${ORG}MSP

    # MSPDir is the filesystem path which contains the MSP configuration
    MSPDir: /data/orgs/${ORG}/msp

    AdminPrincipal: Role.ADMIN

    Policies:
        Readers:
            Type: Signature
            Rule: \"OR('${ORG}MSP.member')\"
        Writers:
            Type: Signature
            Rule: \"OR('${ORG}MSP.member')\"
        Admins:
            Type: Signature
            Rule: \"OR('${ORG}MSP.admin')\"

    AnchorPeers:
       - Host: peer0-${ORG}.$DOMAIN
         Port: 7051
  "
  } > "$configDir" 
}

main