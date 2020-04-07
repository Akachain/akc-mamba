# Setup Amazon Elastic File System

Hyperledger Fabric is a complex system with many components. Many of those share a lot of common files such as trusted certificates, chaincode package, configuration files, etc. For this reason, we choose to use a Network File System inside the cluster to store these common files.

The managed native network file system on AWS is Amazon Elastic File System (EFS). This guide shows necessary steps to setup an EFS instance for a Mamba cluster.

1. On AWS Console, choose service `EFS` and choose `Create file system`

2. Choose the same VPC with the EKS cluster

3. For each Availble Zone, choose the corresponding private subnet. For the `Security Groups`, find the one containing `ClusterSharedWorkerNode` in the name.

4. Add Name tag: `mamba-efs`

5. Fill the rest of the configuration based on your preference and company policies.