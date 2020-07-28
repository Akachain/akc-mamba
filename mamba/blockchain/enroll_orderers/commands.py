import click
import yaml
import re
from kubernetes import client
from os import path
from utils import hiss, util
from settings import settings

def enroll_orderer(orderer):
    # Get domain
    domain = util.get_domain(orderer)

    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    k8s_template_file = '%s/enroll-orderer/fabric-deployment-enroll-orderer.yaml' % util.get_k8s_template_path()
    dict_env = {
        'ORDERER': orderer,
        'ENROLL_DOMAIN': domain,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH
    }

    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def del_enroll_orderer(orderer):

    # Get domain
    domain = util.get_domain(orderer)
    jobname = 'enroll-o-%s' % orderer

    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domain)

def enroll_all_orderer():
    orderers = settings.ORDERER_ORGS.split(' ')
    # TODO: Multiprocess
    for orderer in orderers:
        enroll_orderer(orderer)

def del_all_enroll_orderer():
    orderers = settings.ORDERER_ORGS.split(' ')
    # TODO: Multiprocess
    for orderer in orderers:
        del_enroll_orderer(orderer)

@click.group()
def enroll_orderers():
    """Enroll orderers"""
    pass

@enroll_orderers.command('setup', short_help="Setup enroll orderers")
def setup():
    hiss.rattle('Enroll orderers')
    enroll_all_orderer()

@enroll_orderers.command('delete', short_help="Delete enroll orderers")
def delete():
    hiss.rattle('Delete enroll orderers job')
    del_all_enroll_orderer()
