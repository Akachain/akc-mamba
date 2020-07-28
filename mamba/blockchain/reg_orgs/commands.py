import click
import yaml
import re
from kubernetes import client
from os import path
from utils import hiss, util
from settings import settings

def reg_org(org):
    # Get domain
    domain = util.get_domain(org)

    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    k8s_template_file = '%s/register-org/fabric-deployment-register-org.yaml' % util.get_k8s_template_path()
    dict_env = {
        'ORG': org,
        'REG_DOMAIN': domain,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH
    }

    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def del_reg_org(org):

    # Get domain
    domain = util.get_domain(org)
    jobname = 'register-org-%s' % org

    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domain)

def reg_all_org():
    orgs = settings.ORGS.split(' ')
    # TODO: Multiprocess
    for org in orgs:
        reg_org(org)

def del_all_reg_org():
    orgs = settings.ORGS.split(' ')
    # TODO: Multiprocess
    for org in orgs:
        del_reg_org(org)

@click.group()
def reg_orgs():
    """Register organizations"""
    pass

@reg_orgs.command('setup', short_help="Setup register organizations")
def setup():
    hiss.rattle('Register organizations')
    reg_all_org()


@reg_orgs.command('delete', short_help="Delete register organizations")
def delete():
    hiss.rattle('Delete register organizations job')
    del_all_reg_org()
