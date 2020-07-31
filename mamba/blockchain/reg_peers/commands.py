import click
import yaml
import re
from kubernetes import client
from os import path
from utils import hiss, util
from settings import settings

def reg_peer(org):
    # Get domain
    domain = util.get_domain(org)

    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    k8s_template_file = '%s/register-peer/fabric-deployment-register-peer.yaml' % util.get_k8s_template_path()
    dict_env = {
        'PEER_ORG': org,
        'PEER_DOMAIN': domain,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH
    }

    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def del_reg_peer(org):

    # Get domain
    domain = util.get_domain(org)
    jobname = 'register-p-%s' % org

    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domain)

def reg_all_peer():
    orgs = settings.ORGS.split(' ')
    # TODO: Multiprocess
    for org in orgs:
        reg_peer(org)

def del_all_reg_peer():
    orgs = settings.ORGS.split(' ')
    # TODO: Multiprocess
    for org in orgs:
        del_reg_peer(org)

@click.group()
def reg_peers():
    """Register peers"""
    pass

@reg_peers.command('setup', short_help="Setup register peers")
def setup():
    hiss.rattle('Register peeers')
    reg_all_peer()

@reg_peers.command('delete', short_help="Delete register peers")
def delete():
    hiss.rattle('Delete register peers job')
    del_all_reg_peer()

