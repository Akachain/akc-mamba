#!/bin/bash

# Setup cluster variables
source $(dirname "$0")/env.sh

function main {
   log "Beginning make application artifacts ..."
   printNetworkConfig
   for PEER_ORG in $PEER_ORGS
   do
    printOrgYaml $PEER_ORG
   done
   log "Finished building application artifacts"
}

# printCA
function printCA {
  for PEER_ORG in $PEER_ORGS
  do
    initOrgVars $PEER_ORG
    echo "
  $INT_CA_NAME:
    url: https://$INT_CA_HOST:7054
    # the properties specified under this object are passed to the 'http' client verbatim when
    # making the request to the Fabric-CA server
    httpOptions:
      verify: false
    tlsCACerts:
      path: /shared/ica-$PEER_ORG-ca-chain.pem

    # Fabric-CA supports dynamic user enrollment via REST APIs. A \"root\" user, a.k.a registrar, is
    # needed to enroll and invoke new users.
    registrar:
      - enrollId: $INT_CA_ADMIN_USER
        enrollSecret: $INT_CA_ADMIN_PASS
    # [Optional] The optional name of the CA.
    caName: $INT_CA_NAME
    "
  done


}

# printPeer
function printPeer {
  for org in $PEER_ORGS
  do
    getDomain $org
    for (( peerNum=0; peerNum<$NUM_PEERS; peerNum++ ))
    do
      echo "
  peer$peerNum-$org.$DOMAIN:
    url: grpcs://peer$peerNum-$org.$DOMAIN:7051

    grpcOptions:
      ssl-target-name-override: peer$peerNum-$org.$DOMAIN
    tlsCACerts:
      path: /shared/ica-$org-ca-chain.pem
      "
    done
  done

  endorsementOrg=($ENDORSEMENT_ORG_NAME)
  endorsementAddress=($ENDORSEMENT_ORG_ADDRESS)
  endorsementTlsCert=($ENDORSEMENT_ORG_TLSCERT)
  for (( i=0; i<${#endorsementOrg[@]}; i++ ))
  do
    echo "
  ${endorsementOrg[i]}:
    url: grpcs://${endorsementAddress[i]}:7051

    grpcOptions:
      ssl-target-name-override: ${endorsementOrg[i]}
    tlsCACerts:
      path: /shared/${endorsementTlsCert[i]}"
  done

}

# printOrderer
function printOrderer {
  if [[ "$ORDERER_ORGS" == "" ]]; then
    echo "
  orderer-external:
    url: grpcs://$EXTERNAL_ORDERER_ADDRESSES:7050
    grpcOptions:
      ssl-target-name-override: $EXTERNAL_ORDERER_ADDRESSES
      grpc-max-send-message-length: -1

    tlsCACerts:
      path: /shared/ica-orderer-ca-chain.pem
    "
  fi
  for i in $ORDERER_ORGS
  do
    for (( j=0; j<$NUM_ORDERERS; j++ ))
    do
      echo "
  orderer$j-$i.$ORDERER_DOMAINS:
    url: grpcs://orderer$j-$i.$ORDERER_DOMAINS:7050
    grpcOptions:
      ssl-target-name-override: orderer$j-$i.$ORDERER_DOMAINS
      grpc-max-send-message-length: -1

    tlsCACerts:
      path: /shared/ica-orderer-ca-chain.pem
    "
    done
  done
}

# printOrgs
function printOrgs {
  initOrgVars $1
  echo "
  $ORG:
    mspid: $ORG_MSP_ID

    peers:"
    for (( peerNum=0; peerNum<$NUM_PEERS; peerNum++ ))
    do  
      echo "
      - peer$peerNum-$ORG.$DOMAIN
      "
    done

    echo "
    # Fabric-CA servers.
    certificateAuthorities:
      - $INT_CA_NAME

    adminPrivateKey:
      path: /shared/crypto-config/peerOrganizations/$DOMAIN/users/admin/msp/keystore/key.pem
    signedCert:
      path: /shared/crypto-config/peerOrganizations/$DOMAIN/users/admin/msp/signcerts/cert.pem
    "
}
function printNetworkConfig {
  rm -rf /data/app/artifacts/network-config.yaml
  {
  echo "
---
#
# The network connection profile provides client applications the information about the target
# blockchain network that are necessary for the applications to interact with it. These are all
# knowledge that must be acquired from out-of-band sources. This file provides such a source.
#
name: \"Akachain\"

#
# Any properties with an \"x-\" prefix will be treated as application-specific, exactly like how naming
# in HTTP headers or swagger properties work. The SDK will simply ignore these fields and leave
# them for the applications to process. This is a mechanism for different components of an application
# to exchange information that are not part of the standard schema described below. In particular,
# the \"x-type\" property with the \"hlfv1\" value example below is used by Hyperledger Composer to
# determine the type of Fabric networks (v0.6 vs. v1.0) it needs to work with.
#
x-type: \"hlfv1\"

#
# Describe what the target network is/does.
#
description: \"Akachain Network\"

#
# Schema version of the content. Used by the SDK to apply the corresponding parsing rules.
#
version: \"1.0\"

#
# The client section will be added on a per org basis see org1.yaml and org2.yaml
#
# client
#
# [Optional]. But most apps would have this section so that channel objects can be constructed
# based on the content below. If an app is creating channels, then it likely will not need this
# section.
#
channels:

  $CHANNEL_NAME:
    orderers:"
      if [[ "$ORDERER_ORGS" == "" ]]; then
        echo "      - orderer-external"
      fi
      for i in $ORDERER_ORGS
      do
        for (( j=0; j<$NUM_ORDERERS; j++ ))
        do
          echo "      - orderer$j-$i.$ORDERER_DOMAINS"
        done
      done
      echo "
    peers:"
      for endorsementOrg in $ENDORSEMENT_ORG_NAME
      do
        echo "
      $endorsementOrg:
        endorsingPeer: true
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: true
        "
      done
      for org in $PEER_ORGS
      do
        getDomain $org
        for (( peerNum=0; peerNum<$NUM_PEERS; peerNum++ ))
        do  
          if [ "$peerNum" == "0" ]; then
            echo "
      peer$peerNum-$org.$DOMAIN:
        endorsingPeer: true
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: true
          "
          else
            echo "
      peer$peerNum-$org.$DOMAIN:
        endorsingPeer: false
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: false
          "
          fi
        done
      done

  echo "
organizations:
"
  for org in $PEER_ORGS
  do
    printOrgs $org
  done

  echo "
#
# List of orderers to send transaction and channel create/update requests to. For the time
# being only one orderer is needed. If more than one is defined, which one get used by the
# SDK is implementation specific. Consult each SDK's documentation for its handling of orderers.
#
orderers:
"
  printOrderer

  echo "
peers:
"
  printPeer

  echo "
#
# Fabric-CA is a special kind of Certificate Authority provided by Hyperledger Fabric which allows
# certificate management to be done via REST APIs. Application may choose to use a standard
# Certificate Authority instead of Fabric-CA, in which case this section would not be specified.
#
certificateAuthorities:
"
  printCA
  } > /data/app/artifacts/network-config.yaml
}

function printOrgYaml {
  local org=$1
  rm -rf /data/app/artifacts/$org.yaml
  {
  echo "
---
#
# The network connection profile provides client applications the information about the target
# blockchain network that are necessary for the applications to interact with it. These are all
# knowledge that must be acquired from out-of-band sources. This file provides such a source.
#
name: \"AKC\"

#
# Any properties with an \"x-\" prefix will be treated as application-specific, exactly like how naming
# in HTTP headers or swagger properties work. The SDK will simply ignore these fields and leave
# them for the applications to process. This is a mechanism for different components of an application
# to exchange information that are not part of the standard schema described below. In particular,
# the \"x-type\" property with the \"hlfv1\" value example below is used by Hyperledger Composer to
# determine the type of Fabric networks (v0.6 vs. v1.0) it needs to work with.
#
x-type: \"hlfv1\"

#
# Describe what the target network is/does.
#
description: \"AKC Network - client definition for $org\"

#
# Schema version of the content. Used by the SDK to apply the corresponding parsing rules.
#
version: \"1.0\"

#
# The client section is SDK-specific. The sample below is for the node.js SDK
#
client:
  # Which organization does this application instance belong to? The value must be the name of an org
  # defined under \"organizations\"
  organization: $org

  # Some SDKs support pluggable KV stores, the properties under \"credentialStore\"
  # are implementation specific
  credentialStore:
    # [Optional]. Specific to FileKeyValueStore.js or similar implementations in other SDKs. Can be others
    # if using an alternative impl. For instance, CouchDBKeyValueStore.js would require an object
    # here for properties like url, db name, etc.
    path: \"./crypto-path/fabric-client-kv-$org\"

    # [Optional]. Specific to the CryptoSuite implementation. Software-based implementations like
    # CryptoSuite_ECDSA_AES.js in node SDK requires a key store. PKCS#11 based implementations does
    # not.
    cryptoStore:
      # Specific to the underlying KeyValueStore that backs the crypto key store.
      path: \"/tmp/crypto-store/fabric-client-kv-$org\"

    # [Optional]. Specific to Composer environment
    # wallet: wallet-name
  "
  } > /data/app/artifacts/$org.yaml
}

main