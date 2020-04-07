# Setup Amazon Elastic Kubernetes Cluster

## Prerequisites
We are going to setup an Amazon managed EKS cluster using [eksctl-The official CLI for Amazon EKS](https://eksctl.io/)

Please follow the guide [here](https://eksctl.io/introduction/installation/) to install eksctl. 

It is also recommended to have [AWS Command Line Interface](https://aws.amazon.com/cli/) (aws cli) installed. 

Please also make sure to configure AWS credentials for the app by adding these 2 files in `/home/user/.aws`

```
File /home/user/.aws/config
[default]
region=ap-southeast-1
output=json

File /home/user/.aws/credentials
[default]
aws_access_key_id=YOUR_AWS_ACCESS_KEY_ID_HERE
aws_secret_access_key=YOUR_AWS_ACCESS_KEY_HERE
```

## Create a new EKS cluster

#### 1. Generate SSH Keypair
Generate a SSH keypair for your EKS worker nodes. You will need it to ssh inside a node for debugging purpose later on. Then, upload the public key to AWS with

```
aws ec2 import-key-pair --key-name "workernode-cluster-mamba" --public-key-material file://~/.ssh/workernode-cluster-mamba.pub
```

Or just create a key pair `workernode-cluster-mamba` using AWS EC2 Keypairs UI.

#### 2. Create appropriate IAM service role
Using AWS Service / IAM / Access Management / Roles screen, we can add a new Role

TODO: Change this part to use AWS CLI 100%
```
Role: EKSServiceRoleTest
Select type of trusted entity: AWS service
Use case: EKS
Permissions:
    - AmazonEKSClusterPolicy
    - AmazonEKSServicePolicy
```

We will use AWS CLI 

```
aws iam create-policy --policy-name "ingressController-iam-policy" --policy-document file://./eks/policy/ingressController-iam-policy.json

aws iam create-policy --policy-name "k8s-asg-policy" --policy-document file://./eks/policy/k8s-asg-policy.json

aws iam create-policy --policy-name "WorkerNodesRolePoliciesEKS" --policy-document file://./eks/policy/WorkerNodesRolePoliciesEKS.json
```

#### 3. Modify cluster configuration
Modify `eks/eks-amzlinux` to update appropriate values. The file content is pretty much self-explained.

#### 4. Create cluster

```
eksctl create cluster -f ./eks/eks-amzlinux.yaml
```

Now your EKS cluster is up !!