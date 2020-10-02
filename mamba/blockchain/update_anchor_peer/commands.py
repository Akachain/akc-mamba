import click
import os
import time
from settings import settings
from os import path

from utils import hiss, util

def update_anchor_peer(org):

    # Get domain
    domain = util.get_domain(org)
    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    dict_env = {
        'ORG_NAME': org,
        'ORG_DOMAIN': domain,
        'ORGS': settings.PEER_ORGS,
        'ORDERER_NAME': settings.ORDERER_ORGS,
        'ORDERER_DOMAIN': settings.ORDERER_DOMAINS,
        'CHANNEL_NAME': settings.CHANNEL_NAME,
        'FABRIC_TAG': settings.FABRIC_TAG,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH
    }
    k8s_template_file = '%s/update-anchor-peer/fabric-deployment-anchor-peer.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def delete_job_update_anchor_peer(org):
    # Get domain
    domain = util.get_domain(org)
    jobname = 'update-anchor-peer-%s-%s' % (org, settings.CHANNEL_NAME)
    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domain)

def setup_all():
    orgs = settings.PEER_ORGS.split(' ')
    for org in orgs:
        update_anchor_peer(org)

def del_all_job():
    orgs = settings.PEER_ORGS.split(' ')
    for org in orgs:
        delete_job_update_anchor_peer(org)

@click.group()
def anchor_peer():
    """Anchor Peer config"""
    pass

@anchor_peer.command('setup', short_help="Create job to update anchor peer")
def setup_anchor_peer():
    hiss.rattle('Update anchor peer')
    setup_all()

@anchor_peer.command('delete', short_help="Delete job update anchor peer")
def delete_anchor_peer():
    hiss.rattle('Delete job config anchor peer')
    del_all_job()