#!/bin/bash

# Builds the channel artifacts (e.g. genesis block, etc)
#

function main {
   log "Beginning building channel artifacts ..."
   makeConfigTxYaml
   generateChannelArtifacts
   log "Finished building channel artifacts"
}

# printOrg
function printOrg {
   echo "
  - &$ORG_CONTAINER_NAME

    Name: $ORG

    # ID to load the MSP definition as
    ID: $ORG_MSP_ID

    # MSPDir is the filesystem path which contains the MSP configuration
    MSPDir: $ORG_MSP_DIR

    # AdminPrincipal: Role.ADMIN

    Policies:"
    if [ "$1" == "peer" ]; then
        echo "
        Readers:
            Type: Signature
            Rule: \"OR('$ORG_MSP_ID.admin', '$ORG_MSP_ID.peer', '$ORG_MSP_ID.client')\"
        Writers:
            Type: Signature
            Rule: \"OR('$ORG_MSP_ID.admin', '$ORG_MSP_ID.client')\"
        Admins:
            Type: Signature
            Rule: \"OR('$ORG_MSP_ID.admin')\"
        Endorsement:
            Type: Signature
            Rule: \"OR('$ORG_MSP_ID.peer')\""
    else
        echo "
        Readers:
            Type: Signature
            Rule: \"OR('$ORG_MSP_ID.member')\"
        Writers:
            Type: Signature
            Rule: \"OR('$ORG_MSP_ID.member')\"
        Admins:
            Type: Signature
            Rule: \"OR('$ORG_MSP_ID.admin')\""
    fi
}

# printOrdererOrg <ORG>
function printOrdererOrg {
   initOrgVars $1
   printOrg
}

# printPeerOrg <ORG> <COUNT>
function printPeerOrg {
   initPeerVars $1 $2
   PEER_HOST=${PEER_NAME}.${DOMAIN}
   local PEER="peer"
   printOrg $PEER
   echo "
    AnchorPeers:
       - Host: $PEER_HOST
         Port: 7051"
}

function makeConfigTxYaml {
   {
   echo "
################################################################################
#
#   SECTION: Capabilities
#
################################################################################
Capabilities:
    Channel: &ChannelCapabilities
        V2_0: true

    Orderer: &OrdererCapabilities
        V2_0: true

    Application: &ApplicationCapabilities
        V2_0: true"

   echo "
################################################################################
#
#   Section: Organizations
#
################################################################################
Organizations:"

   for ORG in $ORDERER_ORGS; do
      printOrdererOrg $ORG
   done

   for ORG in $PEER_ORGS; do
      printPeerOrg $ORG 1
   done

   echo "
################################################################################
#
#   SECTION: Orderer
#
################################################################################
Orderer: &OrdererDefaults

    # Orderer Type: The orderer implementation to start.
    # Available types are \"solo\", \"kafka\" and \"etcdraft\".
    OrdererType: $ORDERER_TYPE

    # Batch Timeout: The amount of time to wait before creating a batch.
    BatchTimeout: $BATCH_TIMEOUT

    # Batch Size: Controls the number of messages batched into a block.
    BatchSize:

        # Max Message Count: The maximum number of messages to permit in a
        # batch.
        MaxMessageCount: $BATCH_SIZE_MAX_MESSAGE_COUNT

        # Absolute Max Bytes: The absolute maximum number of bytes allowed for
        # the serialized messages in a batch. If the 'kafka' OrdererType is
        # selected, set 'message.max.bytes' and 'replica.fetch.max.bytes' on the
        # Kafka brokers to a value that is larger than this one.
        AbsoluteMaxBytes: 99 MB

        # Preferred Max Bytes: The preferred maximum number of bytes allowed for
        # the serialized messages in a batch. A message larger than the
        # preferred max bytes will result in a batch larger than preferred max
        # bytes.
        PreferredMaxBytes: 512 KB

    # Max Channels is the maximum number of channels to allow on the ordering
    # network. When set to 0, this implies no maximum number of channels.
    MaxChannels: 0"

    if [ "$ORDERER_TYPE" == "kafka" ]; then
        echo "
    Kafka:
        # Brokers: A list of Kafka brokers to which the orderer connects. Edit
        # this list to identify the brokers of the ordering service.
        # NOTE: Use IP:port notation.
        Brokers:
            - broker.$KAFKA_NAMESPACE:9092"
    elif [ "$ORDERER_TYPE" == "etcdraft" ]; then
        echo "
    EtcdRaft:
        Consenters:"
        for ORG in $ORDERER_ORGS; do
            local COUNT=1
            while [[ "$COUNT" -le $NUM_ORDERERS ]]; do
                if [ "$FABRIC_NETWORK_TYPE" == "PROD" ] && [[ "$COUNT" -gt 1 ]]; then
                    COUNT=$((COUNT+1))
                    continue
                fi
                initOrdererVars $ORG $COUNT
                echo "
        - Host: $ORDERER_HOST
          Port: $ORDERER_PORT
          ClientTLSCert: /data/crypto-config/$ORG.$DOMAIN/orderers/$ORDERER_HOST/tls/server.crt
          ServerTLSCert: /data/crypto-config/$ORG.$DOMAIN/orderers/$ORDERER_HOST/tls/server.crt
                "
                COUNT=$((COUNT+1))
            done
        done
    fi
    echo "
    Addresses:"
    if [ "$EXTERNAL_ORDERER_ADDRESSES" != "" ]; then
    echo "
        - $EXTERNAL_ORDERER_ADDRESSES:7050"
    fi
    for ORG in $ORDERER_ORGS; do
    local COUNT=1
    while [[ "$COUNT" -le $NUM_ORDERERS ]]; do
        if [ "$FABRIC_NETWORK_TYPE" == "PROD" ] && [[ "$COUNT" -gt 1 ]]; then
            COUNT=$((COUNT+1))
            continue
        fi
        initOrdererVars $ORG $COUNT
        echo "        - $ORDERER_HOST:$ORDERER_PORT"
        COUNT=$((COUNT+1))
    done
    done
    echo "
    # Organizations is the list of orgs which are defined as participants on
    # the orderer side of the network.
    Organizations:"

    # for ORG in $ORDERER_ORGS; do
    #   initOrgVars $ORG
    #   echo "        - *${ORG_CONTAINER_NAME}"
    # done

   echo "
    # Policies defines the set of policies at this level of the config tree
    # For Orderer policies, their canonical path is
    #   /Channel/Orderer/<PolicyName>
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: \"ANY Readers\"
        Writers:
            Type: ImplicitMeta
            Rule: \"ANY Writers\"
        Admins:
            Type: ImplicitMeta
            Rule: \"MAJORITY Admins\"
        # BlockValidation specifies what signatures must be included in the block
        # from the orderer for the peer to validate it.
        BlockValidation:
            Type: ImplicitMeta
            Rule: \"ANY Writers\"

    # Capabilities describes the orderer level capabilities, see the
    # dedicated Capabilities section elsewhere in this file for a full
    # description
    Capabilities:
        <<: *OrdererCapabilities"

   echo "
################################################################################
#
#   CHANNEL
#
#   This section defines the values to encode into a config transaction or
#   genesis block for channel related parameters.
#
################################################################################
Channel: &ChannelDefaults
    # Policies defines the set of policies at this level of the config tree
    # For Channel policies, their canonical path is
    #   /Channel/<PolicyName>
    Policies:
        # Who may invoke the 'Deliver' API
        Readers:
            Type: ImplicitMeta
            Rule: \"ANY Readers\"
        # Who may invoke the 'Broadcast' API
        Writers:
            Type: ImplicitMeta
            Rule: \"ANY Writers\"
        # By default, who may modify elements at this config level
        Admins:
            Type: ImplicitMeta
            Rule: \"MAJORITY Admins\"


    # Capabilities describes the channel level capabilities, see the
    # dedicated Capabilities section elsewhere in this file for a full
    # description
    Capabilities:
        <<: *ChannelCapabilities"

   echo "
################################################################################
#
#   SECTION: Application
#
################################################################################
Application: &ApplicationDefaults

    # Organizations is the list of orgs which are defined as participants on
    # the application side of the network.
    Organizations:

    # Policies defines the set of policies at this level of the config tree
    # For Application policies, their canonical path is
    #   /Channel/Application/<PolicyName>
    Policies: &ApplicationDefaultPolicies
        Readers:
            Type: ImplicitMeta
            Rule: \"ANY Readers\"
        Writers:
            Type: ImplicitMeta
            Rule: \"ANY Writers\"
        Admins:
            Type: ImplicitMeta
            Rule: \"MAJORITY Admins\"
        LifecycleEndorsement:
            Type: ImplicitMeta
            Rule: \"MAJORITY Endorsement\"
        Endorsement:
            Type: ImplicitMeta
            Rule: \"MAJORITY Endorsement\"

    # Capabilities describes the application level capabilities, see the
    # dedicated Capabilities section elsewhere in this file for a full
    # description
    Capabilities:
        <<: *ApplicationCapabilities"

   echo "
################################################################################
#
#   Profiles
#
################################################################################
Profiles:

    OrgsOrdererGenesis:
        <<: *ChannelDefaults
        Capabilities:
            <<: *ChannelCapabilities
        Orderer:
            <<: *OrdererDefaults
            Organizations:"
                for ORG in $ORDERER_ORGS; do
                  initOrgVars $ORG
                  echo "                - *${ORG_CONTAINER_NAME}"
                done
   echo "
            Capabilities:
                <<: *OrdererCapabilities
        Application:
            <<: *ApplicationDefaults
            Organizations:"
                for ORG in $ORDERER_ORGS; do
                  initOrgVars $ORG
                  echo "                - *${ORG_CONTAINER_NAME}"
                done
   echo "
            Capabilities:
                <<: *ApplicationCapabilities
        Consortiums:
            SampleConsortium:
                Organizations:"
                    for ORG in $PEER_ORGS; do
                      initOrgVars $ORG
                      echo "                    - *${ORG_CONTAINER_NAME}"
                    done

   echo "
    OrgsChannel:
        <<: *ChannelDefaults
        Consortium: SampleConsortium
        Application:
            <<: *ApplicationDefaults
            Organizations:"
                    for ORG in $PEER_ORGS; do
                      initOrgVars $ORG
                      echo "                - *${ORG_CONTAINER_NAME}"
                    done
   echo "
            Capabilities:
                <<: *ApplicationCapabilities"
   } > /etc/hyperledger/fabric/configtx.yaml
   # Copy it to the data directory to make debugging easier
   cp /etc/hyperledger/fabric/configtx.yaml /$DATA
}

function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatal "configtxgen tool not found. exiting"
  fi

  log "Generating orderer genesis block at $GENESIS_BLOCK_FILE"
  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  if [ "$FABRIC_TAG" == "2.2.0" ]; then
    configtxgen -profile OrgsOrdererGenesis -channelID mamba-sys-channel -outputBlock $GENESIS_BLOCK_FILE
  else
    configtxgen -profile OrgsOrdererGenesis -outputBlock $GENESIS_BLOCK_FILE
  fi
  if [ "$?" -ne 0 ]; then
    fatal "Failed to generate orderer genesis block"
  fi

  log "Generating channel configuration transaction at $CHANNEL_TX_FILE"
  configtxgen -profile OrgsChannel -outputCreateChannelTx $CHANNEL_TX_FILE -channelID $CHANNEL_NAME
  if [ "$?" -ne 0 ]; then
    fatal "Failed to generate channel configuration transaction"
  fi

  for ORG in $PEER_ORGS; do
     initOrgVars $ORG
     log "Generating anchor peer update transaction for $ORG at $ANCHOR_TX_FILE"
     configtxgen -profile OrgsChannel -outputAnchorPeersUpdate $ANCHOR_TX_FILE \
                 -channelID $CHANNEL_NAME -asOrg $ORG
     if [ "$?" -ne 0 ]; then
        fatal "Failed to generate anchor peer update for $ORG"
     fi
  done
}

set -e

SDIR=$(dirname "$0")
source $SDIR/env.sh

main
