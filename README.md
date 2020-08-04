<img src="./mamba-text.png" alt="drawing" height="120"/>

AKC-Mamba provides a **production ready**, **complete** experience in deploying a Hyperledger Fabric blockchain Network on Kubernetes (K8S) Clusters.

In version 1.0, AKC-Mamba only supports Amazon EKS, we will gradually roll out support for native Kubernetes or other integrated Kubernetes Service Provider later on.

## 1. System Model
A complete Hyperledger Fabric 1.4 network consists 
- 1 Root CA (rca)
- 1 Intermediate CA for each organization (ica)
- 1 Kafka Based ordering service 
- A Pre-defined number of peer nodes for each organization.
- Bootstraping a sample chaincode in the network

Besides original Hyperledger Fabric, AKC-Mamba uses several inhouse developed tools to help a system administrator to accelerate his work. A list of pre-configured tools are:
- 1 AKC-Admin: administrative tool that expose REST API for Hyperledger Fabric network manipulation
- Hyperledger Fabric Blockchain Explorer
- Prometheus service
- Grafana service with a comprehensive dashboard to monitor the system.

## 2. Prerequisites

1. Follow our guide in [`eks/README.md`](eks/README.md) to setup an AWS EKS cluster.

1. Setup a Network File System following our guide in [`efs/guide.md`](efs/README.md)

1. Create a bastion host to access the VPC with the EKS cluster inside it following the instruction [here](https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html)

1. Install Python3 in the bastion host with
    ```
    sudo apt-get install python3
    ```

1. Make sure you have all necessary tools on your bastion host following this 
    - awscli - version 2 ([instruction](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html))
    - kubectl & aws-iam-authenticator ([instruction](https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html))
    
1. Config `awscli` with your user credentials 

1. Allow kubectl to connect to your EKS cluster by creating a `kube config` file following the instruction [here](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html)


## 3. Installation Guide 
Please follow the installation instruction [here](mamba/README.md)

## 4. License

AKC-Mamba project source code files are made available under MIT license, located in the LICENSE file. Basically, you can do whatever you want as long as you include the original copyright and license notice in any copy of the software/source.

