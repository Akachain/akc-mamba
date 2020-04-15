#!/bin/bash

source $(dirname "$0")/env.sh

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
  local ADMIN_URL="http://admin-rca-ica.${ORDERER_DOMAINS}:4001"
  local ORG=""

  # Register user for each org
  for PEER_ORG in $PEER_ORGS
  do
    ORG=$PEER_ORG
    log "REGISTER USER: $PEER_ORG"
    REGISTER_USER=$(curl -s -X POST   ${ADMIN_URL}/registerUser   -H "content-type: application/json"   -d '{
      "orgname":"'"${PEER_ORG}"'"
    }');
    logResult "$REGISTER_USER"
  done

  # Create channel
  log "CREATE CHANNEL: $CHANNEL_NAME"
  CREATE_CHANNEL_CC=$(curl -s -X POST   ${ADMIN_URL}/channels   -H "content-type: application/json"   -d '{
    "orgname":"'"${ORG}"'",
    "channelName":"'"${CHANNEL_NAME}"'",
    "channelConfigPath":"../../../shared/channel.tx"
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
      JOINCHANNEL=$(curl -s -X POST   ${ADMIN_URL}/joinchannel   -H "content-type: application/json"   -d '{
        "orgname":"'"${PEER_ORG}"'",
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

  # Install sample chaincode
  log "INSTALL CHAINCODE"
  for PEER_ORG in $PEER_ORGS
  do
    INSTALL_CHAINCODE=$(curl -s -X POST   ${ADMIN_URL}/chaincodes   -H "content-type: application/json"   -d '{
      "orgname":"'"${PEER_ORG}"'",
      "chaincodePath":"chaincodes/fabcar/",
      "chaincodeId":"fabcar1",
      "chaincodeVersion":"v1.0",
      "chaincodeType":"golang"
    }');
    logResult "$INSTALL_CHAINCODE"
  done

  # Init sample chaincode
  log "INIT CHAINCODE"
  INIT_CHAINCODE=$(curl -s -X POST   ${ADMIN_URL}/initchaincodes   -H "content-type: application/json"   -d '{
    "orgname":"'"${PEER_ORG}"'",
    "channelName":"'"${CHANNEL_NAME}"'",
    "chaincodeId":"fabcar1",
    "chaincodeVersion":"v1.0",
    "chaincodeType":"golang",
    "args":[]
  }');
  logResult "$INIT_CHAINCODE"
  sleep 3s
  # Invoke
  log "INVOKE CHAINCODE"
  INVOKE_CHAINCODE=$(curl -s -X POST   ${ADMIN_URL}/invokeChainCode   -H "content-type: application/json"   -d '{
    "orgname":"'"${PEER_ORG}"'",
    "channelName":"'"${CHANNEL_NAME}"'",
    "chaincodeId":"fabcar1",
    "args": ["CAR1", "a", "b", "c", "d"],
    "fcn": "createCar"
  }');
  logResult "$INVOKE_CHAINCODE"
}
main