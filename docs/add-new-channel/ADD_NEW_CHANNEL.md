## 1. Add new channel information to network-config.yaml
    - Open network-config.yaml in efs: /tmp/artifact/cluster-akachain-common-production/admin/artifacts/network-config.yaml
    - In ```channels``` section, add config of the new channel
## 1. Create and apply job to create new channel.tx
Template:
```yaml template
---
apiVersion: batch/v1
kind: Job
metadata:
  namespace: default
  name: creategentx
spec:
  backoffLimit: 1
  template:
    metadata:
      name: creategentx
    spec:
      restartPolicy: "Never"
      volumes:
      - name: sharedvolume
        persistentVolumeClaim:
          claimName: efs
      - name: data
        nfs:
          server: {{EFS_SERVER}}
          path: /pvs/{{EFS_PATH}}/{{EFS_EXTEND}}/akc-ca-data
      containers:
      - name: creategentx
        image: hyperledger/fabric-tools:1.4.1
        command: 
        - /bin/sh 
        - -c 
        - |
          set -xe
          echo 'Cryptogen Starts';
          export FABRIC_CFG_PATH=/shared/{{EFS_EXTEND}}/akc-ca-data/;
          configtxgen -profile OrgsChannel -outputCreateChannelTx /shared/{{EFS_EXTEND}}/akc-ca-data/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME};
          #configtxgen -profile OrgsChannel -outputAnchorPeersUpdate /shared/VPID-PreProduct/akc-ca-data/${ORG_NAME}MSP-${CHANNEL_NAME}-anchors.tx -channelID ${CHANNEL_NAME} -asOrg ${ORG_NAME}MSP;
        env:
        - name: CHANNEL_NAME
          value: {{CHANNEL_NAME}}
        volumeMounts:
        - mountPath: /shared
          name: sharedvolume
        - mountPath: /data
          name: data

```
## 1. Call admin api to create and join new channel
```
curl -s -X POST http://admin-rca-ica.orderer:4001/channels -H "content-type: application/json"   -d '{
  "channelName":"newonemgchannel",
  "channelConfigPath":"../../../shared/newonemgchannel.tx",
  "orgname":"akc"
}'

curl -s -X POST http://admin-rca-ica.orderer:4001/joinchannel -H "content-type: application/json"   -d '{
  "orgname":"akc",
  "channelName":"newonemgchannel"
}'
```