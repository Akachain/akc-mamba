import click
import yaml
import re
import datetime
from kubernetes import client
from os import path
from kubernetes.client.rest import ApiException
from utils import hiss, util
from settings import settings


def terminate_ica(ica_org):
    ica_name = 'ica-%s' % ica_org
    # Get domain ica to create namespace
    ica_domain = util.get_domain(ica_org)
    if not ica_domain:
        return hiss.hiss('Fail to get domain of %s ' % ica_org)

    # Terminate stateful set
    return settings.k8s.delete_stateful(name=ica_name, namespace=ica_domain, delete_pvc=True)

def delete_ica(ica_org):
    ica_name = 'ica-%s' % ica_org
    # Get domain ica to create namespace
    ica_domain = util.get_domain(ica_org)
    if not ica_domain:
        return hiss.hiss('Fail to get domain of %s ' % ica_org)

    # Delete stateful set
    return settings.k8s.delete_stateful(name=ica_name, namespace=ica_domain)

def setup_ica(ica_org):

    # Get domain ica to create namespace
    ica_domain = util.get_domain(ica_org)
    if not ica_domain:
        return hiss.hiss('Fail to get domain of %s ' % ica_org)

    # Create temp folder & namespace
    settings.k8s.prereqs(ica_domain)

    ica_name = 'ica-%s' % ica_org

    rca_host = settings.EXTERNAL_RCA_ADDRESSES
    if not settings.EXTERNAL_RCA_ADDRESSES:
        rca_host = '%s.%s' % (settings.RCA_NAME, settings.RCA_DOMAIN)

    if settings.K8S_TYPE == 'minikube':
        storage_class = 'standard'
    else:
        storage_class = 'gp2'

    k8s_template_file = '%s/ica/fabric-deployment-ica.yaml' % util.get_k8s_template_path()
    dict_env = {
        'ORG': ica_org,
        'ICA_NAME': ica_name,
        'ICA_DOMAIN': ica_domain,
        'RCA_NAME': settings.RCA_NAME,
        'RCA_HOST': rca_host,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH,
        'STORAGE_CLASS': storage_class
    }
    settings.k8s.apply_yaml_from_template(
        namespace=ica_domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def setup_all_ica():
    
    orgs = settings.ORGS.split(' ')
    # TODO: Multiprocess
    for org in orgs:
        setup_ica(org)

def delete_all_ica():
    orgs = settings.ORGS.split(' ')
    # TODO: Multiprocess
    for org in orgs:
        delete_ica(org)

def terminate_all_ica():
    orgs = settings.ORGS.split(' ')
    result = []
    # TODO: Multiprocess
    for org in orgs:
        result.append(terminate_ica(org))
    return result

@click.group()
def ica():
    """Intermediate Certificate Authority"""
    pass


@ica.command('setup', short_help="Setup Intermediate CA")
def setup():
    hiss.rattle('Setup ICA')
    setup_all_ica()

@ica.command('delete', short_help="Delete Intermediate CA")
def delete():
    hiss.rattle('Delete ICA')
    delete_all_ica()

@ica.command('terminate', short_help="Terminate Intermediate CA")
def terminate():
    hiss.rattle('Terminate Intermediate CA Server')
    terminate_all_ica()
