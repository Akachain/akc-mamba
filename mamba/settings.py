# Settings module contains all global objects that are shared accross the mamba project
# It is useful for utility objects that only need to be initialized once
# follow the instruction from here:
# https://stackoverflow.com/questions/13034496/using-global-variables-between-files
import os
import yaml
import shutil
from utils.kube import KubeHelper
from dotenv import load_dotenv
from utils import util


def init(dotenv_path, set_default):
    if set_default:
        default_path = 'config/.env'
        shutil.copy(dotenv_path, default_path)
        load_dotenv(default_path)
    else:
        load_dotenv(dotenv_path)

    global k8s
    k8s = KubeHelper()

    global EKS_CLUSTER_NAME
    global EKS_REGION
    global EKS_AUTO_SCALING_GROUP
    global EKS_SCALING_SIZE
    global EKS1_AUTO_SCALING_GROUP
    global EKS1_SCALING_SIZE
    EKS_CLUSTER_NAME = os.getenv('EKS_CLUSTER_NAME')
    EKS_REGION = os.getenv('EKS_REGION')
    EKS_AUTO_SCALING_GROUP = os.getenv('EKS_AUTO_SCALING_GROUP')
    EKS_SCALING_SIZE = os.getenv('EKS_SCALING_SIZE')
    EKS1_AUTO_SCALING_GROUP = os.getenv('EKS1_AUTO_SCALING_GROUP')
    EKS1_SCALING_SIZE = os.getenv('EKS1_SCALING_SIZE')

    global EFS_SERVER
    global EFS_PATH
    global EFS_ROOT
    global EFS_POD
    global EFS_EXTEND
    global EFS_SERVER_ID
    EFS_SERVER = os.getenv('EFS_SERVER')
    EFS_PATH = os.getenv('EFS_PATH')
    EFS_ROOT = os.getenv('EFS_ROOT')
    EFS_POD = os.getenv('EFS_POD')
    EFS_EXTEND = os.getenv('EFS_EXTEND')
    EFS_SERVER_ID = os.getenv('EFS_SERVER_ID')

    global RCA_NAME
    global RCA_ORG
    RCA_NAME = os.getenv('RCA_NAME')
    RCA_ORG = os.getenv('RCA_ORG')

    global ORDERER_ORGS
    global ORDERER_DOMAINS
    global ORDERER_TYPE
    ORDERER_ORGS = os.getenv('ORDERER_ORGS')
    ORDERER_DOMAINS = os.getenv('ORDERER_DOMAINS')
    ORDERER_TYPE = os.getenv('ORDERER_TYPE')

    global KAFKA_NAMESPACE
    KAFKA_NAMESPACE = os.getenv('KAFKA_NAMESPACE')

    global BATCH_TIMEOUT
    global BATCH_SIZE_MAX_MESSAGE_COUNT
    BATCH_TIMEOUT = os.getenv('BATCH_TIMEOUT')
    BATCH_SIZE_MAX_MESSAGE_COUNT = os.getenv('BATCH_SIZE_MAX_MESSAGE_COUNT')

    global NUM_ORDERERS
    NUM_ORDERERS = os.getenv('NUM_ORDERERS')

    global PEER_ORGS
    global PEER_DOMAINS
    global PEER_PREFIX
    PEER_ORGS = os.getenv('PEER_ORGS')
    PEER_DOMAINS = os.getenv('PEER_DOMAINS')
    PEER_PREFIX = os.getenv('PEER_PREFIX')

    global NUM_PEERS
    NUM_PEERS = os.getenv('NUM_PEERS')

    global CHANNEL_NAME
    CHANNEL_NAME = os.getenv('CHANNEL_NAME')

    global PRIVATE_DOCKER_IMAGE
    global PRIVATE_DOCKER_SEVER
    global PRIVATE_DOCKER_USER
    global PRIVATE_DOCKER_PASSWORD
    global PRIVATE_DOCKER_EMAIL
    PRIVATE_DOCKER_IMAGE = os.getenv('PRIVATE_DOCKER_IMAGE')
    PRIVATE_DOCKER_SEVER = os.getenv('PRIVATE_DOCKER_SEVER')
    PRIVATE_DOCKER_USER = os.getenv('PRIVATE_DOCKER_USER')
    PRIVATE_DOCKER_PASSWORD = os.getenv('PRIVATE_DOCKER_PASSWORD')
    PRIVATE_DOCKER_EMAIL = os.getenv('PRIVATE_DOCKER_EMAIL')

    global FABRIC_TAG
    FABRIC_TAG = os.getenv('FABRIC_TAG')

    global EXTERNAL_ORDERER_ADDRESSES, EXTERNAL_ORG_PEER0_ADDRESSES
    global EXTERNAL_ORG_PEER1_ADDRESSES, EXTERNAL_RCA_ADDRESSES
    EXTERNAL_ORDERER_ADDRESSES = os.getenv('EXTERNAL_ORDERER_ADDRESSES')
    EXTERNAL_ORG_PEER0_ADDRESSES = os.getenv('EXTERNAL_ORG_PEER0_ADDRESSES')
    EXTERNAL_ORG_PEER1_ADDRESSES = os.getenv('EXTERNAL_ORG_PEER1_ADDRESSES')
    EXTERNAL_RCA_ADDRESSES = os.getenv('EXTERNAL_RCA_ADDRESSES')

    global NEW_ORG_NAME
    NEW_ORG_NAME = os.getenv('NEW_ORG_NAME')

    global ORGS, DOMAINS
    ORGS = (ORDERER_ORGS+' ' +PEER_ORGS).strip()
    DOMAINS = (ORDERER_DOMAINS+' '+PEER_DOMAINS).strip()
