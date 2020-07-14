#!/bin/bash
set -e
cd ~/.akachain/akc-mamba/mamba

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

function helmInstall {
  # Get helm latest version
  echo -e 'Installing helm:'
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > ./k8s/environment/helm/auto_generated_get_helm.sh
  chmod +x ./k8s/environment/helm/auto_generated_get_helm.sh
  ./k8s/environment/helm/auto_generated_get_helm.sh
  kubectl apply -f ./k8s/environment/helm/1rbac.yaml
  ./k8s/environment/helm/2install_helm.sh
  # Check install process
  podPending kube-system
  echo -e '\nInstall helm success'
}

function autoscaler {
  # Edit autoscaler template
  if [ $K8S_TYPE == 'eks' ]
  then
    echo -e "Installing cluster autoscaler:"
    autoscaler=`cat "./k8s/environment/autoscaler/cluster_autoscaler.yml" | sed \
        -e "s/{{EKS_SCALING_SIZE}}/$EKS_SCALING_SIZE/g"\
        -e "s/{{EKS1_SCALING_SIZE}}/$EKS1_SCALING_SIZE/g"\
        -e "s/{{EKS_AUTO_SCALING_GROUP}}/$EKS_AUTO_SCALING_GROUP/g"\
        -e "s/{{EKS1_AUTO_SCALING_GROUP}}/$EKS1_AUTO_SCALING_GROUP/g"\
        -e "s/{{EKS_REGION}}/$EKS_REGION/g"`
    echo "$autoscaler" | kubectl apply -f -
    podPending kube-system
    echo -e "\nInstall autoscaler success"
  else
    echo -e "You run with k8s type: $K8S_TYPE"
  fi
}

function storageClass {
  if [ $K8S_TYPE == 'eks' ]
  then
    echo -e 'Installing EBS encryption'
    kubectl apply -f ./k8s/environment/ebs-encryption/0gp2-encryption.yaml;
    local SC_PENDING=$(kubectl get sc gp2-encryption | awk '{print $2}' | grep default | wc -l)
    while [ "${SC_PENDING}" != "1" ];
    do
      ./k8s/environment/ebs-encryption/1set_default_sc.sh
      echo -e 'Making gp2-encryption to default storage class'
      SC_PENDING=$(kubectl get sc gp2-encryption | awk '{print $2}' | grep default | wc -l)
      sleep 10
    done
    echo -e 'gp2-encryption is default storage class'
  else
    echo -e 'Installing local storage'
    kubectl apply -f ./k8s/environment/local-storage/0local-storage.yaml;
    echo -e 'minikube standard is default storage class'
  fi
}

function efs {
  echo -e 'Checking EFS install or not'
  if [ $K8S_TYPE == "eks" ]
  then
    local EFS=$(helm ls efs | grep 'DEPLOYED' | wc -l)
    if [ $EFS == "1" ]
    then
      echo -e 'EFS installed, upgrade EFS to the latest version'
      ./k8s/environment/efs/upgrade_efs.sh $EFS_SERVER_ID $EKS_REGION
    else
      echo -e 'Installing EFS: '
      ./k8s/environment/efs/install_efs.sh $EFS_SERVER_ID $EKS_REGION
    fi
    podPending default
    echo -e 'EFS install success'
    echo -e 'Created EFS PVC'
    kubectl apply -f ./k8s/environment/efs/pvc-efs.yaml
    local PVC=$(kubectl get pvc efs | awk '{print $2}' | grep Bound | wc -l)
    while [ "${PVC}" != "1" ];
    do
      printf -- "\e[2m  Creating EFS PVC \033[0m\033"
      local PVC=$(kubectl get pvc efs | awk '{print $2}' | grep Bound | wc -l)
      sleep 9 2>/dev/null &
      spinner
    done
    #Search and replace default efs-path value in env.sh
    EFS_PVC=efs-$(kubectl get pvc | grep efs | awk '{print $3}')
    echo $EFS_PVC
    
    sed -i -e 's/efs-pvc-.*[^"]/'"$EFS_PVC"'/g' ./config/.env
    echo -e 'Create EFS Pod'
    kubectl apply -f ./k8s/environment/efs/test-efs.yaml
    podPending default
    echo -e 'EFS Pod created'
  else
    kubectl apply -f ./k8s/environment/efs/nfs-volume.yaml
    podPending default
    echo -e 'Create volume PV success'
    ###

    kubectl apply -f ./k8s/environment/efs/nfs-pvc.yaml
    podPending default
    echo -e 'Created NFS PVC success'
    ###

    # docker pull itsthenetwork/nfs-server-alpine
    kubectl apply -f ./k8s/environment/efs/nfs-server.yaml
    podPending default
    echo -e 'NFS server install success'
    NFS_SERVER="$(kubectl get svc -n default | grep nfs-server | awk '{print $3}')"
    sed -i -e 's/EFS_SERVER=.*/EFS_SERVER='"$NFS_SERVER"'/g' ./config/.env
    ###

    kubectl apply -f ./k8s/environment/efs/nfs-efs.yaml --validate=false
    podPending default
    echo -e 'Created EFS success'

    sed -i -e 's/efs-pvc-.*[^"]/'""'/g' ./config/.env
  fi

  #Search and replace default test-efs value in env.sh
  EFS_POD=$(kubectl get pod -n default | grep test-efs | awk '{print $1}')
  sed -i -e 's/test-efs-.*[^"]/'"$EFS_POD"'/g' ./config/.env
}

function ingress {
  if [ $K8S_TYPE == 'eks' ]
  then
    echo -e 'Installing ALB-Ingress: '
    kubectl apply -f ./k8s/environment/ingress/0clusterRole.yaml;
    ingress=`cat "./k8s/environment/ingress/1alb-ingress-controller.yaml" | sed \
        -e "s/{{EKS_CLUSTER_NAME}}/$EKS_CLUSTER_NAME/g"`
    echo "$ingress" | kubectl apply -f -
    podPending kube-system
    echo -e 'Installed ALB-Ingress'
  else
    printf -- '\033[32m You run k8s mode '$K8S_TYPE' and will not install ingress. \033[0m\n';
  fi
}

function metrics {
  if [ $K8S_TYPE == 'eks' ]
  then
    echo -e 'Checking metrics install or not'
    METRICS=$(helm ls metrics-server | grep 'DEPLOYED' | wc -l)
    if [ ${METRICS} == "1" ]
    then
      echo -e 'Metrics installed, upgrade metrics to the latest version'
      ./k8s/environment/metrics/upgrade_metrics.sh
    else
      echo -e 'Installing metric: '
      ./k8s/environment/metrics/install_metrics.sh
    fi
    podPending metrics
    echo -e 'Install metric server success'
  else
    printf -- '\033[32m You run k8s mode '$K8S_TYPE' and will not install metrics. \033[0m\n';
  fi
}

function environment {
  helmInstall
  autoscaler
  storageClass
  efs
  ingress
  metrics
}

# environment
source ./config/.env
source ./blockchain/scripts/utilities.sh
environment
