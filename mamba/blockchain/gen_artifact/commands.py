import click
import yaml
import re
from kubernetes import client
from os import path
from utils import hiss, util
from settings import settings

def generate_artifact():

    domains = settings.ORDERER_DOMAINS.split(' ')

    # Create temp folder & namespace
    settings.k8s.prereqs(domains[0])

    k8s_template_file = '%s/gen-artifacts/fabric-deployment-gen-artifacts.yaml' % util.get_k8s_template_path()
    dict_env = {
        'ORDERER_DOMAIN': domains[0],
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH
    }

    settings.k8s.apply_yaml_from_template(
        namespace=domains[0], k8s_template_file=k8s_template_file, dict_env=dict_env)

def del_generate_artifact():

    domains = settings.ORDERER_DOMAINS.split(' ')
    jobname = 'generate-artifacts'

    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domains[0])
    

@click.group()
def gen_artifact():
    """Generate application artifacts"""
    pass

@gen_artifact.command('setup', short_help="Run job to generate application artifacts")
def setup():
    hiss.rattle('Generate application artifacts')

    generate_artifact()

@gen_artifact.command('delete', short_help="Delete job gen artifact")
def delete():
    hiss.rattle('Delete job gen artifact')

    del_generate_artifact()
