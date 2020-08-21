#!/bin/bash
# set -xe
## -- Global Variables section -- ##
GLOBAL_RETURN_CODE=$?
#RUN_MODE="operator"
# RUN_MODE="merchant"
# echo "RUN_MODE=${RUN_MODE}" > $(dirname "$0")/configuration.sh

# Setup cluster variables
source $(dirname "$0")/env.sh
source $(dirname "$0")/utilities.sh

# Print usage messages
function printHelp(){
  echo "Usage: "
  echo "  init.sh <component>"
  echo "    <component> - one of 'artifact', 'rca', 'ica', 'reg-org', 'reg-orderer', 'reg-peer', 'enroll-orderer', 'enroll-peer', 'update-folder', 'zookeeper', 'kafka', 'channel-artifact', 'orderer', 'peer', 'admin', 'clean'"
  echo ""
  echo "      - 'environment'          - Setup environment for cluster"
  echo "      - 'environmentBuild'          - Setup environmentBuild for cluster"
  echo "      - 'artifact'             - copy artifacts to EFS"
  echo "      - 'rca'                  - create a new Root Certificate Authority service,"
  echo "        'del-rca'              - delete the Root Certificate Authority service"
  echo "      - 'ica'                  - create new Intermediate Certificate Authority services"
  echo "        'del-ica'              - delete the Intermediate Certificate Authority services"
  echo "      - 'reg-org'              - run jobs to register organizations"
  echo "        'del-reg-org'          - delete organization registration jobs"
  echo "      - 'reg-orderer'          - run jobs to register orderers"
  echo "        'del-reg-orderer'      - delete orderer registration jobs"
  echo "      - 'reg-peer'             - run jobs to register peers"
  echo "        'del-reg-peer'         - delete peer registration jobs"
  echo "      - 'enroll-orderer'       - run jobs to enroll orderers"
  echo "        'del-enroll-orderer'   - delete orderer enrollment jobs"
  echo "      - 'enroll-peer'          - run jobs to enroll peers"
  echo "        'del-enroll-peer'      - delete peer enrollment jobs"
  echo "      - 'update-folder'        - create crypto-config folder to contains artifacts"
  echo "      - 'zookeeper'            - create new Zookeeper services"
  echo "        'del-zookeeper'        - delete the Zookeeper services"
  echo "      - 'kafka'                - create new Kafka services"
  echo "        'del-kafka'            - delete the Kafka services"
  echo "      - 'channel-artifact'     - run job to generate channel.tx, genesis.block"
  echo "        'del-channel-artifact' - delete the channel-artifact job"
  echo "      - 'orderer'              - create new StatefullSet orderers"
  echo "        'del-kafka'            - delete the StatefullSet orderers"
  echo "      - 'peer'                 - create new StatefullSet peers"
  echo "        'del-peer'             - delete the StatefullSet peers"
  echo "      - 'gen-artifacts'        - run jobs to generate application artifacts"
  echo "        'del-gen-artifacts'    - delete jobs to generate application artifacts"
  echo "      - 'admin'                - create new a new Admin service"
  echo "        'del-admin'            - delete the Admin service"
  echo "      - 'bootstrap'            - bootstrap network"
  echo "        'del-bootstrap'        - delete bootstrap job"
  echo "      - 'stop'                 - stop all pods and services, jobs, statefulSet"
  echo "      - 'terminate'            - stop all pods and services, jobs, statefulSet & pvc"
  echo "  init.sh -h (print this message)"
}

## -- Environment section -- ##
function podPending {
  PODSPENDING=$(kubectl get pods --namespace=$1 | awk '{ if ($3!="Completed") print $2}' | grep 0 | wc -l | awk '{print $1}')
  while [ "${PODSPENDING}" != "0" ];
  do
    printf -- "\e[2m  Waiting on Pod to deploy in namespace $1. Pods pending = ${PODSPENDING} \033[0m\033"
    PODSPENDING=$(kubectl get pods --namespace=$1 | awk '{ if ($3!="Completed") print $2}' | grep 0 | wc -l | awk '{print $1}')
    sleep 9 2>/dev/null &
    spinner
  done
  printf -- '\033[32m DONE. \033[0m\n';
}

function jobPending {
  JOBSPENDING=$(kubectl get jobs.batch -n $1 | awk '{print $2}' | grep 0 | wc -l | awk '{print $1}')
  while [ "${JOBSPENDING}" != "0" ];
  do
    printf -- "\e[2m  Waiting on Job to complete in namespace $1. Jobs pending = ${JOBSPENDING} \033[0m\033"
    JOBSPENDING=$(kubectl get jobs.batch -n $1 | awk '{print $2}' | grep 0 | wc -l | awk '{print $1}')
    sleep 9 2>/dev/null &
    spinner
  done
  printf -- '\033[32m DONE. \033[0m\n';
}

function environmentBuild {
  helmInstall
  ebsEncryption
  efs
}

function environment {
  helmInstall
  autoscaler
  ebsEncryption
  efs
  ingress
  metrics
}

function helmInstall {
  # Get helm latest version
  echo -e 'Installing helm:'
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > ./k8s/helm/0get_helm.sh
  chmod +x ./k8s/helm/0get_helm.sh
  ./k8s/helm/0get_helm.sh
  kubectl apply -f ./k8s/helm/1rbac.yaml
  ./k8s/helm/2install_helm.sh
  # Check install process
  podPending kube-system
  echo -e '\nInstall helm success'
}

function ebsEncryption {
  echo -e 'Installing EBS encryption'
  kubectl apply -f ./k8s/ebs-encryption/0gp2-encryption.yaml;
  local SC_PENDING=$(kubectl get sc gp2-encryption | awk '{print $2}' | grep default | wc -l)
  while [ "${SC_PENDING}" != "1" ];
  do
    ./k8s/ebs-encryption/1set_default_sc.sh
    echo -e 'Making gp2-encryption to default storage class'
    SC_PENDING=$(kubectl get sc gp2-encryption | awk '{print $2}' | grep default | wc -l)
    sleep 10
  done
  echo -e 'gp2-encryption is default storage class'
}

function metrics {
  echo -e 'Checking metrics install or not'
  METRICS=$(helm ls metrics-server | grep 'DEPLOYED' | wc -l)
  if [ ${METRICS} == "1" ]
  then
    echo -e 'Metrics installed, upgrade metrics to the latest version'
    ./k8s/metrics/upgrade_metrics.sh
  else
    echo -e 'Installing metric: '
    ./k8s/metrics/install_metrics.sh
  fi
  podPending metrics
  echo -e 'Install metric server success'
}

function ingress {
  echo -e 'Installing ALB-Ingress: '
  kubectl apply -f ./k8s/ingress/0clusterRole.yaml;
  ingress=`cat "./k8s/ingress/1alb-ingress-controller.yaml" | sed \
      -e "s/{{EKS_CLUSTER_NAME}}/$EKS_CLUSTER_NAME/g"`
  echo "$ingress" | kubectl apply -f -
  podPending kube-system
  echo -e 'Installed ALB-Ingress'
}

function efs {
  echo -e 'Checking EFS install or not'
  local EFS=$(helm ls efs | grep 'DEPLOYED' | wc -l)
  if [ $EFS == "1" ]
  then
    echo -e 'EFS installed, upgrade EFS to the latest version'
    ./k8s/efs/upgrade_efs.sh $EFS_SERVER_ID $EKS_REGION
  else
    echo -e 'Installing EFS: '
    ./k8s/efs/install_efs.sh $EFS_SERVER_ID $EKS_REGION
  fi
  podPending default
  echo -e 'EFS install success'
  echo -e 'Created EFS PVC'
  kubectl apply -f ./k8s/efs/pvc-efs.yaml
  local PVC=$(kubectl get pvc efs | awk '{print $2}' | grep Bound | wc -l)
  while [ "${PVC}" != "1" ];
  do
    echo -e 'Creating EFS PVC'
    local PVC=$(kubectl get pvc efs | awk '{print $2}' | grep Bound | wc -l)
  done
  #Search and replace default efs-path value in env.sh
  EFS_PVC=efs-$(kubectl get pvc | grep efs | awk '{print $3}')
  echo $EFS_PVC
  sed -i -e 's/efs-pvc-.*[^"]/'"$EFS_PVC"'/g' $(dirname "$0")/env-${RUN_MODE}.sh
  echo -e 'Create EFS Pod'
  kubectl apply -f ./k8s/efs/test-efs.yaml
  podPending default
  echo -e 'EFS Pod created'
  #Search and replace default test-efs value in env.sh
  EFS_POD=$(kubectl get pod -n default | grep test-efs | awk '{print $1}')
  sed -i -e 's/test-efs-.*[^"]/'"$EFS_POD"'/g' $(dirname "$0")/env-${RUN_MODE}.sh
  source $(dirname "$0")/env-${RUN_MODE}.sh
}

function autoscaler {
  # Edit autoscaler template
  echo -e "Installing cluster autoscaler:"
  autoscaler=`cat "./k8s/autoscaler/cluster_autoscaler.yml" | sed \
      -e "s/{{EKS_SCALING_SIZE}}/$EKS_SCALING_SIZE/g"\
      -e "s/{{EKS1_SCALING_SIZE}}/$EKS1_SCALING_SIZE/g"\
      -e "s/{{EKS_AUTO_SCALING_GROUP}}/$EKS_AUTO_SCALING_GROUP/g"\
      -e "s/{{EKS1_AUTO_SCALING_GROUP}}/$EKS1_AUTO_SCALING_GROUP/g"\
      -e "s/{{EKS_REGION}}/$EKS_REGION/g"`
  echo "$autoscaler" | kubectl apply -f -
  podPending kube-system
  echo -e "\nInstall autoscaler success"
}

# Create new namespace
function createNamespace {
  local namespaces=`cat "./namespaces.yaml" | sed "s/{{NAMESPACES}}/$1/g"`
  echo "$namespaces" | kubectl apply -f -
  return 0
}

# Setup a fresh new RCA pod
# WARNING: This is just an experimental feature without considering security options, do NOT use this option in production.
# TODO: optional mod to connect to an external RCA through vpn
function setupRCA {
  # Create new namespace
  createNamespace $RCA_DOMAIN

  # Edit deployment information
  rca=`cat "./k8s/rca/fabric-deployment-rca-akc.yaml" | sed \
      -e "s/{{ORG}}/$RCA_DOMAIN/g"\
      -e "s/{{RCA_NAME}}/$RCA_NAME/g"\
      -e "s/{{FABRIC_ORGS}}/$ORGS/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`
  #echo "$rca"
  echo "$rca" | kubectl apply -f -
  return 0
}
function deleteRCA {
  # Create new namespace
  createNamespace $RCA_DOMAIN

  # Edit deployment information
  rca=`cat "./k8s/rca/fabric-deployment-rca-akc.yaml" | sed \
      -e "s/{{ORG}}/$RCA_DOMAIN/g"\
      -e "s/{{RCA_NAME}}/$RCA_NAME/g"\
      -e "s/{{FABRIC_ORGS}}/$ORGS/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$rca"
  echo "$rca" | kubectl delete -f -
  return 0
}

function terminateRCA {
  # Delete RCA pod and service
  deleteRCA
  local pvc=`kubectl get pvc -n  ${RCA_DOMAIN} | grep "rca" | awk '{print $1}'`
  if [ ! -z "$pvc" ];
  then
    kubectl delete pvc -n ${RCA_DOMAIN} $pvc
  fi
}

# Setup intermediate CA for independent organization
function setupICA {
  # Create new namespace
  local ICA_ORG="$1"
  getDomain $ICA_ORG
  local ICA_NAME="ica-${ICA_ORG}"
  createNamespace $DOMAIN

  # Edit deployment information
  ica=`cat "./k8s/ica/fabric-deployment-ica.yaml" | sed \
      -e "s/{{ORG}}/$ICA_ORG/g"\
      -e "s/{{ICA_NAME}}/$ICA_NAME/g"\
      -e "s/{{ICA_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{RCA_NAME}}/$RCA_NAME/g"\
      -e "s/{{RCA_HOST}}/$RCA_NAME.$RCA_DOMAIN/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$ica"
  echo "$ica" | kubectl apply -f -
  return 0
}
function deleteICA {
  # Create new namespace
  local ICA_ORG="$1"
  getDomain $ICA_ORG
  local ICA_NAME="ica-${ICA_ORG}"
  createNamespace $DOMAIN

  # Edit deployment information
  ica=`cat "./k8s/ica/fabric-deployment-ica.yaml" | sed \
      -e "s/{{ORG}}/$ICA_ORG/g"\
      -e "s/{{ICA_NAME}}/$ICA_NAME/g"\
      -e "s/{{ICA_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{RCA_NAME}}/$RCA_NAME/g"\
      -e "s/{{RCA_HOST}}/$RCA_NAME.$RCA_DOMAIN/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$ica"
  echo "$ica" | kubectl delete -f -
  return 0
}

function setupICAex {
  # Create new namespace
  local ICA_ORG="$1"
  getDomain $ICA_ORG
  local ICA_NAME="ica-${ICA_ORG}"
  createNamespace $DOMAIN

  # Edit deployment information
  ica=`cat "./k8s/ica-ex/fabric-deployment-ica.yaml" | sed \
      -e "s/{{ORG}}/$ICA_ORG/g"\
      -e "s/{{ICA_NAME}}/$ICA_NAME/g"\
      -e "s/{{ICA_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{RCA_NAME}}/$RCA_NAME/g"\
      -e "s/{{EXTERNAL_RCA_ADDRESSES}}/$EXTERNAL_RCA_ADDRESSES/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$ica"
  echo "$ica" | kubectl apply -f -
  return 0
}
function deleteICAex {
  # Create new namespace
  local ICA_ORG="$1"
  getDomain $ICA_ORG
  local ICA_NAME="ica-${ICA_ORG}"
  createNamespace $DOMAIN

  # Edit deployment information
  ica=`cat "./k8s/ica-ex/fabric-deployment-ica.yaml" | sed \
      -e "s/{{ORG}}/$ICA_ORG/g"\
      -e "s/{{ICA_NAME}}/$ICA_NAME/g"\
      -e "s/{{ICA_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{RCA_NAME}}/$RCA_NAME/g"\
      -e "s/{{EXTERNAL_RCA_ADDRESSES}}/$EXTERNAL_RCA_ADDRESSES/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$ica"
  echo "$ica" | kubectl delete -f -
  return 0
}

function terminateICA {
  # Delete ICA pod and service
  local ICA_ORG="$1"
  deleteICA $ICA_ORG
  getDomain $ICA_ORG
  local pvc=`kubectl get pvc -n  ${DOMAIN} | grep "ica" | awk '{print $1}'`
  if [ ! -z "$pvc" ];
  then
    kubectl delete pvc -n ${DOMAIN} $pvc
  fi
}

function terminateICAex {
  # Delete ICA pod and service
  local ICA_ORG="$1"
  deleteICAex $ICA_ORG
  getDomain $ICA_ORG
  local pvc=`kubectl get pvc -n  ${DOMAIN} | grep "ica" | awk '{print $1}'`
  if [ ! -z "$pvc" ];
  then
    kubectl delete pvc -n ${DOMAIN} $pvc
  fi
}

# Copy relevant artifacts to EFS so it is accessible by other pods
function copyArtifact {
  # scripts
  kubectl exec -i $EFS_POD -- bash -c "mkdir -p $EFS_ROOT/admin"
  kubectl exec -i $EFS_POD -- bash -c "mkdir -p $EFS_ROOT/akc-ca-data"
  kubectl cp scripts-old/. $EFS_POD:$EFS_ROOT/akc-ca-scripts/
  kubectl cp scripts/. $EFS_POD:$EFS_ROOT/akc-ca-scripts/
  kubectl exec -i $EFS_POD -- bash -c "mv $EFS_ROOT/akc-ca-scripts/akc-ca-scripts/*.sh $EFS_ROOT/akc-ca-scripts/"
  kubectl exec -i $EFS_POD -- bash -c "rm -rf $EFS_ROOT/akc-ca-scripts/akc-ca-scripts"
  kubectl cp artifacts/. $EFS_POD:$EFS_ROOT/admin/artifacts
  # kubectl cp data/. $EFS_POD:$EFS_ROOT/akc-ca-data/
}

# After creating appropriate certificate authorities, we now need to create organization
# certificates by enrolling them to the corresponding intermediate CA.
function registerOrganizations {

  local REG_ORG="$1"
  getDomain $REG_ORG
  # echo $DOMAIN

  # Edit deployment information
  reg=`cat "./k8s/register-org/fabric-deployment-register-org.yaml" | sed \
      -e "s/{{ORG}}/$REG_ORG/g"\
      -e "s/{{REG_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl apply -f -
  return 0
}
function deleteOrgRegistrations {

  local REG_ORG="$1"
  getDomain $REG_ORG

  # Edit deployment information
  reg=`cat "./k8s/register-org/fabric-deployment-register-org.yaml" | sed \
      -e "s/{{ORG}}/$REG_ORG/g"\
      -e "s/{{REG_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl delete -f -
  return 0
}

# After creating appropriate certificate authorities, we now need to create organization
# certificates by enrolling them to the corresponding intermediate CA.
function registerOrderer {

  local ORDERER_ORG="$1"
  getDomain $ORDERER_ORG

  # Edit deployment information
  reg=`cat "./k8s/register-orderer/fabric-deployment-register-orderer.yaml" | sed \
      -e "s/{{ORDERER_ORG}}/$ORDERER_ORG/g"\
      -e "s/{{ORDERER_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl apply -f -
  return 0
}
function deleteOrdererRegistration {

  local ORDERER_ORG="$1"
  getDomain $ORDERER_ORG

  # Edit deployment information
  reg=`cat "./k8s/register-orderer/fabric-deployment-register-orderer.yaml" | sed \
      -e "s/{{ORDERER_ORG}}/$ORDERER_ORG/g"\
      -e "s/{{ORDERER_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl delete -f -
  return 0
}

# After creating appropriate certificate authorities, we now need to create organization
# certificates by enrolling them to the corresponding intermediate CA.
function registerPeer {

  local PEER_ORG="$1"
  getDomain $PEER_ORG
  echo $DOMAIN

  # Edit deployment information
  reg=`cat "./k8s/register-peer/fabric-deployment-register-peer.yaml" | sed \
      -e "s/{{PEER_ORG}}/$PEER_ORG/g"\
      -e "s/{{PEER_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl apply -f -
  return 0
}
function deletePeerRegistration {

  local PEER_ORG="$1"
  getDomain $PEER_ORG

  # Edit deployment information
  reg=`cat "./k8s/register-peer/fabric-deployment-register-peer.yaml" | sed \
      -e "s/{{PEER_ORG}}/$PEER_ORG/g"\
      -e "s/{{PEER_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl delete -f -
  return 0
}

# After creating appropriate certificate authorities, we now need to create organization
# certificates by enrolling them to the corresponding intermediate CA.
function enrollOrderer {

  local ENROLL_ORDERER="$1"
  getDomain $ENROLL_ORDERER

  # Edit deployment information
  reg=`cat "./k8s/enroll-orderer/fabric-deployment-enroll-orderer.yaml" | sed \
      -e "s/{{ORDERER}}/$ENROLL_ORDERER/g"\
      -e "s/{{ENROLL_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl apply -f -
  return 0
}
function deleteOrdererEnrollment {

  local ENROLL_ORDERER="$1"
  getDomain $ENROLL_ORDERER

  # Edit deployment information
  reg=`cat "./k8s/enroll-orderer/fabric-deployment-enroll-orderer.yaml" | sed \
      -e "s/{{ORDERER}}/$ENROLL_ORDERER/g"\
      -e "s/{{ENROLL_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl delete -f -
  return 0
}

# After creating appropriate certificate authorities, we now need to create organization
# certificates by enrolling them to the corresponding intermediate CA.
function enrollPeer {

  local ENROLL_PEER="$1"
  local PEER_INDEX="$2"
  getDomain $ENROLL_PEER
  getOrgExternalAddress $ENROLL_PEER $PEER_INDEX

  # Edit deployment information
  reg=`cat "./k8s/enroll-peer/fabric-deployment-enroll-peer.yaml" | sed \
      -e "s/{{PEER}}/$ENROLL_PEER/g"\
      -e "s/{{ENROLL_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{PEER_INDEX}}/$PEER_INDEX/g"\
      -e "s/{{EXTERNAL_PEER_HOST}}/$EXTERNAL_PEER_HOST/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl apply -f -
  return 0
}
function deletePeerEnrollment {

  local ENROLL_PEER="$1"
  local PEER_INDEX="$2"
  getDomain $ENROLL_PEER
  getOrgExternalAddress $ENROLL_PEER $PEER_INDEX

  # Edit deployment information
  reg=`cat "./k8s/enroll-peer/fabric-deployment-enroll-peer.yaml" | sed \
      -e "s/{{PEER}}/$ENROLL_PEER/g"\
      -e "s/{{ENROLL_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{PEER_INDEX}}/$PEER_INDEX/g"\
      -e "s/{{EXTERNAL_PEER_HOST}}/$EXTERNAL_PEER_HOST/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl delete -f -
  return 0
}

# After creating appropriate certificate authorities, we now need to create organization
# certificates by enrolling them to the corresponding intermediate CA.
function updateFolder {
  # scripts
  # delete old file ./scripts/updateFolder.sh to create new one
  rm -rf ./scripts/updateFolder.sh

  # Edit script to copy artifacts of orderers
  # Pass params: orderer index
  for (( ORDERER_INDEX=1; ORDERER_INDEX<=$NUM_ORDERERS; ORDERER_INDEX++ ));
  do
    update=`cat "./scripts/updateOrdererFolder.sh" | sed \
        -e "s/{{ORDERER}}/$ORDERER_ORGS/g" \
        -e "s/{{ORDERER_DOMAIN}}/$ORDERER_DOMAINS/g" \
        -e "s/{{ORDERER_INDEX}}/$ORDERER_INDEX/g"`
    echo "$update" >> ./scripts/updateFolder.sh
  done

  # Edit script to copy artifacts of peers
  # Pass params: peer org name, number of peers in each org
  for PEER_ORG in $PEER_ORGS
  do
    getDomain $PEER_ORG
    update=`cat "./scripts/updatePeerFolder.sh" | sed \
        -e "s/{{PEER_ORG}}/$PEER_ORG/g"\
        -e "s/{{PEER_DOMAIN}}/$DOMAIN/g"\
        -e "s/{{NUM_PEERS}}/$NUM_PEERS/g"`
    echo "$update" >> ./scripts/updateFolder.sh
  done

  kubectl cp ./scripts/updateFolder.sh $EFS_POD:$EFS_ROOT/akc-ca-data/
  kubectl exec -i $EFS_POD -- bash -c "rm -rf $EFS_ROOT/akc-ca-data/crypto-config"
  kubectl exec -i $EFS_POD -- bash -c "chmod 755 $EFS_ROOT/akc-ca-data/updateFolder.sh"
  kubectl exec -i $EFS_POD -- bash -c "cd $EFS_ROOT/akc-ca-data/ && ./updateFolder.sh"
}

# After creating appropriate certificate authorities, we now need to create organization
# certificates by enrolling them to the corresponding intermediate CA.
function zookeeper {
  createNamespace $KAFKA_NAMESPACE

  # Edit deployment information
  zoo0=`cat "./k8s/zookeeper/0zk-cs.yaml" | sed \
      -e "s/{{KAFKA_NAMESPACE}}/$KAFKA_NAMESPACE/g"`
  echo "$zoo0" | kubectl apply -f -

  zoo1=`cat "./k8s/zookeeper/1zk-hs.yaml" | sed \
      -e "s/{{KAFKA_NAMESPACE}}/$KAFKA_NAMESPACE/g"`
  echo "$zoo1" | kubectl apply -f -

  zoo2=`cat "./k8s/zookeeper/2zk-set.yaml" | sed \
      -e "s/{{KAFKA_NAMESPACE}}/$KAFKA_NAMESPACE/g"`
  echo "$zoo2" | kubectl apply -f -
  return 0
}
function deleteZookeeper {

  # Edit deployment information
  zoo0=`cat "./k8s/zookeeper/0zk-cs.yaml" | sed \
      -e "s/{{KAFKA_NAMESPACE}}/$KAFKA_NAMESPACE/g"`
  echo "$zoo0" | kubectl delete -f -

  zoo1=`cat "./k8s/zookeeper/1zk-hs.yaml" | sed \
      -e "s/{{KAFKA_NAMESPACE}}/$KAFKA_NAMESPACE/g"`
  echo "$zoo1" | kubectl delete -f -

  zoo2=`cat "./k8s/zookeeper/2zk-set.yaml" | sed \
      -e "s/{{KAFKA_NAMESPACE}}/$KAFKA_NAMESPACE/g"`
  echo "$zoo2" | kubectl delete -f -
  return 0
}

function terminateZookeeper {
  # Delete zoo pod and service
  deleteZookeeper
  # delete pvc
  local pvc=`kubectl get pvc -n  ${KAFKA_NAMESPACE} | grep "zoo" | awk '{print $1}'`
  if [ ! -z "$pvc" ];
  then
    kubectl delete pvc -n ${KAFKA_NAMESPACE} $pvc
  fi
}

# After creating appropriate certificate authorities, we now need to create organization
# certificates by enrolling them to the corresponding intermediate CA.
function kafka {
  createNamespace $KAFKA_NAMESPACE

  # Edit deployment information
  kafka0=`cat "./k8s/kafka/0kafka-hs.yaml" | sed \
      -e "s/{{KAFKA_NAMESPACE}}/$KAFKA_NAMESPACE/g"`
  echo "$kafka0" | kubectl apply -f -

  kafka1=`cat "./k8s/kafka/1kafka-cs.yaml" | sed \
      -e "s/{{KAFKA_NAMESPACE}}/$KAFKA_NAMESPACE/g"`
  echo "$kafka1" | kubectl apply -f -

  kafka2=`cat "./k8s/kafka/2kafka-set.yaml" | sed \
      -e "s/{{KAFKA_NAMESPACE}}/$KAFKA_NAMESPACE/g"`
  echo "$kafka2" | kubectl apply -f -

  return 0
}

function deleteKafka {
  # Edit deployment information
  kafka0=`cat "./k8s/kafka/0kafka-hs.yaml" | sed \
      -e "s/{{KAFKA_NAMESPACE}}/$KAFKA_NAMESPACE/g"`
  echo "$kafka0" | kubectl delete -f -

  kafka1=`cat "./k8s/kafka/1kafka-cs.yaml" | sed \
      -e "s/{{KAFKA_NAMESPACE}}/$KAFKA_NAMESPACE/g"`
  echo "$kafka1" | kubectl delete -f -

  kafka2=`cat "./k8s/kafka/2kafka-set.yaml" | sed \
      -e "s/{{KAFKA_NAMESPACE}}/$KAFKA_NAMESPACE/g"`
  echo "$kafka2" | kubectl delete -f -
  return 0
}

function terminateKafka {
  # Delete zoo pod and service
  deleteKafka
  # delete pvc
  local pvc=`kubectl get pvc -n  ${KAFKA_NAMESPACE} | grep "kafka" | awk '{print $1}'`
  if [ ! -z "$pvc" ];
  then
    kubectl delete pvc -n ${KAFKA_NAMESPACE} $pvc
  fi
}

# After creating appropriate certificate authorities, we now need to create organization
# certificates by enrolling them to the corresponding intermediate CA.
function createChannelArtifact {
  # Edit deployment information
  reg=`cat "./k8s/channel-artifacts/fabric-deployment-channel-artifacts.yaml" | sed \
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ORDERER_DOMAINS/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl apply -f -
  return 0
}
function deleteChannelArtifact {
  # Edit deployment information
  reg=`cat "./k8s/channel-artifacts/fabric-deployment-channel-artifacts.yaml" | sed \
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ORDERER_DOMAINS/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl delete -f -
  return 0
}

# After creating appropriate certificate authorities, we now need to create organization
# certificates by enrolling them to the corresponding intermediate CA.
function stsOrderer {

  local ORDERER="$1"
  local ORDERER_INDEX="$2"

  # Edit deployment information
  reg=`cat "./k8s/orderer-sts/orderer-service.yaml" | sed \
      -e "s/{{ORDERER}}/$ORDERER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ORDERER_DOMAINS/g"\
      -e "s/{{ORDERER_INDEX}}/$ORDERER_INDEX/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl apply -f -

   # Edit deployment information
  reg=`cat "./k8s/orderer-sts/orderer-stateful.yaml" | sed \
      -e "s/{{ORDERER}}/$ORDERER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ORDERER_DOMAINS/g"\
      -e "s/{{ORDERER_INDEX}}/$ORDERER_INDEX/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl apply -f -

  # Edit nlb deployment information
  reg=`cat "./k8s/orderer-sts/orderer-service-nlb.yaml" | sed \
      -e "s/{{ORDERER}}/$ORDERER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ORDERER_DOMAINS/g"\
      -e "s/{{ORDERER_INDEX}}/$ORDERER_INDEX/g"`

  #echo "$reg"
  echo "$reg" | kubectl apply -f -
  return 0
}
function deleteStsOrderer {

  local ORDERER="$1"
  local ORDERER_INDEX="$2"

  # Edit deployment information
  reg=`cat "./k8s/orderer-sts/orderer-service.yaml" | sed \
      -e "s/{{ORDERER}}/$ORDERER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ORDERER_DOMAINS/g"\
      -e "s/{{ORDERER_INDEX}}/$ORDERER_INDEX/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl delete -f -

   # Edit deployment information
  reg=`cat "./k8s/orderer-sts/orderer-stateful.yaml" | sed \
      -e "s/{{ORDERER}}/$ORDERER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ORDERER_DOMAINS/g"\
      -e "s/{{ORDERER_INDEX}}/$ORDERER_INDEX/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  #echo "$reg"
  echo "$reg" | kubectl delete -f -
  return 0
}

function terminateOrderer {
  # Delete ICA pod and service
  local ORDERER="$1"
  local ORDERER_INDEX="$2"
  deleteStsOrderer $ORDERER $ORDERER_INDEX
  local pvc=`kubectl get pvc -n  ${ORDERER_DOMAINS} | grep "orderer$ORDERER_INDEX-$ORDERER" | awk '{print $1}'`
  if [ ! -z "$pvc" ];
  then
    kubectl delete pvc -n ${ORDERER_DOMAINS} $pvc
  fi
}

# After creating appropriate certificate authorities, we now need to create organization
# certificates by enrolling them to the corresponding intermediate CA.
function stsPeer {

  local PEER_ORG="$1"
  local PEER_INDEX="$2"
  getDomain $PEER_ORG

  # Edit deployment information
  reg=`cat "./k8s/peer-sts/peer-service-stateful.yaml" | sed \
      -e "s/{{PEER_ORG}}/$PEER_ORG/g"\
      -e "s/{{PEER_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{PEER_INDEX}}/$PEER_INDEX/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl apply -f -

  # # Edit deployment information
  # reg=`cat "./k8s/peer-sts/peer-service-nlb.yaml" | sed \
  #     -e "s/{{PEER_ORG}}/$PEER_ORG/g"\
  #     -e "s/{{PEER_DOMAIN}}/$DOMAIN/g"\
  #     -e "s/{{PEER_INDEX}}/$PEER_INDEX/g"\
  #     -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
  #     -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
  #     -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  # echo "$reg" | kubectl apply -f -

  # Edit deployment information
  reg=`cat "./k8s/peer-sts/peer-stateful.yaml" | sed \
      -e "s/{{PEER_ORG}}/$PEER_ORG/g"\
      -e "s/{{PEER_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{PEER_INDEX}}/$PEER_INDEX/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl apply -f -
  return 0
}
function deleteStsPeer {

  local PEER_ORG="$1"
  local PEER_INDEX="$2"
  getDomain $PEER_ORG

  # Edit deployment information
  reg=`cat "./k8s/peer-sts/peer-service-stateful.yaml" | sed \
      -e "s/{{PEER_ORG}}/$PEER_ORG/g"\
      -e "s/{{PEER_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{PEER_INDEX}}/$PEER_INDEX/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl delete -f -

  # Edit deployment information
  reg=`cat "./k8s/peer-sts/peer-stateful.yaml" | sed \
      -e "s/{{PEER_ORG}}/$PEER_ORG/g"\
      -e "s/{{PEER_DOMAIN}}/$DOMAIN/g"\
      -e "s/{{PEER_INDEX}}/$PEER_INDEX/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl delete -f -
  return 0
}

function terminatePeer {
  # Delete ICA pod and service
  local PEER_ORG="$1"
  local PEER_INDEX="$2"
  getDomain $PEER_ORG
  deleteStsPeer $PEER_ORG $PEER_INDEX
  local pvcPeer=`kubectl get pvc -n  ${DOMAIN} | grep "peer$PEER_INDEX-pvc-$DOMAIN" | awk '{print $1}'`
  if [ ! -z "$pvcPeer" ];
  then
    kubectl delete pvc -n ${DOMAIN} $pvcPeer
  fi

  local pvcCouchdb=`kubectl get pvc -n  ${DOMAIN} | grep "couch$PEER_INDEX-pvc-$DOMAIN" | awk '{print $1}'`
  if [ ! -z "$pvcCouchdb" ];
  then
    kubectl delete pvc -n ${DOMAIN} $pvcCouchdb
  fi
}

function genArtifacts {
  # Edit deployment information
  reg=`cat "./k8s/gen-artifacts/fabric-deployment-gen-artifacts.yaml" | sed \
      -e "s/{{ORDERER_DOMAIN}}/$ORDERER_DOMAINS/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl apply -f -
}

function deleteGenArtifacts {
  # Edit deployment information
  reg=`cat "./k8s/gen-artifacts/fabric-deployment-gen-artifacts.yaml" | sed \
      -e "s/{{ORDERER_DOMAIN}}/$ORDERER_DOMAINS/g"\
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl delete -f -
}

# After creating appropriate certificate authorities, we now need to create organization
# certificates by enrolling them to the corresponding intermediate CA.
function admin {
  kubectl exec -i $EFS_POD -- bash -c "mkdir -p $EFS_ROOT/admin/crypto-path"
  kubectl exec -i $EFS_POD -- bash -c "mkdir -p $EFS_ROOT/admin/crypto-store"
  # Coppy ./artifacts to $EFS_POD:$EFS_ROOT/admin
  # kubectl cp ./artifacts/ $EFS_POD:$EFS_ROOT/admin
  local ADMIN_DOMAINS=$ORDERER_DOMAINS

  if [ -z "$ADMIN_DOMAINS" ]; then
    ADMIN_DOMAINS=$PEER_DOMAINS
  fi

  # Edit deployment information
  reg=`cat "./k8s/admin/admin-deployment.yaml" | sed \
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ADMIN_DOMAINS/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl apply -f -

  # Edit deployment information
  reg=`cat "./k8s/admin/admin-service.yaml" | sed \
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ADMIN_DOMAINS/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl apply -f -
  return 0
}
function deleteAdmin {
  local ADMIN_DOMAINS=$ORDERER_DOMAINS

  if [ -z "$ADMIN_DOMAINS" ]; then
    ADMIN_DOMAINS=$PEER_DOMAINS
  fi

  # Edit deployment information
  reg=`cat "./k8s/admin/admin-deployment.yaml" | sed \
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ADMIN_DOMAINS/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl delete -f -

  # Edit deployment information
  reg=`cat "./k8s/admin/admin-service.yaml" | sed \
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ADMIN_DOMAINS/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl delete -f -
  return 0
}

function stop {
  deleteAdmin

  for h in $PEER_ORGS
  do
    for (( k=0; k<$NUM_PEERS; k++ ))
    do
      deleteStsPeer $h $k
    done
  done

  for h in $ORDERER_ORGS
  do
    for (( k=1; k<=$NUM_ORDERERS; k++ ))
    do
      deleteStsOrderer $h $k
    done
  done

  deleteChannelArtifact

  if [ "${ORDERER_TYPE}" == "kafka" ]; then ## copy script and data files to EFS
    deleteZookeeper
    deleteKafka
  fi

  for h in $PEER_ORGS
  do
    for (( k=0; k<$NUM_PEERS; k++ ))
    do
      deletePeerEnrollment $h $k
    done
  done

  for i in $ORDERER_ORGS
  do
    deleteOrdererEnrollment $i
  done

  for i in $PEER_ORGS
  do
    deletePeerRegistration $i
  done

  for i in $ORDERER_ORGS
  do
    deleteOrdererRegistration $i
  done

  for i in $ORGS
  do
    deleteOrgRegistrations $i
  done

  for i in $ORGS
  do
    deleteICA $i
  done

  deleteRCA

  deleteGenArtifacts
}

function terminate {
  if [[ "$RUN_MODE" == "operator" ]]; then
    deleteBootstrap

    for h in $ORDERER_ORGS
    do
      for (( k=1; k<=$NUM_ORDERERS; k++ ))
      do
        terminateOrderer $h $k
      done
    done

    deleteChannelArtifact

    if [ "${ORDERER_TYPE}" == "kafka" ]; then ## copy script and data files to EFS
      terminateZookeeper
      terminateKafka
    fi

    for i in $ORDERER_ORGS
    do
      deleteOrdererEnrollment $i
    done

    for i in $ORDERER_ORGS
    do
      deleteOrdererRegistration $i
    done

    terminateRCA

    deleteGenArtifacts
  fi

  deleteAdmin
  for h in $PEER_ORGS
  do
    for (( k=0; k<$NUM_PEERS; k++ ))
    do
      terminatePeer $h $k
    done
  done

  for i in $PEER_ORGS
  do
    deletePeerRegistration $i
  done

  for i in $ORGS
  do
    deleteOrgRegistrations $i
  done

  for i in $ORGS
  do
    terminateICA $i
  done

  kubectl exec -i $EFS_POD -- bash -c "rm -rf $EFS_ROOT/akc-ca-data/*"
  kubectl exec -i $EFS_POD -- bash -c "rm -rf $EFS_ROOT/admin/*"

  log "Deleting namespace.."
  kubectl delete ns $RCA_DOMAIN $DOMAINS
}

function start {
  printf -- "Do you want to terminate old network? (Y/n) "
  read confirmTerminate
  if [ "$confirmTerminate" == "y" ] || [ "$confirmTerminate" == "Y" ];
  then
    log Terminate old network
    terminate
  fi

  log "Copy scripts to EFS"
  copyArtifact

  log "Create a new Root Certificate Authority service"
  setupRCA
  podPending $RCA_DOMAIN

  log "Create new Intermediate Certificate Authority services"
  for i in $ORGS
  do
    setupICA $i
  done
  for i in $DOMAINS
  do
    podPending $i
  done

  log "Run jobs to register organizations"
  for i in $ORGS
  do
    registerOrganizations $i
  done
  for i in $DOMAINS
  do
    jobPending $i
  done

  log "Run jobs to register orderers"
  for i in $ORDERER_ORGS
  do
    registerOrderer $i
  done
  log "Run jobs to register peers"
  for i in $PEER_ORGS
  do
    registerPeer $i
  done
  # Check status
  for i in $DOMAINS
  do
    jobPending $i
  done

  log "Run jobs to enroll orderers"
  for i in $ORDERER_ORGS
  do
    enrollOrderer $i
  done
  log "Run jobs to enroll peers"
  for h in $PEER_ORGS
  do
    for (( k=0; k<$NUM_PEERS; k++ ))
    do
      enrollPeer $h $k
    done
  done
  # Check status
  for i in $DOMAINS
  do
    jobPending $i
  done

  log "Create crypto-config folder to contains artifacts"
  updateFolder

  if [ "${ORDERER_TYPE}" == "kafka" ]; then
    log "Create new Zookeeper services"
    zookeeper
    podPending $KAFKA_NAMESPACE
    log "Create new Kafka services"
    kafka
    podPending $KAFKA_NAMESPACE
  fi

  log "Run job to generate channel.tx, genesis.block"
  createChannelArtifact
  jobPending $ORDERER_DOMAINS

  log "Create new StatefullSet orderers"
  for i in $ORDERER_ORGS
  do
    for (( j=1; j<=$NUM_ORDERERS; j++ ))
    do
      stsOrderer $i $j
    done
  done

  log "Create new StatefullSet peers"
  for h in $PEER_ORGS
  do
    for (( k=0; k<$NUM_PEERS; k++ ))
    do
      stsPeer $h $k
    done
  done

  for i in $DOMAINS
  do
    podPending $i
  done

  log "Run jobs to generate application artifacts"
  genArtifacts
  jobPending $ORDERER_DOMAINS

  # Create secret if use private docker hub
  if [ "$PRIVATE_DOCKER_IMAGE" == "true" ];
  then
    log "Create secrets"
    createSecret $ORDERER_DOMAINS regcred
  fi
  log "Create new a new Admin service"
  admin
  podPending $ORDERER_DOMAINS

  log "Bootrap network"
  bootstrapNetwork
  jobPending $ORDERER_DOMAINS
  viewLogPod $ORDERER_DOMAINS "bootstrap-network"
  log "FINISH"
}

function bootstrapNetwork {
  # Edit deployment information
  reg=`cat "./k8s/bootstrap-network/fabric-deployment-bootstrap-network.yaml" | sed \
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ORDERER_DOMAINS/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl apply -f -
}

function deleteBootstrap {
  # Edit deployment information
  reg=`cat "./k8s/bootstrap-network/fabric-deployment-bootstrap-network.yaml" | sed \
      -e "s/{{EFS_SERVER}}/$EFS_SERVER/g"\
      -e "s/{{ORDERER_DOMAIN}}/$ORDERER_DOMAINS/g"\
      -e "s/{{EFS_PATH}}/$EFS_PATH/g"\
      -e "s/{{EFS_EXTEND}}/$EFS_EXTEND/g"`

  echo "$reg" | kubectl delete -f -
}

MODE=$1
shift

# Create a fresh network with rca and ica
if [ "${MODE}" == "artifact" ]; then ## copy script and data files to EFS
  copyArtifact
# Create environment Build for network
elif [ "${MODE}" == "environmentBuild" ]; then ## delete a new RCA
  environmentBuild
# Create environment for network
elif [ "${MODE}" == "environment" ]; then ## delete a new RCA
  environment

## create a new RCA
elif [ "${MODE}" == "rca" ]; then
  setupRCA
elif [ "${MODE}" == "del-rca" ]; then ## delete a new RCA
  deleteRCA

## create ICA for each organization
elif [ "${MODE}" == "ica" ]; then
  for i in $ORGS
  do
    setupICA $i
  done
elif [ "${MODE}" == "del-ica" ]; then ## delete ICA for each organization
  for i in $ORGS
  do
    deleteICA $i
  done
elif [ "${MODE}" == "ter-ica" ]; then ## delete ICA for each organization
  for i in $ORGS
  do
    terminateICA $i
  done
## create ICA for each organization using external rca
elif [ "${MODE}" == "ica-ex" ]; then
  for i in $ORGS
  do
    setupICAex $i
  done
elif [ "${MODE}" == "del-ica-ex" ]; then ## delete ICA for each organization
  for i in $ORGS
  do
    deleteICAex $i
  done
elif [ "${MODE}" == "ter-ica-ex" ]; then ## delete ICA for each organization
  for i in $ORGS
  do
    terminateICAex $i
  done
## register orgs
elif [ "${MODE}" == "reg-org" ]; then
  for i in $ORGS
  do
    registerOrganizations $i
  done
elif [ "${MODE}" == "del-reg-org" ]; then ##  delete org registrations
  for i in $ORGS
  do
    deleteOrgRegistrations $i
  done

## register orderers
elif [ "${MODE}" == "reg-orderer" ]; then
  for i in $ORDERER_ORGS
  do
    registerOrderer $i
  done
elif [ "${MODE}" == "del-reg-orderer" ]; then ## delete orderer registrations
  for i in $ORDERER_ORGS
  do
    deleteOrdererRegistration $i
  done

## register peers
elif [ "${MODE}" == "reg-peer" ]; then
  for i in $PEER_ORGS
  do
    registerPeer $i
  done
elif [ "${MODE}" == "del-reg-peer" ]; then ## delete peer registrations
  for i in $PEER_ORGS
  do
    deletePeerRegistration $i
  done

## enroll orderers
elif [ "${MODE}" == "enroll-orderer" ]; then
  for i in $ORDERER_ORGS
  do
    enrollOrderer $i
  done
elif [ "${MODE}" == "del-enroll-orderer" ]; then ## delete orderer enrollments
  for i in $ORDERER_ORGS
  do
    deleteOrdererEnrollment $i
  done

## enroll peers
elif [ "${MODE}" == "enroll-peer" ]; then
  for h in $PEER_ORGS
  do
    for (( k=0; k<$NUM_PEERS; k++ ))
    do
      enrollPeer $h $k
    done
  done
elif [ "${MODE}" == "del-enroll-peer" ]; then ## delete peer enrollments
  for h in $PEER_ORGS
  do
    for (( k=0; k<$NUM_PEERS; k++ ))
    do
      deletePeerEnrollment $h $k
    done
  done

## migrate artifact orgs folder to crypto-config folder
elif [ "${MODE}" == "update-folder" ]; then ##
  updateFolder

## deploy zookeepers
elif [ "${MODE}" == "zookeeper" ]; then
  zookeeper
elif [ "${MODE}" == "del-zookeeper" ]; then ## delete zookeepers
  deleteZookeeper

## deploy kafkas
elif [ "${MODE}" == "kafka" ]; then
  kafka
elif [ "${MODE}" == "del-kafka" ]; then ## delete kafkas
  deleteKafka

## run channel-artifacts to generate: channel.tx, genesis.block
elif [ "${MODE}" == "channel-artifact" ]; then
  createChannelArtifact
elif [ "${MODE}" == "del-channel-artifact" ]; then ## delete channel-artifacts job
  deleteChannelArtifact

## deploy orderers
elif [ "${MODE}" == "orderer" ]; then
  for i in $ORDERER_ORGS
  do
    for (( j=1; j<=$NUM_ORDERERS; j++ ))
    do
      stsOrderer $i $j
    done
  done
elif [ "${MODE}" == "del-orderer" ]; then ## delete orderer StatefulSets & Services
  for i in $ORDERER_ORGS
  do
    for (( j=1; j<=$NUM_ORDERERS; j++ ))
    do
      deleteStsOrderer $i $j
    done
  done
elif [ "${MODE}" == "ter-orderer" ]; then ## terminate orderer StatefulSets, Services & PVC
  for i in $ORDERER_ORGS
  do
    for (( j=1; j<=$NUM_ORDERERS; j++ ))
    do
      terminateOrderer $i $j
    done
  done

## deploy peers
elif [ "${MODE}" == "peer" ]; then
  for h in $PEER_ORGS
  do
    for (( k=0; k<$NUM_PEERS; k++ ))
    do
      stsPeer $h $k
    done
  done
elif [ "${MODE}" == "del-peer" ]; then ## delete peer StatefulSets & Services
  for h in $PEER_ORGS
  do
    for (( k=0; k<$NUM_PEERS; k++ ))
    do
      deleteStsPeer $h $k
    done
  done
elif [ "${MODE}" == "ter-peer" ]; then ## terminate peer StatefulSets, Services & PVC
  for h in $PEER_ORGS
  do
    for (( k=0; k<$NUM_PEERS; k++ ))
    do
      terminatePeer $h $k
    done
  done

## generate artifact
elif [ "${MODE}" == "gen-artifacts" ]; then
  genArtifacts
## delete generate artifact
elif [ "${MODE}" == "del-gen-artifacts" ]; then
  deleteGenArtifacts
## deploy admin
elif [ "${MODE}" == "admin" ]; then
  admin
elif [ "${MODE}" == "del-admin" ]; then ## delete admin
  deleteAdmin

## run clean to clear all jobs, deployments, services
elif [ "${MODE}" == "stop" ]; then ##
  stop
elif [ "${MODE}" == "terminate" ]; then ##
  terminate
elif [ "${MODE}" == "start" ]; then ##
  start
elif [ "${MODE}" == "bootstrap" ]; then ##
  bootstrapNetwork
elif [ "${MODE}" == "del-bootstrap" ]; then ## delete admin
  deleteBootstrap
else
  printHelp
  exit 1
fi
