# Settings module contains all global objects that are shared accross the mamba project
# It is useful for utility objects that only need to be initialized once
# follow the instruction from here:
# https://stackoverflow.com/questions/13034496/using-global-variables-between-files
import os
from os.path import expanduser
import shutil
from utils.kube import KubeHelper
from dotenv import load_dotenv
from utils import util, hiss
from k8s.config import commands


def init():

    DEFAULT_CONFIG_PATH = expanduser('~/.akachain/akc-mamba/mamba/config/.env')
    commands.extract(force_all=False, force_config=False,
                     force_script=False, force_template=False, force_other=False, dev_mode=False)

    # Load env
    load_dotenv(DEFAULT_CONFIG_PATH)

    global PVS_PATH
    global K8S_TYPE
    K8S_TYPE = os.getenv('K8S_TYPE')
    if K8S_TYPE == 'eks':
        PVS_PATH = '/pvs'
    else:
        PVS_PATH = '/exports'

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
    if EFS_SERVER:
        EFS_SERVER_ID = EFS_SERVER.split('.')[0]

    global RCA_NAME
    global RCA_DOMAIN
    RCA_NAME = os.getenv('RCA_NAME')
    RCA_DOMAIN = os.getenv('RCA_DOMAIN')

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

    global FABRIC_TAG, FABRIC_CA_TAG, COUCHDB_TAG
    FABRIC_TAG = os.getenv('FABRIC_TAG')
    FABRIC_CA_TAG = os.getenv('FABRIC_CA_TAG')
    COUCHDB_TAG = os.getenv('COUCHDB_TAG')

    global EXTERNAL_ORDERER_ADDRESSES, EXTERNAL_ORG_PEER0_ADDRESSES
    global EXTERNAL_ORG_PEER1_ADDRESSES, EXTERNAL_RCA_ADDRESSES
    EXTERNAL_ORDERER_ADDRESSES = os.getenv('EXTERNAL_ORDERER_ADDRESSES')
    EXTERNAL_ORG_PEER0_ADDRESSES = os.getenv('EXTERNAL_ORG_PEER0_ADDRESSES')
    EXTERNAL_ORG_PEER1_ADDRESSES = os.getenv('EXTERNAL_ORG_PEER1_ADDRESSES')
    EXTERNAL_RCA_ADDRESSES = os.getenv('EXTERNAL_RCA_ADDRESSES')


    global REMOTE_RCA_NAME, REMOTE_RCA_ADDRESS
    global REMOTE_ORDERER_NAME, REMOTE_ORDERER_DOMAIN
    REMOTE_RCA_NAME = os.getenv('REMOTE_RCA_NAME')
    REMOTE_RCA_ADDRESS = os.getenv('REMOTE_RCA_ADDRESS')
    REMOTE_ORDERER_NAME = os.getenv('REMOTE_ORDERER_NAME')
    REMOTE_ORDERER_DOMAIN = os.getenv('REMOTE_ORDERER_DOMAIN')

    global ENDORSEMENT_ORG_NAME, ENDORSEMENT_ORG_DOMAIN, ENDORSEMENT_ORG_ADDRESS, ENDORSEMENT_ORG_TLSCERT
    ENDORSEMENT_ORG_NAME = os.getenv('ENDORSEMENT_ORG_NAME')
    ENDORSEMENT_ORG_DOMAIN = os.getenv('ENDORSEMENT_ORG_DOMAIN')
    ENDORSEMENT_ORG_ADDRESS = os.getenv('ENDORSEMENT_ORG_ADDRESS')
    ENDORSEMENT_ORG_TLSCERT = os.getenv('ENDORSEMENT_ORG_TLSCERT')

    global NEW_ORG_NAME
    NEW_ORG_NAME = os.getenv('NEW_ORG_NAME')

    global ORGS, DOMAINS
    ORGS = (ORDERER_ORGS+' ' + PEER_ORGS).strip()
    DOMAINS = (ORDERER_DOMAINS+' '+PEER_DOMAINS).strip()

    global DEPLOYMENT_ENV
    DEPLOYMENT_ENV = os.getenv('DEPLOYMENT_ENV')
