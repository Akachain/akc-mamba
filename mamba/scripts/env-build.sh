##--START REPLACE CONTENTS--##
# EKS Cluster information, include:
# 1) Cluster name,  for alb-ingress
# 2) Region for efs
# 3) Auto scaling group and size for cluster autoscaler
EKS_CLUSTER_NAME="cluster-example"
EKS_REGION="ap-southeast-1"
EKS_AUTO_SCALING_GROUP="eksctl-example-nodegroup-NodeGroup1-example-NodeGroup-XXXXXXX"
EKS_SCALING_SIZE="2:10"

# RootCA configuration
RCA_NAME="rca-akc"
RCA_ORG="akachain"

# EFS information
EFS_SERVER="fs-xxxxxxxx.efs.ap-southeast-1.amazonaws.com"
EFS_PATH="efs-pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
EFS_ROOT="/tmp/artifact/${EKS_CLUSTER_NAME}"
EFS_POD="test-efs-xxxxxxxxx-xxxxx"
EFS_EXTEND="${EKS_CLUSTER_NAME}"
EFS_SERVER_ID="fs-xxxxxxxx"