#!/bin/bash

function one_line_pem {
    awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\",$0;}' $1 > /tmp/one_line.pem
}

function generate_json_ccp {
    one_line_pem $CA_CHAINFILE
    local PEER_PEM=$(cat /tmp/one_line.pem)
    # CA and Peer using same public key
    local CA_PEM=$(cat /tmp/one_line.pem)

    echo "
{
    \"name\": \"${CLUSTER_NAME}-${ORG}\",
    \"version\": \"1.0.0\",
    \"client\": {
        \"organization\": \"${ORG}\",
        \"connection\": {
            \"timeout\": {
                \"peer\": {
                    \"endorser\": \"300\"
                }
            }
        }
    },
    \"organizations\": {
        \"${ORG}\": {
            \"mspid\": \"${ORG}MSP\",
            \"peers\": [
                \"peer0-${ORG}.${DOMAIN}\"
            ],
            \"certificateAuthorities\": [
                \"ica-${ORG}.${DOMAIN}\"
            ]
        }
    },
    \"peers\": {
        \"peer0-${ORG}.${DOMAIN}\": {
            \"url\": \"grpcs://peer0-${ORG}.${DOMAIN}:7051\",
            \"tlsCACerts\": {
                \"pem\": \"${PEER_PEM}\"
            },
            \"grpcOptions\": {
                \"ssl-target-name-override\": \"peer0-${ORG}.${DOMAIN}\",
                \"hostnameOverride\": \"peer0-${ORG}.${DOMAIN}\"
            }
        }
    },
    \"certificateAuthorities\": {
        \"ica-${ORG}.${DOMAIN}\": {
            \"url\": \"https://ica-${ORG}.${DOMAIN}:7054\",
            \"caName\": \"ica-${ORG}.${DOMAIN}\",
            \"tlsCACerts\": {
                \"pem\": \"${CA_PEM}\"
            },
            \"httpOptions\": {
                \"verify\": false
            }
        }
    }
}
" | sed -e 's/\\\\\\/\\n/g'  > /shared/admin-v2/artifacts/connection-${ORG}.json
cat /shared/admin-v2/artifacts/connection-${ORG}.json
}

function main {
    initOrgVars $ORG
    generate_json_ccp
}

source $(dirname "$0")/env.sh
OUTPUT=/shared/admin-v2/artifacts/connection-${ORG}.json
main
