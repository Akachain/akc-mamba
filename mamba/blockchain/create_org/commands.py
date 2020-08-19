import click
import os
import time
from settings import settings
from os import path

from shutil import copyfile
from utils import hiss, util

from blockchain.copyscripts.commands import copy_scripts
from blockchain.rca.commands import setup_rca
from blockchain.ica.commands import setup_all_ica
from blockchain.reg_orgs.commands import reg_all_org
from blockchain.reg_orderers.commands import reg_all_orderer
from blockchain.reg_peers.commands import reg_all_peer
from blockchain.enroll_orderers.commands import enroll_all_orderer
from blockchain.enroll_peers.commands import enroll_all_peer
from blockchain.update_folder.commands import update_folder
from blockchain.zookeeper.commands import setup_zookeeper
from blockchain.kafka.commands import setup_kafka
from blockchain.channel_artifact.commands import gen_channel_artifact
from blockchain.orderer.commands import setup_all_orderer
from blockchain.peer.commands import setup_all_peer
from blockchain.gen_artifact.commands import generate_artifact
from k8s.secret.commands import create_docker_secret
from blockchain.admin.commands import setup_admin
from blockchain.bootstrap_network.commands import bootstrap_network


def create_new_org():
    hiss.rattle('Create New Org')

    # Copy scripts to EFS
    copy_scripts()

    # Phai co rca external address
    # Create new Intermediate Certificate Authority services
    setup_all_ica()

    # Run jobs to register organizations
    reg_all_org()

    # Run jobs to register peers
    reg_all_peer()

    time.sleep(1)

    # Run jobs to enroll peers
    enroll_all_peer()

    time.sleep(5)

    # Create crypto-config folder to contains artifacts
    update_folder()

    # Default value of ORDERER_DOMAINS = default, it needed to run processes below
    if (settings.ORDERER_DOMAINS == ''):
        settings.ORDERER_DOMAINS='default'

    # Create new StatefullSet peers
    setup_all_peer()

    # Run jobs to generate application artifacts
    generate_artifact()

    # Create secret if use private docker hub
    if settings.PRIVATE_DOCKER_IMAGE == 'true':
        create_docker_secret('default','mamba')

    # Create new a new Admin service
    time.sleep(1)
    setup_admin()

    # # Return value ORDERER_DOMAINS
    if (settings.ORDERER_DOMAINS == 'default'):
        settings.ORDERER_DOMAINS=''

    dict_env = {
        'ORG_NAME': settings.PEER_ORGS,
        'ORG_DOMAIN': settings.PEER_DOMAINS,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH
    }

    # Create configtx
    create_config_template = '%s/add-org/0create-configtx.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=settings.PEER_DOMAINS, k8s_template_file=create_config_template, dict_env=dict_env)

    # Gen org.json
    gen_artifact_template = '%s/add-org/1gen-artifacts.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=settings.PEER_DOMAINS, k8s_template_file=gen_artifact_template, dict_env=dict_env)

    return True


@click.command('create-org', short_help="Start Blockchain Network")
def create_org():
    create_new_org()