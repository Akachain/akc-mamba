1. Start network
```
mamba -config='config/operator.env' --set-default
mamba start
```

2. Prepare merchant
```
mamba -config='config/merchant.env' --set-default
mamba copyscripts
```

3. Copy /tmp/artifact/cluster-operator-demo/akc-ca-data/rca-akc-cert.pem from operator cluster to merchant cluster: /tmp/artifact/cluster-merchant-demo/akc-ca-data/rca-akc-cert.pem
```
cp /tmp/artifact/cluster-example/akc-ca-data/rca-akc-cert.pem /tmp/artifact/cluster-merchant-example/akc-ca-data/
```

4. Setup external address orderer, rca

5. Create new org
```
mamba create-org
```
Output: ica, peer, admin, network-config, merchant.yaml, merchant.json
6. Copy merchant.json từ merchant cluster (/tmp/artifact/cluster-merchant-demo/akc-ca-data/merchant.json) sang operator cluster (/tmp/artifact/cluster-operator-demo/akc-ca-data/merchant.json)

```
cp /tmp/artifact/cluster-merchant-example/akc-ca-data/remotetest.json /tmp/artifact/cluster-example/akc-ca-data/
```
7. update config channel (support channel have 1 org)

```
mamba -config='config/operator.env' --set-default
mamba channel-config auto-update
```

8. Install test chaincode on operator cluster
```
curl -s -X POST   http://admin-rca-ica.ordererhai:4001/chaincodes   -H "content-type: application/json"   -d '{
  "orgname":"mambatest",
  "chaincodeId":"fabcar",
  "chaincodePath":"chaincodes/fabcar/",
  "chaincodeVersion":"v1.0",
  "chaincodeType":"golang"
}'
```

9. In merchant cluster:

- Copy ica-orderer-ca-chain.pem from operator (/tmp/artifact/cluster-operator-demo/akc-ca-data/ica-orderer-ca-chain.pem) to merchant cluster (same path)
```
cp /tmp/artifact/cluster-example/akc-ca-data/ica-orderer-ca-chain.pem /tmp/artifact/cluster-merchant-example/akc-ca-data/
```

Note:

If endorsement policy is all org, you must send tlsca cert between endorsement peers.
  Merchant send operator -> Operator edit network config
  Operator send merchant -> Merchant edit network config


- Copy tls of peer operator to merchant
```
cp /tmp/artifact/cluster-example/akc-ca-data/ica-mambatest-ca-chain.pem /tmp/artifact/cluster-merchant-example/akc-ca-data/
```

- Register new user for new org
```
curl -s -X POST   http://admin-rca-ica.default:4001/registerUser   -H "content-type: application/json"   -d '{
  "orgname":"remotetest"
}'
```

- Join channel
```
curl -s -X POST   http://admin-rca-ica.default:4001/joinchannel   -H "content-type: application/json"   -d '{
  "orgname":"remotetest",
  "channelName":"akctestchannel"
}'
```

- Install test chain code
```
curl -s -X POST   http://admin-rca-ica.default:4001/chaincodes   -H "content-type: application/json"   -d '{
  "orgname":"remotetest",
  "chaincodeId":"fabcar",
  "chaincodePath":"chaincodes/fabcar/",
  "chaincodeVersion":"v1.0",
  "chaincodeType":"golang"
}'
```



10. Init/Upgrade chaincode on Operator cluster
```

curl -s -X POST   http://admin-rca-ica.ordererhai:4001/initchaincodes   -H "content-type: application/json"   -d '{
  "orgname":"mambatest",
  "channelName":"akctestchannel",
  "chaincodeId":"fabcar",
  "chaincodeVersion":"v1.0",
  "chaincodeType":"golang",
  "args":[]
}'

curl -s -X POST   http://admin-rca-ica.ordererhai:4001/upgradeChainCode   -H "content-type: application/json"   -d '{
  "orgname":"mambatest",
  "channelName":"akctestchannel",
  "chaincodeId":"fabcar",
  "chaincodeVersion":"v1.0",
  "chaincodeType":"golang",
  "args":[]
}'
```

11. Try invoke chaincode on merchant cluster:
```
curl -s -X POST   http://admin-rca-ica.default:4001/invokeChainCode   -H "content-type: application/json"   -d '{
  "orgname":"remotetest",
  "channelName":"akctestchannel",
  "chaincodeId":"fabcar",
  "args": ["CAR1", "a", "b", "c", "d"],
  "fcn": "createCar"
}'
```