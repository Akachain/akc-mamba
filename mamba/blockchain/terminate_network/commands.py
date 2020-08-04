import click
import os
import time
from settings import settings
from os import path
from shutil import copyfile
from utils import hiss, util

from blockchain.bootstrap_network.commands import del_bootstrap_network
from blockchain.channel_artifact.commands import del_gen_channel_artifact
from blockchain.gen_artifact.commands import del_generate_artifact
from blockchain.reg_orgs.commands import del_all_reg_org
from blockchain.reg_orderers.commands import del_all_reg_orderer
from blockchain.reg_peers.commands import del_all_reg_peer
from blockchain.enroll_orderers.commands import del_all_enroll_orderer
from blockchain.enroll_peers.commands import del_all_enroll_peer

from blockchain.rca.commands import terminate_rca
from blockchain.ica.commands import terminate_all_ica
from blockchain.zookeeper.commands import terminate_zookeeper
from blockchain.kafka.commands import terminate_kafka
from blockchain.orderer.commands import terminate_all_orderer
from blockchain.peer.commands import terminate_all_peer
from blockchain.admin.commands import del_admin

def remove_cert():
    ## Find explorer_db pod
    pods = settings.k8s.find_pod(namespace='default', keyword="test-efs")
    if not pods:
        return hiss.hiss('cannot find tiller pod')
    
    remove_cert = 'rm -rf %s/akc-ca-data/*; rm -rf %s/admin/*' % (settings.EFS_ROOT, settings.EFS_ROOT)
    exec_command = [
        '/bin/bash',
        '-c',
        '%s'  % (remove_cert)]

    return settings.k8s.exec_pod(
        podName=pods[0], namespace='default', command=exec_command)
    

def terminate_network():

    result = []
    # Delete job
    util.smart_append(result, del_admin())
    util.smart_append(result, del_bootstrap_network())
    util.smart_append(result, del_gen_channel_artifact())
    util.smart_append(result, del_generate_artifact())
    util.smart_append(result, del_all_reg_org())
    util.smart_append(result, del_all_reg_orderer())
    util.smart_append(result, del_all_reg_peer())
    util.smart_append(result, del_all_enroll_orderer())
    util.smart_append(result, del_all_enroll_peer())

    # Terminate Root Certificate Authority service
    util.smart_append(result, terminate_rca())

    # Terminate Intermediate Certificate Authority services
    util.smart_append(result, terminate_all_ica())

    if settings.ORDERER_TYPE == 'kafka':
        # Terminate Zookeeper services
        util.smart_append(result, terminate_zookeeper())
        # Terminate Kafka services
        util.smart_append(result, terminate_kafka())
    
    # Terminate StatefullSet orderers
    util.smart_append(result, terminate_all_orderer())

    # Terminate StatefullSet peers
    util.smart_append(result, terminate_all_peer())

    # Remove old cert
    util.smart_append(result, remove_cert())

    #TODO: Delete secret

    for r in result: print(r)
    return result


@click.command('terminate', short_help="Terminate Blockchain Network")
def terminate():
    hiss.rattle('Terminate Network')
    terminate_network()
