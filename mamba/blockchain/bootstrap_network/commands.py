from os import path
import click
import yaml
import re
from kubernetes import client
from utils import hiss, util
from settings import settings

def bootstrap_network():

    orderer_orgs = settings.ORDERER_ORGS.split(' ')
    orderer_domains = settings.ORDERER_DOMAINS.split(' ')

    peer_orgs = settings.PEER_ORGS.split(' ')
    peer_domains = settings.PEER_DOMAINS.split(' ')


    # Create temp folder & namespace
    settings.k8s.prereqs(orderer_domains[0])

    k8s_template_file = '%s/bootstrap-network/fabric-deployment-bootstrap-network.yaml' % util.get_k8s_template_path()
    dict_env = {
        'ORDERER_NAME': orderer_orgs[0],
        'ORDERER_DOMAIN': orderer_domains[0],
        'ORG_NAME': peer_orgs[0],
        'ORG_DOMAIN': peer_domains[0],
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH
    }

    settings.k8s.apply_yaml_from_template(
        namespace=orderer_domains[0], k8s_template_file=k8s_template_file, dict_env=dict_env)

def del_bootstrap_network():

    domains = settings.ORDERER_DOMAINS.split(' ')
    jobname = 'bootstrap-network'

    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domains[0])
    

@click.group()
def bootstrap():
    """Bootstrap network"""
    pass

@bootstrap.command('setup', short_help="Run job to bootstrap network")
def setup():
    hiss.rattle('Generate channel.tx, genesis.block')

    bootstrap_network()

@bootstrap.command('delete', short_help="Delete job bootstrap network")
def delete():
    hiss.rattle('Delete job channel artifact')

    del_bootstrap_network()
