import click
import yaml
import re
import datetime
from kubernetes import client
from os import path
from kubernetes.client.rest import ApiException
from utils import hiss, util
from settings import settings


def terminate_peer(peer, index):
    # Get domain
    domain = util.get_domain(peer)

    # peer service name
    name = 'peer%s-%s' % (index, peer) 

    # Terminate peer stateful set
    res_del_peer =  settings.k8s.delete_stateful(name=name, namespace=domain, delete_pvc=True)

    # couchdb service name
    name = 'couchdb%s-%s' % (index, peer) 

    # Terminate couchdb stateful set
    res_del_db =  settings.k8s.delete_stateful(name=name, namespace=domain, delete_pvc=True)

    if res_del_peer.success == True and res_del_db.success == True:
        hiss.sub_echo('Terminate peer & couchdb success')
    return res_del_db

def delete_peer(peer, index):
    # Get domain
    domain = util.get_domain(peer)

    # peer service name
    name = 'peer%s-%s' % (index, peer) 

    # Delete peer stateful set
    res_del_peer =  settings.k8s.delete_stateful(name=name, namespace=domain)

    # couchdb service name
    name = 'couchdb%s-%s' % (index, peer) 

    # Delete couchdb stateful set
    res_del_db =  settings.k8s.delete_stateful(name=name, namespace=domain)

    if res_del_peer.success == True and res_del_db.success == True:
        hiss.sub_echo('Delete peer & couchdb success')

def setup_peer(peer, index):

    # Get domain
    domain = util.get_domain(peer)
    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    if settings.K8S_TYPE == 'minikube':
        storage_class = 'standard'
    else:
        storage_class = 'gp2'

    dict_env = {
        'PEER_ORG': peer,
        'PEER_DOMAIN': domain,
        'PEER_INDEX': index,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH,
        'STORAGE_CLASS': storage_class
    }

    peer_stateful = '%s/peer-sts/peer-stateful.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=peer_stateful, dict_env=dict_env)

    peer_service = '%s/peer-sts/peer-service-stateful.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=peer_service, dict_env=dict_env)

    num_peers = int(settings.NUM_PEERS)
    if (num_peers > 2):
        hiss.echo('NUM_PEER > 2: Does not support deployment nlb service')
    if (util.get_peer_external_domain(peer, index) != ''):
        peer_service_nlb = '%s/peer-sts/peer-service-nlb.yaml' % util.get_k8s_template_path()
        settings.k8s.apply_yaml_from_template(
            namespace=domain, k8s_template_file=peer_service_nlb, dict_env=dict_env)

def setup_all_peer():
    peers = settings.PEER_ORGS.split(' ')
    for peer in peers:
        for index in range(int(settings.NUM_PEERS)):
            setup_peer(peer, str(index))

def del_all_peer():
    peers = settings.PEER_ORGS.split(' ')
    for peer in peers:
        for index in range(int(settings.NUM_PEERS)):
            delete_peer(peer, str(index))

def terminate_all_peer():
    peers = settings.PEER_ORGS.split(' ')
    results = []
    for peer in peers:
        for index in range(int(settings.NUM_PEERS)):
            results.append(terminate_peer(peer, str(index)))
    return results

@click.group()
def peer():
    """Peer"""
    pass


@peer.command('setup', short_help="Setup peers")
def setup():
    hiss.rattle('Setup peers')
    setup_all_peer()

@peer.command('delete', short_help="Delete peers")
def delete():
    hiss.rattle('Delete peers')
    del_all_peer()

@peer.command('terminate', short_help="Terminate peers")
def terminate():
    hiss.rattle('Terminate peers')
    terminate_all_peer()
