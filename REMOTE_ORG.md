## 1. Start network
```bash
mamba start
```
## 2. Prepare merchant config in '/home/hainq/.akachain/akc-mamba/mamba/config/merchant.env'
- In merchant env, must fill:
  - EXTERNAL_ORDERER_ADDRESSES, EXTERNAL_RCA_ADDRESSES
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
## 4. Copy merchant.json to operator cluster
```
cp /tmp/artifact/merchant-network/akc-ca-data/merchant.json /tmp/artifact/akc-network/akc-ca-data/
```
## 5. In operator cluster, add merchant to channel
Must specify env: NEW_ORG_NAME="merchant" in operator.env file
```
cp /home/hainq/.akachain/akc-mamba/mamba/config/operator.env /home/hainq/.akachain/akc-mamba/mamba/config/.env
mamba channel-config auto-update
```

## 6. Install chaincode test
```
curl -s -X POST   http://admin-rca-ica.akc:4001/chaincodes   -H "content-type: application/json"   -d '{
  "orgname":"akc",
  "chaincodeId":"fabcar",
  "chaincodePath":"chaincodes/fabcar/",
  "chaincodeVersion":"v1.0",
  "chaincodeType":"golang"
}'
```

## 7. Copy signed cert of orderer and akc org to merchant cluster
```
cp /tmp/artifact/akc-network/akc-ca-data/ica-orderer-ca-chain.pem /tmp/artifact/merchant-network/akc-ca-data/
cp /tmp/artifact/akc-network/akc-ca-data/ica-akc-ca-chain.pem /tmp/artifact/merchant-network/akc-ca-data/
```

## 8. Join merchant to channel
```
curl -s -X POST   http://admin-rca-ica.default:4001/registerUser   -H "content-type: application/json"   -d '{
  "orgname":"merchant"
}'
curl -s -X POST   http://admin-rca-ica.default:4001/joinchannel   -H "content-type: application/json"   -d '{
  "orgname":"merchant",
  "channelName":"akcchannel"
}'
curl -s -X POST   http://admin-rca-ica.default:4001/chaincodes   -H "content-type: application/json"   -d '{
  "orgname":"merchant",
  "chaincodeId":"fabcar",
  "chaincodePath":"chaincodes/fabcar/",
  "chaincodeVersion":"v1.0",
  "chaincodeType":"golang"
}'
```

## 9. Init or upgrade chaincode on operator cluster
- Init
```
curl -s -X POST   http://admin-rca-ica.akc:4001/initchaincodes   -H "content-type: application/json"   -d '{
  "orgname":"akc",
  "channelName":"akcchannel",
  "chaincodeId":"fabcar",
  "chaincodeVersion":"v1.0",
  "chaincodeType":"golang",
  "args":[]
}'
```
- Or upgrade if chaincode exists
```
curl -s -X POST   http://admin-rca-ica.ordererhai:4001/upgradeChainCode   -H "content-type: application/json"   -d '{
  "orgname":"akc",
  "channelName":"akcchannel",
  "chaincodeId":"fabcar",
  "chaincodeVersion":"v1.0",
  "chaincodeType":"golang",
  "args":[]
}'
```

## 10. Try invoke chaincode on merchant cluster:
```
curl -s -X POST   http://admin-rca-ica.default:4001/invokeChainCode   -H "content-type: application/json"   -d '{
  "orgname":"merchant",
  "channelName":"akcchannel",
  "chaincodeId":"fabcar",
  "args": ["CAR1", "a", "b", "c", "d"],
  "fcn": "createCar"
}'

curl -s -X POST   http://admin-rca-ica.akc:4001/invokeChainCode   -H "content-type: application/json"   -d '{
  "orgname":"akc",
  "channelName":"akcchannel",
  "chaincodeId":"fabcar",
  "args": ["CAR1", "a", "b", "c", "d"],
  "fcn": "createCar"
}'
```
