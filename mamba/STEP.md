## Update config
Chỉnh sửa config tại file config/operator.sh

## Chạy các command
1. Copy 'scripts' & 'chaincode test' folder to EFS
mamba copyscripts

2. Root Certificate Authority
mamba rca setup

3. Intermediate Certificate Authority
mamba ica setup

4. Register organizations
mamba reg-orgs setup

5. Register orderers
mamba reg-orderers setup

6. Register peers
mamba reg-peers setup

7. Enroll orderers
mamba enroll-orderers setup

8. Enroll peers
mamba enroll-peers setup

(Lưu ý: Bước này cần check job succeed rồi mới chạy bước updatefolder tiếp theo)

9. Update folder crypto-config in EFS
mamba updatefolder

10. Zookeeper & Kafka
mamba zookeeper setup

mamba kafka setup

11. Generate channel.tx, genesis.block
mamba channel-artifact setup

12. Deploy Orderer Service
mamba orderer setup

13. Deploy Peer Service
mamba peer setup

14. Generate application artifacts
mamba gen-artifact setup

15. Create Secret
mamba secret create

16. Run Admin Service
mamba admin setup

17. Bootstrap network: create channel, join channel, install fabcar chaincode, init fabcar chaincode
mamba bootstrap setup

### Delete all
k delete ns akachainhai
k delete ns kafkahai
k delete ns ordererhai
k delete ns mambatest

k exec -it test bash
rm -rf /tmp/artifact/cluster-operator-hai