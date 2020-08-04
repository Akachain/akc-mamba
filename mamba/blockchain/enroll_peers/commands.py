import click
import yaml
import re
from kubernetes import client
from os import path
from utils import hiss, util
from settings import settings

def enroll_peer(peer, index):
    # Get domain
    domain = util.get_domain(peer)

    # Get external domain
    external_domain = util.get_peer_external_domain(peer, index)

    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    k8s_template_file = '%s/enroll-peer/fabric-deployment-enroll-peer.yaml' % util.get_k8s_template_path()
    dict_env = {
        'PEER': peer,
        'PEER_DOMAIN': domain,
        'PEER_INDEX': index,
        'EXTERNAL_PEER_HOST': external_domain,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH
    }

    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def del_enroll_peer(peer, index):

    # Get domain
    domain = util.get_domain(peer)
    jobname = 'enroll-p%s-%s' % (index, peer)

    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domain)

def enroll_all_peer():
    peers = settings.PEER_ORGS.split(' ')
    # TODO: Multiprocess
    for peer in peers:
        for index in range(int(settings.NUM_PEERS)):
            enroll_peer(peer, str(index))

def del_all_enroll_peer():
    peers = settings.PEER_ORGS.split(' ')
    # TODO: Multiprocess
    for peer in peers:
        for index in range(int(settings.NUM_PEERS)):
            del_enroll_peer(peer, str(index))

@click.group()
def enroll_peers():
    """Enroll peers"""
    pass

@enroll_peers.command('setup', short_help="Setup enroll peers")
def setup():
    hiss.rattle('Enroll peers')
    enroll_all_peer()

@enroll_peers.command('delete', short_help="Delete enroll peers")
def delete():
    hiss.rattle('Delete enroll peers job')
    del_all_enroll_peer()
