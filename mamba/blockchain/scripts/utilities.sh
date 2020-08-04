#!/bin/bash
# source $(dirname "$0")/utilities.sh

function viewLogPod {
  local NAMESPACE=$1
  local POD_NAME=$2
  local NAME=$(kubectl get pod -n ${NAMESPACE} | grep "$POD_NAME" | awk '{print $1}')
  kubectl logs -n ${NAMESPACE} ${NAME}
}

function createSecret {
  local NAMESPACE=$1
  local SECRET_NAME=$2
  kubectl create secret docker-registry \
   $SECRET_NAME --docker-server=$PRIVATE_DOCKER_SEVER \
   --docker-username=$PRIVATE_DOCKER_USER --docker-password=$PRIVATE_DOCKER_PASSWORD \
   --docker-email=$PRIVATE_DOCKER_EMAIL \
   -n $NAMESPACE
}

function spinner(){
    pid=$! # Process Id of the previous running command
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1}"
    sleep .1
    done
    echo ""
}