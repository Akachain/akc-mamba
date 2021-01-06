## 1. Start network
```bash
mamba start
```
## 2. Prepare merchant config in '/home/hainq/.akachain/akc-mamba/mamba/config/merchant.env'
- In merchant env, must fill:
  - REMOTE_RCA_NAME, REMOTE_RCA_ADDRESS, REMOTE_ORDERER_HOST, REMOTE_ORDERER_NAME, REMOTE_ORDERER_DOMAIN
  - ENDORSEMENT_ORG_NAME, ENDORSEMENT_ORG_ADDRESS, ENDORSEMENT_ORG_TLSCERT
- In operator env, must fill:
  - NEW_ORG_NAME
```
cp /home/hainq/.akachain/akc-mamba/mamba/config/merchant.env /home/hainq/.akachain/akc-mamba/mamba/config/.env
```
- Prepare folder of merchant cluster using command:
```
mamba copyscripts
```
- Setup environment:
```
mamba environment
```
## 3. Copy signed cert of root ca to merchant cluster
```
kubectl exec -it test-efs-7759545f7-b5ffw bash
cp /tmp/artifact/akc-network/akc-ca-data/rca-akc-cert.pem /tmp/artifact/merchant-network/akc-ca-data/
```

## 4. Create new org in new cluster
```
mamba create-org
```
-> Automation generate to merchant.json
## 5. Copy merchant.json to operator cluster
```
cp /tmp/artifact/merchant-network/akc-ca-data/merchant.json /tmp/artifact/akc-network/akc-ca-data/
```
## 6. In operator cluster, add merchant to channel
Must specify env: NEW_ORG_NAME="merchant" in operator.env file
```
cp /home/hainq/.akachain/akc-mamba/mamba/config/operator.env /home/hainq/.akachain/akc-mamba/mamba/config/.env
mamba channel-config auto-update
```

## 7. Install chaincode test
```
curl --location --request POST http://admin-v2-akc.akc:4001/api/v2/chaincodes/packageCC \
--header 'content-type: application/json' \
--data-raw '{
  "orgName":"akc",
  "chaincodePath":"/chaincodes/fabcar",
  "chaincodeName":"fabcar",
  "chaincodeVersion":"2",
  "chaincodeType":"golang",
  "peerIndex": "0"
}'
curl --location --request POST http://admin-v2-akc.akc:4001/api/v2/chaincodes/install \
--header 'content-type: application/json' \
--data-raw '{
  "chaincodeName":"fabcar",
  "chaincodePath":"fabcar.tar.gz",
  "target": "0 akc"
}'

curl --location --request POST http://admin-v2-akc.akc:4001/api/v2/chaincodes/queryInstalled \
--header 'content-type: application/json' \
--data-raw '{
    "orgName":"akc",
    "peerIndex": "0",
    "chaincodeName": "fabcar",
    "chaincodeVersion": "2"
}'
curl --location --request POST http://admin-v2-akc.akc:4001/api/v2/chaincodes/approveForMyOrg \
--header 'content-type: application/json' \
--data-raw '{
    "orgName":"akc",
    "peerIndex": "0",
    "chaincodeName": "fabcar",
    "chaincodeVersion": 2,
    "channelName": "akcchannel",
    "packageId": "fabcar_2:dd2f978e3976a3df9812335447207907051b24e7315841ac922b5fd376e74cb8",
    "ordererAddress": "orderer0-orderer.orderer:7050"
}'
```

## 8. Copy signed cert of orderer and akc org to merchant cluster
- Orderer TLS cert
```
mkdir -p /tmp/artifact/c-merchant/akc-ca-data/crypto-config/orderer.orderer/orderers/orderer0-orderer.orderer/msp/tlsintermediatecerts/
cp /tmp/artifact/cluster-mamba-example/akc-ca-data/crypto-config/orderer.orderer/orderers/orderer0-orderer.orderer/msp/tlsintermediatecerts/ica-orderer-orderer-7054.pem /tmp/artifact/c-merchant/akc-ca-data/crypto-config/orderer.orderer/orderers/orderer0-orderer.orderer/msp/tlsintermediatecerts/
```
- Operator peer TLS cert
```
mkdir -p /tmp/artifact/c-merchant/akc-ca-data/crypto-config/akc.akc/peers/peer0-akc.akc/tls/tlsintermediatecerts/
cp /tmp/artifact/cluster-mamba-example/akc-ca-data/crypto-config/akc.akc/peers/peer0-akc.akc/tls/tlsintermediatecerts/tls-ica-akc-akc-7054.pem /tmp/artifact/c-merchant/akc-ca-data/crypto-config/akc.akc/peers/peer0-akc.akc/tls/tlsintermediatecerts/
```

## 9. Join merchant to channel
```
curl -s -X POST   http://admin-v2-merchant.merchant:4001/api/v2/cas/enrollAdmin   -H "content-type: application/json"   -d '{
  "orgName":"merchant",
  "adminName": "ica-merchant-admin",
  "adminPassword": "ica-merchant-adminpw"
}'
curl -s -X POST   http://admin-v2-merchant.merchant:4001/api/v2/cas/registerUser   -H "content-type: application/json"   -d '{
  "orgName":"merchant",
  "userName": "merchant",
  "adminName": "ica-merchant-admin"
}'
curl -s -X POST   http://admin-v2-merchant.merchant:4001/api/v2/channels/join   -H "content-type: application/json"   -d '{
  "orgName":"merchant",
  "peerIndex": "0",
  "channelName":"akcchannel",
  "ordererAddress": "orderer0-orderer.orderer:7050"
}'
```

## 10. Init or upgrade chaincode on operator cluster
- Install test chaincode on merchant cluster
```
curl --location --request POST http://admin-v2-merchant.merchant:4001/api/v2/chaincodes/packageCC \
--header 'content-type: application/json' \
--data-raw '{
  "orgName":"merchant",
  "chaincodePath":"/chaincodes/fabcar",
  "chaincodeName":"fabcar",
  "chaincodeVersion":"2",
  "chaincodeType":"golang",
  "peerIndex": "0"
}'
curl --location --request POST http://admin-v2-merchant.merchant:4001/api/v2/chaincodes/install \
--header 'content-type: application/json' \
--data-raw '{
  "chaincodeName":"fabcar",
  "chaincodePath":"fabcar.tar.gz",
  "target": "0 merchant"
}'

curl --location --request POST http://admin-v2-merchant.merchant:4001/api/v2/chaincodes/queryInstalled \
--header 'content-type: application/json' \
--data-raw '{
    "orgName":"merchant",
    "peerIndex": "0",
    "chaincodeName": "fabcar",
    "chaincodeVersion": "2"
}'
curl --location --request POST http://admin-v2-merchant.merchant:4001/api/v2/chaincodes/approveForMyOrg \
--header 'content-type: application/json' \
--data-raw '{
    "orgName":"merchant",
    "peerIndex": "0",
    "chaincodeName": "fabcar",
    "chaincodeVersion": 2,
    "channelName": "akcchannel",
    "packageId": "fabcar_2:dd2f978e3976a3df9812335447207907051b24e7315841ac922b5fd376e74cb8",
    "ordererAddress": "orderer0-orderer.orderer:7050"
}'
```
- Commit
```
curl --location --request POST http://admin-v2-merchant.merchant:4001/api/v2/chaincodes/commitChaincodeDefinition \
--header 'content-type: application/json' \
--data-raw '{
    "chaincodeName": "fabcar",
    "chaincodeVersion": 2,
    "channelName": "akcchannel",
    "target": "0 merchant 0 akc",
    "ordererAddress": "orderer0-orderer.orderer:7050"
}'
```
## 11. Copy tls cert of new org to other org
```
mkdir -p /tmp/artifact/cluster-mamba-example/akc-ca-data/crypto-config/merchant.merchant/peers/peer0-merchant.merchant/tls/tlsintermediatecerts/
cp /tmp/artifact/c-merchant/akc-ca-data/crypto-config/merchant.merchant/peers/peer0-merchant.merchant/tls/tlsintermediatecerts/tls-ica-merchant-merchant-7054.pem /tmp/artifact/cluster-mamba-example/akc-ca-data/crypto-config/merchant.merchant/peers/peer0-merchant.merchant/tls/tlsintermediatecerts/
```

## 12. Try invoke chaincode on merchant cluster:
```
curl -s -X POST   http://admin-rca-ica.default:4001/invokeChainCode   -H "content-type: application/json"   -d '{
  "orgName":"merchant",
  "channelName":"akcchannel",
  "chaincodeId":"fabcar",
  "args": ["CAR1", "a", "b", "c", "d"],
  "fcn": "createCar"
}'

curl -s -X POST   http://admin-rca-ica.akc:4001/invokeChainCode   -H "content-type: application/json"   -d '{
  "orgName":"akc",
  "channelName":"akcchannel",
  "chaincodeId":"fabcar",
  "args": ["CAR1", "a", "b", "c", "d"],
  "fcn": "createCar"
}'
```
