import click
import yaml
import re
from kubernetes import client
from os import path
from utils import hiss, util
from settings import settings

def reg_orderer(orderer):
    # Get domain
    domain = util.get_domain(orderer)

    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    k8s_template_file = '%s/register-orderer/fabric-deployment-register-orderer.yaml' % util.get_k8s_template_path()
    dict_env = {
        'ORDERER_ORG': orderer,
        'ORDERER_DOMAIN': domain,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH
    }

    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def del_reg_orderer(orderer):

    # Get domain
    domain = util.get_domain(orderer)
    jobname = 'register-o-%s' % orderer

    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domain)

def reg_all_orderer():
    orderers = settings.ORDERER_ORGS.split(' ')
    # TODO: Multiprocess
    for orderer in orderers:
        reg_orderer(orderer)

def del_all_reg_orderer():
    orderers = settings.ORDERER_ORGS.split(' ')
    # TODO: Multiprocess
    for orderer in orderers:
        del_reg_orderer(orderer)

@click.group()
def reg_orderers():
    """Register orderers"""
    pass

@reg_orderers.command('setup', short_help="Setup register orderers")
def setup():
    hiss.rattle('Register orderers')
    reg_all_orderer()

@reg_orderers.command('delete', short_help="Delete register orderers")
def delete():
    hiss.rattle('Delete register orderers job')
    del_all_reg_orderer()
