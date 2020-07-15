#!/bin/bash

# Generate anchor config file
function generateAnchorConfig() {
    for ORG in $ORGS; do
        echo "#######    Generating anchor peer update transaction for ${ORG}  ##########"
        set -x
        export FABRIC_CFG_PATH=$PWD
        mkdir -p /data/channel-artifacts
        configtxgen -profile OrgsChannel -outputAnchorPeersUpdate "./channel-artifacts/${ORG}Anchors.tx" -channelID $CHANNEL_NAME -asOrg ${ORG}
        res=$?
        set +x
        if [ $res -ne 0 ]; then
            echo "Failed to generate anchor peer update transaction for ${ORG}..."
            exit 1
        fi
        echo
    done
}

function updateAnchorPeerConfig() {
    which curl
    if [ "$?" -ne 0 ]; then
        echo "configtxgen tool not found. installing"
        apk update && apk add curl
    fi
    for ORG in $ORGS; do
        # local orgmsp=${ORG}MSP
        set -x
        curl -s -X POST   http://$ADMIN_URL/api/v2/peers/updateAnchorPeer   -H "content-type: application/json"   -d '{
            "orgName":"'"${ORG}"'",
            "peerIndex": "0",
            "channelName":"'"${CHANNEL_NAME}"'",
            "ordererAddress": "'"${ORDERER_ADDRESS}"'",
            "anchorConfigPath":"'"/shared/channel-artifacts/${ORG}Anchors.tx"'"
        }'
        set +x
    done

    echo "Update Anchor Peer Config"
}

function main() {
    generateAnchorConfig
    updateAnchorPeerConfig
}

cd /data/
main


