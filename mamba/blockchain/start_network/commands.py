import click
import os
import time
from settings import settings
from os import path

from shutil import copyfile
from utils import hiss

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
from k8s.secret.commands import create_all_docker_secret
from blockchain.admin.commands import setup_admin
from blockchain.bootstrap_network.commands import bootstrap_network


def start_network():
    hiss.rattle('Setup Network')

    # Copy scripts to EFS
    copy_scripts()

    # Create a new Root Certificate Authority service
    setup_rca()

    # Create new Intermediate Certificate Authority services
    setup_all_ica()

    # Run jobs to register organizations
    reg_all_org()

    # Run jobs to register orderers
    reg_all_orderer()

    # Run jobs to register peers
    reg_all_peer()

    # Run jobs to enroll orderers
    enroll_all_orderer()

    # Run jobs to enroll peers
    enroll_all_peer()

    time.sleep(5)

    # Create crypto-config folder to contains artifacts
    update_folder()

    if settings.ORDERER_TYPE == 'kafka':
        # Create new Zookeeper services
        setup_zookeeper()
        # Create new Kafka services
        setup_kafka()
    
    # Run job to generate channel.tx, genesis.block
    gen_channel_artifact()

    # Create new StatefullSet orderers
    setup_all_orderer()

    # Create new StatefullSet peers
    setup_all_peer()

    # Run jobs to generate application artifacts
    generate_artifact()

    # Create secret if use private docker hub
    if settings.PRIVATE_DOCKER_IMAGE == 'true':
        create_all_docker_secret('mamba')

    # Create new a new Admin service
    time.sleep(1)
    setup_admin()

    # Bootrap network
    time.sleep(1)
    bootstrap_network()

    # cat log
    domains = settings.ORDERER_DOMAINS.split(' ')
    settings.k8s.read_pod_log('bootstrap-network', domains[0])

    return True


@click.command('start', short_help="Start Blockchain Network")
def start():
    start_network()