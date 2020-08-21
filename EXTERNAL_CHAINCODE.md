## 1. BOOTSTRAP NETWORK
  You should start network by command: ```mamba start```
## 2. Packaging chaincode
### a. Using AKC-Admin
- Deploy akc-admin in repo: https://github.com/Akachain/akc-admin
- Call api package external chaincode:
    ```
    curl --location --request POST http://localhost:4001/api/v2/chaincodes/packageExternalCC \
    --header 'content-type: application/json' \
    --data-raw '{
        "orgname":"akc",
        "chaincodeName":"fabcar"
    }'
    ```
### b. Manual
- You should prepare files bellow:
- ```connection.json```: Connection to the external chaincode service:
    ```
    {
        "address": "chaincode-fabcar-org1.akc:7052",
        "dial_timeout": "10s",
        "tls_required": false,
        "client_auth_required": false,
        "client_key": "-----BEGIN EC PRIVATE KEY----- ... -----END EC PRIVATE KEY-----",
        "client_cert": "-----BEGIN CERTIFICATE----- ... -----END CERTIFICATE-----",
        "root_cert": "-----BEGIN CERTIFICATE---- ... -----END CERTIFICATE-----"
    }
    ``` 
- ```metadata.json```: Includes information of chaincode
    ```
    {"path":"","type":"external","label":"fabcar"}
    ```
  - Package: With the Fabric v2.0 chaincode lifecycle, chaincode is packaged and installed in a .tar.gz format.
    ```
    tar cfz code.tar.gz connection.json
    tar cfz fabcar.tgz code.tar.gz metadata.json
    ```
  
## 3. Building and deploying the External Chaincode
### a. Writing chaincode to run as an external service
- Write chaincode: See detail in [Hyperledger Fabric](https://hyperledger-fabric.readthedocs.io/en/release-2.2/cc_service.html#writing-chaincode-to-run-as-an-external-service)
- Build chaincode: Using docker to build chaincode to a image. Image tag used in ```Deploy chaincode``` step.
### b. Deploying the chaincode using AKC-Admin
- Install package: 
    ```
    curl --location --request POST http://localhost:4001/api/v2/chaincodes/install \
    --header 'content-type: application/json' \
    --data-raw '{
        "orgname":"akc",
        "chaincodeName":"fabcar",
        "chaincodePath":"fabcar.tgz",
        "peerIndex": "0"
    }'
    ```
- Query Package ID:
    ```
    curl --location --request POST http://localhost:4001/api/v2/chaincodes/queryInstalled \
    --header 'content-type: application/json' \
    --data-raw '{
        "orgname":"akc",
        "peerIndex": "0"
    }'
    ```
- Use package ID in previous step to deploy chaincode as stateful set in kubectl by using command bellow:
    ```
    mamba externalcc deploy --ccname fabcar --ccimage "$IMAGE_TAG" --packageid "$PACKAGE_ID"
    ```
- Approve the chaincode and commit it to the channel
    ```
    curl --location --request POST http://localhost:4001/api/v2/chaincodes/approveForMyOrg \
    --header 'content-type: application/json' \
    --data-raw '{
        "orgname":"akc",
        "peerIndex": "0",
        "chaincodeName": "fabcar",
        "chaincodeVersion": 1,
        "channelName": "akcchannel",
        "packageId": "fabcar:64abc178ac22334e3c30a42af36d688e83cbe9eb428a018a2def426ec3cfd5ea",
        "ordererAddress": "orderer0-orderer.akc:7050",
        "initRequired": 0
    }'

    curl --location --request POST http://localhost:4001/api/v2/chaincodes/commitChaincodeDefinition \
    --header 'content-type: application/json' \
    --data-raw '{
        "chaincodeName": "fabcar",
        "chaincodeVersion": 1,
        "channelName": "akctestchannel",
        "target": "0 akc",
        "ordererAddress": "orderer0-orderer.akc:7050",
        "initRequired": 0
    }'
    ```

- Invoke the chaincode
    ```
    curl --location --request POST http://localhost:4001/api/v2/chaincodes/invokeCLI \
    --header 'content-type: application/json' \
    --data-raw '{
        "chaincodeName": "fabcar",
        "channelName": "akcchannel",
        "target": "0 akc",
        "ordererAddress": "orderer0-orderer.akc:7050",
        "isInit": "0"
    }'

- Query the chaincode
    ```
    peer chaincode query -C akcchannel -n fabcar -c '{"Args":["queryAllCars"]}'
    ```