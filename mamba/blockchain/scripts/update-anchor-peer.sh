#!/bin/bash

# Generate anchor config file
function generateAnchorConfig() {
    for ORG in $ORGS; do
        local orgmsp=${ORG}MSP
        echo "#######    Generating anchor peer update transaction for ${orgmsp}  ##########"
        set -x
        export FABRIC_CFG_PATH=$PWD
        mkdir -p /shared/channel-artifacts
        configtxgen -profile $CHANNEL_NAME -outputAnchorPeersUpdate "./channel-artifacts/${orgmsp}anchors.tx" -channelID $CHANNEL_NAME -asOrg ${orgmsp}
        res=$?
        set +x
        if [ $res -ne 0 ]; then
            echo "Failed to generate anchor peer update transaction for ${orgmsp}..."
            exit 1
        fi
        echo
    done
}

function updateAnchorPeerConfig() {
    which curl
    if [ "$?" -ne 0 ]; then
        echo "configtxgen tool not found. installing"
        apt-get update && apt-get install curl -y
    fi
    for ORG in $ORGS; do
        local orgmsp=${ORG}MSP
        set -x
        curl -s -X POST   http://$ADMIN_URL/api/v2/peers/updateAnchorPeer   -H "content-type: application/json"   -d '{
            "orgName":"'"${ORG}"'",
            "peerIndex": "0",
            "channelName":"'"${CHANNEL_NAME}"'",
            "ordererAddress": "'"${ORDERER_ADDRESS}"'",
            "configUpdatePath":"'"../artifacts/channel-artifacts/${orgmsp}anchors.tx"'"
        }'
        set +x
    done

    echo "Update Anchor Peer Config"
}

function main() {
    generateAnchorConfig
    updateAnchorPeerConfig
}

cd /shared/
main


