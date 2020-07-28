import click
import yaml
import re
import datetime
from kubernetes import client
from os import path
from kubernetes.client.rest import ApiException
from utils import hiss, util
from settings import settings


def terminate_orderer(orderer, index):
    # Get domain
    domain = util.get_domain(orderer)

    name = 'orderer%s-%s' % (index, orderer) 

    # Terminate stateful set
    return settings.k8s.delete_stateful(name=name, namespace=domain, delete_pvc=True)

def delete_orderer(orderer, index):
    # Get domain
    domain = util.get_domain(orderer)

    name = 'orderer%s-%s' % (index, orderer) 

    # Delete stateful set
    return settings.k8s.delete_stateful(name=name, namespace=domain)

def setup_orderer(orderer, index):

    # Get domain
    domain = util.get_domain(orderer)
    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    if settings.K8S_TYPE == 'minikube':
        store_class = 'standard'
    else:
        store_class = 'gp2'

    dict_env = {
        'ORDERER': orderer,
        'ORDERER_DOMAIN': domain,
        'ORDERER_INDEX': index,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH,
        'STORE_CLASS': store_class
    }

    orderer_stateful = '%s/orderer-sts/orderer-stateful.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=orderer_stateful, dict_env=dict_env)

    orderer_service = '%s/orderer-sts/orderer-service.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=orderer_service, dict_env=dict_env)

    if settings.EXTERNAL_ORDERER_ADDRESSES != '':
        # Setup nlb
        orderer_service_nlb = '%s/orderer-sts/orderer-service-nlb.yaml' % util.get_k8s_template_path()
        settings.k8s.apply_yaml_from_template(
            namespace=domain, k8s_template_file=orderer_service_nlb, dict_env=dict_env)

def setup_all_orderer():
    orderers = settings.ORDERER_ORGS.split(' ')
    for orderer in orderers:
        for index in range(int(settings.NUM_ORDERERS)):
            setup_orderer(orderer, str(index))

def delete_all_orderer():
    orderers = settings.ORDERER_ORGS.split(' ')
    for orderer in orderers:
        for index in range(int(settings.NUM_ORDERERS)):
            delete_orderer(orderer, str(index))

def terminate_all_orderer():
    orderers = settings.ORDERER_ORGS.split(' ')
    results = []
    for orderer in orderers:
        for index in range(int(settings.NUM_ORDERERS)):
            results.append(terminate_orderer(orderer, str(index)))
    return results

@click.group()
def orderer():
    """Orderer"""
    pass


@orderer.command('setup', short_help="Setup Orderers")
def setup():
    hiss.rattle('Setup orderers')
    setup_all_orderer()

@orderer.command('delete', short_help="Delete Orderer")
def delete():
    hiss.rattle('Delete Orderer')
    delete_all_orderer()

@orderer.command('terminate', short_help="Terminate Orderer")
def terminate():
    hiss.rattle('Terminate Orderer')
    terminate_all_orderer()
