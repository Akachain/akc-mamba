#!/bin/bash

source $(dirname "$0")/env.sh
set -e

function logResult {
  local RESULT=$1
  if [[ $RESULT == *"true"* ]]
  then
    printf -- "\033[32m $RESULT. \033[0m\n";
    return 0
  else
    printf -- "\033[31m $RESULT. \033[0m\n";
    return 1
  fi
}

function main {
  local ORG="" 

  # Enroll admin for each org
  for PEER_ORG in $PEER_ORGS
  do
    ORG=$PEER_ORG
    initOrgVars $ORG
    log "Enroll Admin: $PEER_ORG"
    ENROLL_ADMIN=$(curl -s -X POST   ${ADMIN_URL}/api/v2/cas/enrollAdmin   -H "content-type: application/json"   -d '{
      "orgName":"'"${PEER_ORG}"'",
      "adminName": "'"${INT_CA_ADMIN_USER}"'",
      "adminPassword": "'"${INT_CA_ADMIN_PASS}"'"
    }');
    logResult "$ENROLL_ADMIN"

    log "Register User: $PEER_ORG"
    REGISTER_USER=$(curl -s -X POST   ${ADMIN_URL}/api/v2/cas/registerUser   -H "content-type: application/json"   -d '{
      "orgName":"'"${PEER_ORG}"'",
      "affiliation":"'"${PEER_ORG}"'.akc",
      "affiliation":"'"${PEER_ORG}"'.akc",
      "userName": "'"${PEER_ORG}"'",
      "role": "client",
      "adminName": "'"${INT_CA_ADMIN_USER}"'"
    }');
    logResult "$ENROLL_ADMIN"
  done

  # Create channel
  log "CREATE CHANNEL: $CHANNEL_NAME"
  CREATE_CHANNEL_CC=$(curl -s -X POST   ${ADMIN_URL}/api/v2/channels/create   -H "content-type: application/json"   -d '{
    "orgName":"'"${ORG}"'",
    "peerIndex":"0",
    "channelName":"'"${CHANNEL_NAME}"'",
    "ordererAddress":"'"${ORDERER_ADDRESS}"'",
    "channelConfig":"/shared/channel.tx"
  }');
  logResult "$CREATE_CHANNEL_CC"
  sleep 3s
  # Sometimes Join takes time hence RETRY at least 3 times
  log "JOIN CHANNEL"
  local MAX_RETRY=3
  local DELAY=3
  for PEER_ORG in $PEER_ORGS
  do
    log "Org ${PEER_ORG} join the channel ${CHANNEL_NAME}"
    for (( h=0; h<=$MAX_RETRY; h++ ))
    do
      JOINCHANNEL=$(curl -s -X POST   ${ADMIN_URL}/api/v2/channels/join   -H "content-type: application/json"   -d '{
        "orgName":"'"${PEER_ORG}"'",
        "peerIndex":"0",
        "channelName":"'"${CHANNEL_NAME}"'"
      }');
      logResult "$JOINCHANNEL"
      res=$?
      if [ $res -eq 0 ]; then
        break
      else
        echo "Org ${PEER_ORG} failed to join the channel, Retry after $DELAY seconds"
        sleep $DELAY
      fi
    done
  done

  # Package sample chaincode
  log "PACKAGE CHAINCODE"
  PACKAGE_CHAINCODE=$(curl -s -X POST   ${ADMIN_URL}/api/v2/chaincodes/packageCC   -H "content-type: application/json"   -d '{
    "orgname":"'"${ORG}"'",
    "chaincodePath":"chaincodes/fabcar",
    "chaincodeName":"fabcar",
    "chaincodeVersion":"1",
    "chaincodeType":"golang",
    "peerIndex": "0"
  }');
  logResult "$PACKAGE_CHAINCODE"

  # Install and approve sample chaincode
  log "INSTALL CHAINCODE"
  for PEER_ORG in $PEER_ORGS
  do
    INSTALL_CHAINCODE=$(curl -s -X POST   ${ADMIN_URL}/api/v2/chaincodes/install   -H "content-type: application/json"   -d '{
      "orgname":"'"${PEER_ORG}"'",
      "chaincodeName":"fabcar",
      "chaincodePath":"fabcar.tar.gz",
      "peerIndex":"0"
    }');
    logResult "$INSTALL_CHAINCODE"

    echo $QUERY_PACKAGE_CHAINCODE
    log "QUERY PACKAGE CHAINCODE"
    QUERY_PACKAGE_CHAINCODE=$(curl -s -X POST   ${ADMIN_URL}/api/v2/chaincodes/queryInstalled   -H "content-type: application/json"   -d '{
      "orgname":"'"${PEER_ORG}"'",
      "peerIndex":"0"
    }' | jq -r '.data[0].packageId');
    echo $QUERY_PACKAGE_CHAINCODE

    APPROVE_CHAINCODE=$(curl -s -X POST   ${ADMIN_URL}/api/v2/chaincodes/approveForMyOrg   -H "content-type: application/json"   -d '{
      "orgname":"'"${PEER_ORG}"'",
      "peerIndex":"0",
      "chaincodeName":"fabcar",
      "chaincodeVersion":1,
      "channelName":"'"${CHANNEL_NAME}"'",
      "packageId":"'"${QUERY_PACKAGE_CHAINCODE}"'",
      "ordererAddress":"'"${ORDERER_ADDRESS}"'"
    }');
    logResult "$APPROVE_CHAINCODE"
  done

  # Commit chaincode
  log "COMMIT CHAINCODE"
  COMMIT_CHAINCODE=$(curl -s -X POST   ${ADMIN_URL}/api/v2/chaincodes/commitChaincodeDefinition   -H "content-type: application/json"   -d '{
    "chaincodeName":"fabcar",
    "chaincodeVersion":1,
    "channelName":"'"${CHANNEL_NAME}"'",
    "target": "'"0 ${ORG}"'",
    "ordererAddress": "'"${ORDERER_ADDRESS}"'"
  }');
  logResult "$COMMIT_CHAINCODE"

  # Invoke sample chaincode
  log "INVOKE CHAINCODE"
  INVOKE_CHAINCODE=$(curl -s -X POST   ${ADMIN_URL}/api/v2/chaincodes/invokeCLI   -H "content-type: application/json"   -d '{
    "chaincodeName": "fabcar",
    "channelName": "'"${CHANNEL_NAME}"'",
    "target": "'"0 ${ORG}"'",
    "ordererAddress": "'"${ORDERER_ADDRESS}"'",
    "args": [],
    "fcn": "initLedger",
    "isInit": "0"
  }');
  logResult "$INVOKE_CHAINCODE"
}

apk add jq
main