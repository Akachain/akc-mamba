import click
import os
import time
from settings import settings
from os import path
from shutil import copyfile
from utils import hiss

from blockchain.rca.commands import delete_rca
from blockchain.ica.commands import delete_all_ica
from blockchain.reg_orgs.commands import del_all_reg_org
from blockchain.reg_orderers.commands import del_all_reg_orderer
from blockchain.reg_peers.commands import del_all_reg_peer
from blockchain.enroll_orderers.commands import del_all_enroll_orderer
from blockchain.enroll_peers.commands import del_all_enroll_peer
from blockchain.zookeeper.commands import delete_zookeeper
from blockchain.kafka.commands import delete_kafka
from blockchain.channel_artifact.commands import del_gen_channel_artifact
from blockchain.orderer.commands import delete_all_orderer
from blockchain.peer.commands import del_all_peer
from blockchain.gen_artifact.commands import del_generate_artifact
from blockchain.admin.commands import del_admin
from blockchain.bootstrap_network.commands import del_bootstrap_network


def delete_network():
    hiss.rattle('Delete Network')

    # Delete Root Certificate Authority service
    delete_rca()

    # Delete Intermediate Certificate Authority services
    delete_all_ica()

    # Delete jobs to register organizations
    del_all_reg_org()

    # Delete jobs to register orderers
    del_all_reg_orderer()

    # Delete jobs to register peers
    del_all_reg_peer()

    # Delete jobs to enroll orderers
    del_all_enroll_orderer()

    # Delete jobs to enroll peers
    del_all_enroll_peer()


    if settings.ORDERER_TYPE == 'kafka':
        # Delete Zookeeper services
        delete_zookeeper()
        # Delete Kafka services
        delete_kafka()
    
    # Delete job to generate channel.tx, genesis.block
    del_gen_channel_artifact()

    # Delete StatefullSet orderers
    delete_all_orderer()

    # Delete StatefullSet peers
    del_all_peer()

    # Delete jobs to generate application artifacts
    del_generate_artifact()

    # Delete Admin service
    del_admin()

    del_bootstrap_network()

    return True


@click.command('delete', short_help="Delete Blockchain Network")
def delete():
    delete_network()
