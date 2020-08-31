import click
import yaml
import re
from kubernetes import client
from os import path
from utils import hiss, util
from settings import settings

def generate_ccp(org):

    # Get domain
    domain = util.get_domain(org)

    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    k8s_template_file = '%s/connection-profile/generate-ccp-job.yaml' % util.get_k8s_template_path()
    dict_env = {
        'ORG_NAME': org,
        'ORG_DOMAIN': domain,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH
    }

    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def del_generate_ccp(org):

    # Get domain
    domain = util.get_domain(org)
    jobname = 'generate-ccp-%s' % org

    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domain)
    
def generate_all_ccp():
    orgs = settings.PEER_ORGS.split(' ')
    # TODO: Multiprocess
    for org in orgs:
        generate_ccp(org)

def delete_all_ccp():
    orgs = settings.PEER_ORGS.split(' ')
    # TODO: Multiprocess
    for org in orgs:
        del_generate_ccp(org)

@click.group()
def ccp():
    """Generate connection profiles"""
    pass

@ccp.command('generate', short_help="Run job to generate connection profiles")
def generate():
    hiss.rattle('Generate connection profiles')

    generate_all_ccp()

@ccp.command('delete', short_help="Delete job generate connection profiles")
def delete():
    hiss.rattle('Delete job generate connection profiles')

    delete_all_ccp()
